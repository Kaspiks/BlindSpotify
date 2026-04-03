import type { GameState, RoomState, Round } from "../../domain/types"
import { useGameStore } from "../../stores/gameStore"
import { useRoomStore } from "../../stores/roomStore"
import { useSyncStore } from "../../stores/syncStore"
import { cardFromRailsRound, mapRailsPlayersToClient, type RailsRoomSnapshot } from "./mapRailsSnapshot"

/**
 * Merge authoritative Rails Pattern B snapshot into local stores without destroying
 * client-only turn/round state when possible.
 */
export function applyRemoteSnapshot(snapshot: RailsRoomSnapshot): void {
  const lastEvent = snapshot.last_event
  const eventId = typeof lastEvent?.id === "number" ? lastEvent.id : 0
  const prevId = useSyncStore.getState().lastRemoteEventId
  if (eventId > 0 && eventId < prevId) {
    console.warn("[live_room] Ignoring stale snapshot", { eventId, prevId })
    return
  }
  if (eventId > 0) {
    useSyncStore.getState().setLastRemoteEventId(eventId)
  }
  if (typeof snapshot.v === "number") {
    useSyncStore.getState().setLastSnapshotVersion(snapshot.v)
  }

  const room = useRoomStore.getState()
  const game = useGameStore.getState()
  const hostId = room.hostId || snapshot.room?.host_player_id || ""

  const mergedPlayers = mapRailsPlayersToClient(snapshot.players, hostId)
  if (mergedPlayers.length > 0) {
    useRoomStore.getState().patchRoom({
      players: mergePlayersById(room.players, mergedPlayers),
      code: snapshot.room?.code ?? room.code,
      connected: true,
      connectionLabel: "Synced"
    })
  }

  const round = snapshot.round
  if (round?.track_id && game.currentRound) {
    const remoteCard = cardFromRailsRound(round)
    if (remoteCard && !game.currentRound.card?.deezerPreviewUrl && remoteCard.deezerPreviewUrl) {
      const cr: Round = {
        ...game.currentRound,
        card: { ...game.currentRound.card, ...remoteCard }
      }
      useGameStore.getState().patchGame({ currentRound: cr })
    }
  }
}

function mergePlayersById(local: RoomState["players"], remote: RoomState["players"]): RoomState["players"] {
  const byId = new Map(local.map((p) => [p.id, { ...p }]))
  for (const r of remote) {
    const existing = byId.get(r.id)
    if (existing) {
      byId.set(r.id, {
        ...existing,
        displayName: r.displayName,
        score: r.score,
        isConnected: r.isConnected,
        isHost: r.isHost
      })
    } else {
      byId.set(r.id, r)
    }
  }
  return Array.from(byId.values())
}

export function hydrateFromSnapshotIfPresent(
  room: RoomState,
  game: GameState,
  snapshot: RailsRoomSnapshot | null
): { room: RoomState; game: GameState } {
  if (!snapshot) return { room, game }
  const hostId = room.hostId || snapshot.room?.host_player_id || ""
  const players = mapRailsPlayersToClient(snapshot.players, hostId)
  let nextRoom = { ...room, players: players.length ? players : room.players }
  const round = snapshot.round
  let nextGame = { ...game }
  if (round?.track_id) {
    const card = cardFromRailsRound(round)
    if (card && nextGame.currentRound) {
      nextGame = {
        ...nextGame,
        currentRound: { ...nextGame.currentRound, card: { ...nextGame.currentRound.card, ...card } }
      }
    }
  }
  return { room: nextRoom, game: nextGame }
}
