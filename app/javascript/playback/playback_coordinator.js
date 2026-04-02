import { playbackLog } from "playback/playback_logger"
import { PreviewPlaybackAdapter } from "playback/preview_playback_adapter"
import { SpotifyExternalAdapter } from "playback/spotify_external_adapter"
import { NullPlaybackAdapter } from "playback/null_playback_adapter"

export const PLAYBACK_MODE_PREVIEW = "preview"
export const PLAYBACK_MODE_EXTERNAL = "external"

const LS_MODE = "blindjam_playback_mode"
const LS_PROVIDER = "blindjam_external_provider"
const LAUNCH_DEBOUNCE_MS = 4000

/**
 * Provider-agnostic playback facade for BlindJam (preview vs Spotify handoff).
 * Methods: resolveTrack, playPreview, openExternal, stop, onResumeFromExternal, getCurrentMode, startListeningFlow
 */
export function createPlaybackCoordinator(options = {}) {
  const { getAudioElement, getContext, context: staticContext = {} } = options

  function context() {
    if (typeof getContext === "function") return getContext()
    return staticContext
  }

  const previewAdapter = new PreviewPlaybackAdapter(getAudioElement)
  const spotifyAdapter = new SpotifyExternalAdapter()

  let resolvedTrack = null
  let externalLaunchInFlight = false
  let lastLaunchKey = null
  let lastLaunchAt = 0

  function getCurrentMode() {
    try {
      const m = localStorage.getItem(LS_MODE)
      if (m === PLAYBACK_MODE_EXTERNAL) return PLAYBACK_MODE_EXTERNAL
    } catch (_) { /* private mode */ }
    return PLAYBACK_MODE_PREVIEW
  }

  function getExternalProvider() {
    try {
      return localStorage.getItem(LS_PROVIDER) || "spotify"
    } catch (_) {
      return "spotify"
    }
  }

  async function resolveTrack(cardOrTrack) {
    const resolveUrl = cardOrTrack.resolveUrl || cardOrTrack.playbackUrl
    if (!resolveUrl) {
      playbackLog("error", "resolve_missing_url", {})
      throw new Error("missing_resolve_url")
    }

    const res = await fetch(resolveUrl, {
      headers: { Accept: "application/json" },
      credentials: "same-origin"
    })

    if (!res.ok) {
      playbackLog("error", "resolve_track_http", { status: res.status })
      throw new Error("resolve_failed")
    }

    const track = await res.json()

    if (!track.preview_url && track.preview_refresh_url) {
      try {
        const r2 = await fetch(track.preview_refresh_url, {
          headers: { Accept: "application/json" },
          credentials: "same-origin"
        })
        if (r2.ok) {
          const j2 = await r2.json()
          if (j2.preview_url) {
            track.preview_url = j2.preview_url
            track.preview_url_valid = true
          }
        }
      } catch (e) {
        playbackLog("warn", "preview_refresh_network", { message: e?.message })
      }
    }

    resolvedTrack = track
    playbackLog("info", "track_resolved", {
      token: track.token,
      hasPreview: !!track.preview_url,
      mode: getCurrentMode()
    })
    return track
  }

  async function playPreview(track) {
    const t = track || resolvedTrack
    return previewAdapter.playPreview(t)
  }

  function openExternal(track, provider) {
    const t = track || resolvedTrack
    const p = provider || getExternalProvider()
    if (p !== "spotify") {
      playbackLog("warn", "unknown_provider_fallback_spotify", { provider: p })
    }

    const key = `${t.token}:spotify`
    const now = Date.now()
    if (externalLaunchInFlight || (lastLaunchKey === key && now - lastLaunchAt < LAUNCH_DEBOUNCE_MS)) {
      playbackLog("warn", "external_launch_debounced", { key, msSinceLast: now - lastLaunchAt })
      return false
    }

    externalLaunchInFlight = true
    lastLaunchKey = key
    lastLaunchAt = now
    setTimeout(() => {
      externalLaunchInFlight = false
    }, 1200)

    const ctx = context()
    const ok = spotifyAdapter.openExternal(t, {
      gameId: ctx.gameId,
      path: ctx.path,
      launchId: `${now}-${Math.random().toString(36).slice(2, 9)}`
    })
    if (ok) playbackLog("info", "deep_link_dispatched", { token: t.token })
    return ok
  }

  function stop() {
    previewAdapter.stop()
  }

  function onResumeFromExternal() {
    const handoff = spotifyAdapter.readHandoff()
    const ctx = context()
    playbackLog("info", "app_resume_check_handoff", {
      hasHandoff: !!handoff,
      gameId: ctx.gameId,
      path: ctx.path
    })
    if (!handoff) return { restored: false }

    const gameMatch =
      handoff.gameId != null &&
      ctx.gameId != null &&
      String(handoff.gameId) === String(ctx.gameId)
    const pathMatch = handoff.path && ctx.path && handoff.path === ctx.path
    const sameGame = gameMatch || pathMatch

    spotifyAdapter.clearHandoff()

    if (sameGame) {
      playbackLog("info", "resumed_game_state", {
        token: handoff.token,
        provider: handoff.provider,
        pathMatch,
        gameMatch
      })
      return { restored: true, handoff }
    }

    playbackLog("warn", "resume_handoff_discarded_mismatch", {
      handoffGameId: handoff.gameId,
      contextGameId: ctx.gameId,
      handoffPath: handoff.path,
      contextPath: ctx.path
    })
    return { restored: false, handoff: null }
  }

  /**
   * High-level: resolve, then preview or Spotify based on settings and availability.
   */
  async function startListeningFlow({ resolveUrl }) {
    const track = await resolveTrack({ resolveUrl })
    const mode = getCurrentMode()
    const hasPreview = !!track.preview_url

    if (mode === PLAYBACK_MODE_PREVIEW && hasPreview) {
      const ok = await playPreview(track)
      if (ok) return { kind: "preview" }
      NullPlaybackAdapter.notify({
        reason: "preview_failed",
        onNotify: options.onManualFallback
      })
      return { kind: "manual", reason: "preview_failed" }
    }

    if (mode === PLAYBACK_MODE_EXTERNAL || !hasPreview) {
      if (!hasPreview) {
        playbackLog("info", "no_preview_routing_external", { token: track.token })
      }
      const launched = openExternal(track, "spotify")
      if (launched) return { kind: "external" }
      NullPlaybackAdapter.notify({
        reason: "external_failed",
        onNotify: options.onManualFallback
      })
      return { kind: "manual", reason: "external_failed" }
    }

    NullPlaybackAdapter.notify({
      reason: "no_preview",
      onNotify: options.onManualFallback
    })
    return { kind: "manual", reason: "no_preview" }
  }

  return {
    resolveTrack,
    playPreview,
    openExternal,
    stop,
    onResumeFromExternal,
    getCurrentMode,
    getExternalProvider,
    startListeningFlow,
    previewAdapter,
    spotifyAdapter
  }
}
