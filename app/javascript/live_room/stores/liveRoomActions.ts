import type { CardPayload, GameState, RoomState } from "../domain/types"
import type { Player } from "../domain/types"
import { createActionCableRoomTransport } from "../lib/realtime/actionCableRoomTransport"
import { applyRemoteSnapshot } from "../lib/realtime/applyRemoteSnapshot"
import type { RailsRoomSnapshot } from "../lib/realtime/mapRailsSnapshot"
import type { RoomTransport } from "../lib/realtime/transport"
import { gameEventToCablePayload } from "../lib/realtime/transport"
import { clearLiveRoomPersistence } from "../lib/persistence/clearSession"
import {
  addPlayerToRoomState,
  advanceToNextTurn,
  attachScannedCardToRound,
  beginPlayback,
  claimSteal,
  expireMainGuess,
  expireStealPhase,
  finishGame,
  removePlayerFromRoomState,
  startGame,
  submitMainGuess,
  submitStealGuess
} from "../lib/game/transitions"
import { cardPayloadFromQr, enrichCardFromPlaybackJson, parseQrPayload } from "../lib/game/qrAdapter"
import { bootstrapLiveRoom, type LiveRoomBootstrapConfig } from "./liveRoomBootstrap"
import { useGameStore } from "./gameStore"
import { useRoomStore } from "./roomStore"
import { useSyncStore } from "./syncStore"
import { useUiStore } from "./uiStore"

let transportRef: RoomTransport | null = null
let randomTrackUrlRef: string | null = null
let isHostRef = false

export function setTransport(t: RoomTransport | null): void {
  transportRef?.disconnect()
  transportRef = t
}

export function getTransport(): RoomTransport | null {
  return transportRef
}

export function setRandomTrackUrl(url: string | null): void {
  randomTrackUrlRef = url
}

function broadcastGameState(): void {
  if (!transportRef) return
  const { patchRoom, replaceRoom, ...room } = useRoomStore.getState()
  const { patchGame, replaceGame, ...game } = useGameStore.getState()
  transportRef.sendRoomEvent({
    type: "game_state",
    payload: { room, game } as unknown as Record<string, unknown>
  })
}

function applyHostGameState(payload: Record<string, unknown> | undefined): void {
  if (!payload) return
  const room = payload.room as Partial<RoomState> | undefined
  const game = payload.game as Partial<GameState> | undefined
  if (room) {
    useRoomStore.getState().patchRoom({
      status: room.status,
      hostId: room.hostId,
      players: room.players,
      settings: room.settings
    })
  }
  if (game) {
    useGameStore.getState().replaceGame(game as GameState)
  }
}

export function initLiveRoomFromDom(cfg: LiveRoomBootstrapConfig, cableUrl: string | null): () => void {
  isHostRef = cfg.isHost
  bootstrapLiveRoom(cfg)
  const mode = cfg.mode
  if (mode === "offline" || !cableUrl) {
    useRoomStore.getState().patchRoom({ connected: true, connectionLabel: "Local" })
    return () => {}
  }
  const transport = createActionCableRoomTransport(cableUrl)
  setTransport(transport)
  const unsub = transport.subscribe(cfg.code, (msg) => {
    const m = msg as { type?: string; state?: RailsRoomSnapshot; payload?: Record<string, unknown> }
    if (m?.type === "game_state") {
      applyHostGameState(m.payload)
      return
    }
    if (m?.state) applyRemoteSnapshot(m.state as RailsRoomSnapshot)
  })
  useRoomStore.getState().patchRoom({ connected: true, connectionLabel: "Live" })
  return () => {
    unsub()
    setTransport(null)
  }
}

export async function fetchInitialState(stateUrl: string): Promise<RailsRoomSnapshot | null> {
  useSyncStore.getState().setReconcileStatus("syncing")
  try {
    const res = await fetch(stateUrl, { headers: { Accept: "application/json" }, credentials: "same-origin" })
    if (!res.ok) throw new Error(String(res.status))
    const json = (await res.json()) as RailsRoomSnapshot
    applyRemoteSnapshot(json)
    useSyncStore.getState().setReconcileStatus("idle")
    return json
  } catch {
    useSyncStore.getState().setReconcileStatus("error")
    useUiStore.getState().pushToast("Could not sync room state", "error")
    return null
  }
}

interface RandomTrackResponse {
  id: number
  token: string
  title: string
  artist_name: string
  release_year?: number
  preview_url: string
  album_cover_url?: string
  album_name?: string
}

async function fetchAndAttachRandomTrack(): Promise<void> {
  if (!randomTrackUrlRef) return

  const game = useGameStore.getState()
  const room = useRoomStore.getState()

  const playedIds = game.roundHistory
    .map((r) => r.card?.songId)
    .filter((id): id is string => Boolean(id))
    .join(",")

  try {
    const sep = randomTrackUrlRef.includes("?") ? "&" : "?"
    const url = playedIds
      ? `${randomTrackUrlRef}${sep}played_ids=${playedIds}`
      : randomTrackUrlRef

    const res = await fetch(url, {
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })

    if (!res.ok) {
      const body = (await res.json().catch(() => ({}))) as Record<string, string>
      throw new Error(body.error || `HTTP ${res.status}`)
    }

    const track = (await res.json()) as RandomTrackResponse

    const card: CardPayload = {
      cardId: `track:${track.id}`,
      songId: String(track.id),
      title: track.title,
      artist: track.artist_name,
      year: track.release_year,
      albumName: track.album_name,
      deezerPreviewUrl: track.preview_url,
      artworkUrl: track.album_cover_url
    }

    const ok1 = liveRoomActions.attachScannedCard(card, room.hostId)
    if (ok1) liveRoomActions.beginPlayback()
  } catch (err) {
    useUiStore.getState().pushToast(
      `Could not load track: ${err instanceof Error ? err.message : "unknown"}`,
      "error"
    )
  }
}

