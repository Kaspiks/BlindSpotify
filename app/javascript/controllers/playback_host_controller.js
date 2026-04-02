import { Controller } from "@hotwired/stimulus"
import { createPlaybackCoordinator } from "playback/playback_coordinator"
import { playbackLog } from "playback/playback_logger"

// Host UX: preview vs Spotify handoff, Capacitor resume, debounced external launch, error surfaces.
export default class extends Controller {
  static values = {
    resolveUrl: String,
    gameId: String,
    loadingTrack: { type: String, default: "Loading track…" },
    loadingPreview: { type: String, default: "Loading preview…" },
    openingSpotify: { type: String, default: "Opening Spotify…" },
    externalHint: {
      type: String,
      default: "If Spotify opens, start playback, then return here to continue."
    },
    errorResolve: { type: String, default: "Could not load this track." },
    errorPreview: { type: String, default: "Preview is not available for this track." },
    errorNetwork: { type: String, default: "Network error. Try again." },
    errorSpotify: { type: String, default: "Could not open Spotify. Try the web link from settings." },
    resumeMessage: {
      type: String,
      default: "You're back — continue when you're ready."
    },
    manualHint: { type: String, default: "Use Reveal or Skip when you are ready." }
  }

  static targets = [
    "transitionOverlay",
    "transitionMessage",
    "transitionHint",
    "errorPanel",
    "errorMessage",
    "resumeBanner",
    "resumeMessage",
    "listenButton",
    "previewAudio",
    "externalOnlyButton"
  ]

  connect() {
    this._resumeTimer = null
    this._rebuildCoordinator()

    this._onVisibility = () => {
      if (document.hidden) {
        playbackLog("info", "document_hidden", {})
      } else {
        playbackLog("info", "document_visible", {})
        this.scheduleResumeCheck("visibility")
      }
    }
    document.addEventListener("visibilitychange", this._onVisibility)

    this._setupCapacitorListeners()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this._onVisibility)
    this._teardownCapacitorListeners()
    clearTimeout(this._resumeTimer)
    this.coordinator?.stop()
  }

  gameIdValueChanged() {
    this._rebuildCoordinator()
  }

  _rebuildCoordinator() {
    this.coordinator = createPlaybackCoordinator({
      getAudioElement: () => (this.hasPreviewAudioTarget ? this.previewAudioTarget : null),
      getContext: () => ({
        gameId: this.gameIdValue,
        path: typeof window !== "undefined" ? window.location.pathname : ""
      }),
      onManualFallback: () => this.flashErrorMessage(this.manualHintValue)
    })
  }

  async _setupCapacitorListeners() {
    const App = typeof window !== "undefined" ? window.Capacitor?.Plugins?.App : null
    if (!App?.addListener) return

    try {
      this._capPause = await App.addListener("pause", () => {
        playbackLog("info", "capacitor_pause", {})
      })
      this._capResume = await App.addListener("resume", () => {
        playbackLog("info", "capacitor_resume", {})
        this.scheduleResumeCheck("capacitor")
      })
    } catch (e) {
      playbackLog("warn", "capacitor_app_listener_setup_failed", { message: e?.message })
    }
  }

  _teardownCapacitorListeners() {
    this._capPause?.remove?.()
    this._capResume?.remove?.()
    this._capPause = null
    this._capResume = null
  }

  scheduleResumeCheck(source) {
    clearTimeout(this._resumeTimer)
    this._resumeTimer = setTimeout(() => this.runResumeFromExternal(source), 220)
  }

  runResumeFromExternal(source) {
    if (!this.coordinator) return
    const result = this.coordinator.onResumeFromExternal()
    playbackLog("info", "resume_handler_result", { source, restored: result.restored })
    if (!result.restored) return

    if (this.hasResumeBannerTarget) {
      this.resumeBannerTarget.classList.remove("hidden")
    }
    if (this.hasResumeMessageTarget && result.handoff) {
      const t = result.handoff.trackTitle || ""
      const a = result.handoff.trackArtist || ""
      this.resumeMessageTarget.textContent = this.resumeMessageValue
        .replace("%{title}", t)
        .replace("%{artist}", a)
    }

    this.dispatch("resumed", { detail: result, prefix: "playback" })
  }

  dismissResume() {
    if (this.hasResumeBannerTarget) this.resumeBannerTarget.classList.add("hidden")
  }

  hideTransition() {
    if (this.hasTransitionOverlayTarget) this.transitionOverlayTarget.classList.add("hidden")
  }

  showTransition(messageKey) {
    if (!this.hasTransitionOverlayTarget) return
    this.transitionOverlayTarget.classList.remove("hidden")
    if (this.hasTransitionMessageTarget) {
      const map = {
        loading: this.loadingTrackValue,
        external: this.openingSpotifyValue,
        preview: this.loadingPreviewValue
      }
      this.transitionMessageTarget.textContent = map[messageKey] || this.loadingTrackValue
    }
    if (this.hasTransitionHintTarget) {
      this.transitionHintTarget.textContent =
        messageKey === "preview" ? "" : this.externalHintValue
    }
  }

  hideError() {
    if (this.hasErrorPanelTarget) this.errorPanelTarget.classList.add("hidden")
  }

  flashErrorMessage(text) {
    if (!this.hasErrorPanelTarget || !this.hasErrorMessageTarget) return
    this.errorMessageTarget.textContent = text
    this.errorPanelTarget.classList.remove("hidden")
  }

  showError(kind) {
    const keys = {
      resolve: this.errorResolveValue,
      preview: this.errorPreviewValue,
      network: this.errorNetworkValue,
      spotify: this.errorSpotifyValue
    }
    this.flashErrorMessage(keys[kind] || this.errorResolveValue)
  }

  async startListening(event) {
    event?.preventDefault()
    this.hideError()
    this.dismissResume()

    const btn = this.hasListenButtonTarget ? this.listenButtonTarget : null
    if (btn) btn.disabled = true

    try {
      this.showTransition("loading")
      const mode = this.coordinator.getCurrentMode()
      if (mode === "preview") this.showTransition("preview")

      const flow = await this.coordinator.startListeningFlow({ resolveUrl: this.resolveUrlValue })
      playbackLog("info", "start_listening_flow_done", { kind: flow.kind, reason: flow.reason })

      if (flow.kind === "preview") {
        this.hideTransition()
      } else if (flow.kind === "external") {
        this.showTransition("external")
        setTimeout(() => this.hideTransition(), 2000)
      } else {
        this.hideTransition()
        if (flow.reason === "no_preview") this.showError("preview")
        else this.showError("spotify")
      }
    } catch (e) {
      playbackLog("error", "start_listening_failed", { message: e?.message })
      this.hideTransition()
      const msg = e?.message || ""
      if (msg.includes("fetch") || msg.includes("network")) this.showError("network")
      else this.showError("resolve")
    } finally {
      if (btn) btn.disabled = false
    }
  }

  async openExternalOnly(event) {
    event?.preventDefault()
    const btn = this.hasExternalOnlyButtonTarget ? this.externalOnlyButtonTarget : null
    if (btn) btn.disabled = true
    try {
      this.showTransition("loading")
      const track = await this.coordinator.resolveTrack({ resolveUrl: this.resolveUrlValue })
      this.showTransition("external")
      this.coordinator.openExternal(track, "spotify")
      setTimeout(() => this.hideTransition(), 2000)
    } catch (e) {
      playbackLog("error", "open_external_only_failed", { message: e?.message })
      this.hideTransition()
      this.showError("spotify")
    } finally {
      if (btn) btn.disabled = false
    }
  }
}
