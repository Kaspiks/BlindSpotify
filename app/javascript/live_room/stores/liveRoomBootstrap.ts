import type { RoomMode } from "../domain/types"
import { createHostPlayer, createInitialRoomState } from "../lib/game/initialState"
import { hydrateFromSnapshotIfPresent } from "../lib/realtime/applyRemoteSnapshot"
import type { RailsRoomSnapshot } from "../lib/realtime/mapRailsSnapshot"
import { mapRailsPlayersToClient } from "../lib/realtime/mapRailsSnapshot"
import { useGameStore } from "./gameStore"
import { useRoomStore } from "./roomStore"
import { useSyncStore } from "./syncStore"
import { useUiStore } from "./uiStore"

export type LiveRoomBootstrapConfig = {
  roomNumericId: string
  code: string
  mode: RoomMode
  hostId: string
  hostDisplayName: string
  selfPlayerId?: string | null
  isHost: boolean
  initialSnapshot?: RailsRoomSnapshot | null
}

export function bootstrapLiveRoom(config: LiveRoomBootstrapConfig): void {
  if (config.mode === "offline") {
    try {
      const raw = localStorage.getItem("live_room_room_v1")
      if (raw) {
        const parsed = JSON.parse(raw) as { state?: { code?: string; status?: string } }
        const s = parsed.state
        if (
          s?.code === config.code &&
          (s.status === "in_round" || s.status === "round_result")
        ) {
          useSyncStore.getState().resetSyncMeta()
          return
        }
      }
    } catch {
      /* ignore */
    }
  }

  useSyncStore.getState().resetSyncMeta()
  useUiStore.getState().setRoundResultModalOpen(false)
  useUiStore.getState().closeQrDrawer()

  const initial = createInitialRoomState({
    code: config.code,
    roomNumericId: config.roomNumericId,
    hostId: config.hostId,
    hostDisplayName: config.hostDisplayName,
    mode: config.mode
  })

  let room = initial.room
  let game = initial.game

  if (config.mode !== "offline" && config.initialSnapshot) {
    const hostId = config.hostId
    const remotePlayers = mapRailsPlayersToClient(config.initialSnapshot.players, hostId)
    if (remotePlayers.length > 0) {
      room = {
        ...room,
        players: remotePlayers.map((p) => ({
          ...p,
          isHost:
            p.isHost ||
            Boolean(config.isHost && config.selfPlayerId && p.id === config.selfPlayerId)
        }))
      }
      const turnIds = remotePlayers.map((p) => p.id)
      if (turnIds.length) {
        game = { ...game, turnOrder: turnIds }
      }
    }
    const le = config.initialSnapshot.last_event
    if (typeof le?.id === "number") {
      useSyncStore.getState().setLastRemoteEventId(le.id)
    }
    if (typeof config.initialSnapshot.v === "number") {
      useSyncStore.getState().setLastSnapshotVersion(config.initialSnapshot.v)
    }
  }

  if (config.selfPlayerId && !room.players.some((p) => p.id === config.selfPlayerId)) {
    room = {
      ...room,
      players: [
        ...room.players,
        {
          id: config.selfPlayerId,
          displayName: "You",
          isHost: config.isHost,
          isConnected: true,
          presence: config.mode === "offline" ? "local" : "remote",
          score: 0
        }
      ]
    }
    game = {
      ...game,
      turnOrder: [...new Set([...game.turnOrder, config.selfPlayerId])]
    }
  }

  const hydrated = hydrateFromSnapshotIfPresent(room, game, config.initialSnapshot ?? null)
  room = hydrated.room
  game = hydrated.game

  const hasHostPlayer = room.players.some((p) => p.isHost)
  if (config.isHost && !hasHostPlayer) {
    room = {
      ...room,
      players: [...room.players, createHostPlayer(config.hostId, config.hostDisplayName)]
    }
    game = {
      ...game,
      turnOrder: [...new Set([config.hostId, ...game.turnOrder])]
    }
  }

  useRoomStore.getState().replaceRoom({
    ...room,
    connected: config.mode !== "offline",
    connectionLabel: config.mode === "offline" ? "Local" : "Connecting…"
  })
  useGameStore.getState().replaceGame(game)
}