export const liveRoomActions = {
  bootstrap: bootstrapLiveRoom,

  addPlayer(player: Player): boolean {
    const room = useRoomStore.getState()
    const r = addPlayerToRoomState(room, player)
    if (!r.ok) {
      useUiStore.getState().pushToast(r.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(r.room)
    useGameStore.getState().patchGame({
      turnOrder: [...new Set([...useGameStore.getState().turnOrder, player.id])]
    })
    return true
  },

  removePlayer(playerId: string): boolean {
    const room = useRoomStore.getState()
    const r = removePlayerFromRoomState(room, playerId)
    if (!r.ok) return false
    useRoomStore.getState().replaceRoom(r.room)
    useGameStore.getState().patchGame({
      turnOrder: useGameStore.getState().turnOrder.filter((id) => id !== playerId)
    })
    return true
  },

  startGame(): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = startGame(room, game, Date.now())
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    if (out.room.mode !== "offline" && randomTrackUrlRef) {
      void fetchAndAttachRandomTrack()
    }
    return true
  },

  startTurnFromResult(): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = advanceToNextTurn(room, game, Date.now())
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    if (out.room.mode !== "offline" && randomTrackUrlRef) {
      void fetchAndAttachRandomTrack()
    }
    return true
  },

  finishGame(): void {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = finishGame(room, game)
    if (out.ok) {
      useRoomStore.getState().replaceRoom(out.room)
      useGameStore.getState().replaceGame(out.game)
      broadcastGameState()
    }
  },

  clearAfterGame(): void {
    clearLiveRoomPersistence()
    useGameStore.persist.clearStorage()
    useRoomStore.persist.clearStorage()
  },

  attachScannedCard(card: CardPayload, scannerId: string): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = attachScannedCardToRound(room, game, card, scannerId, Date.now())
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    return true
  },

  beginPlayback(): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = beginPlayback(room, game, Date.now())
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    return true
  },

  submitMainGuess(playerId: string, text: string, yearGuess?: string): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const y = yearGuess?.trim() || undefined
    const out = submitMainGuess(room, game, playerId, text.trim(), Date.now(), y)
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    return true
  },

  expireMainGuess(): void {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = expireMainGuess(room, game, Date.now())
    if (out.ok) {
      useRoomStore.getState().replaceRoom(out.room)
      useGameStore.getState().replaceGame(out.game)
      broadcastGameState()
    }
  },

  claimSteal(playerId: string): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = claimSteal(room, game, playerId, Date.now())
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    return true
  },

  submitStealGuess(playerId: string, text: string, yearGuess?: string): boolean {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const y = yearGuess?.trim() || undefined
    const out = submitStealGuess(room, game, playerId, text.trim(), Date.now(), y)
    if (!out.ok) {
      useUiStore.getState().pushToast(out.reason, "error")
      return false
    }
    useRoomStore.getState().replaceRoom(out.room)
    useGameStore.getState().replaceGame(out.game)
    broadcastGameState()
    return true
  },

  expireStealPhase(): void {
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    const out = expireStealPhase(room, game, Date.now())
    if (out.ok) {
      useRoomStore.getState().replaceRoom(out.room)
      useGameStore.getState().replaceGame(out.game)
      broadcastGameState()
    }
  },

  retryAutoTrack(): void {
    void fetchAndAttachRandomTrack()
  },

  async handleQrScan(raw: string, scannerId: string, origin: string): Promise<void> {
    const parsed = parseQrPayload(raw)
    if (!parsed) {
      useUiStore.getState().pushToast("Unrecognized QR", "error")
      return
    }
    let card = cardPayloadFromQr(parsed, origin)
    const room = useRoomStore.getState()
    if (room.mode !== "offline" && transportRef && parsed.kind === "track_token") {
      const payload = gameEventToCablePayload({
        type: "CARD_SCANNED",
        payload: { card, byPlayerId: scannerId }
      })
      if (payload) transportRef.sendRoomEvent(payload)
    }
    if (card.resolveUrl && parsed.kind === "track_token") {
      try {
        const res = await fetch(card.resolveUrl, { credentials: "same-origin", headers: { Accept: "application/json" } })
        if (res.ok) {
          const json = (await res.json()) as Record<string, unknown>
          card = enrichCardFromPlaybackJson(card, json)
        }
      } catch {
        /* preview optional */
      }
    }
    liveRoomActions.attachScannedCard(card, scannerId)
    useUiStore.getState().closeQrDrawer()
  },

  async hostReveal(csrfToken: string, url: string): Promise<void> {
    const body = new URLSearchParams({ authenticity_token: csrfToken })
    await fetch(url, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "text/html, application/json"
      },
      body
    })
  },

  async hostNext(csrfToken: string, url: string): Promise<void> {
    const body = new URLSearchParams({ authenticity_token: csrfToken })
    await fetch(url, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "text/html, application/json"
      },
      body
    })
  }
}
