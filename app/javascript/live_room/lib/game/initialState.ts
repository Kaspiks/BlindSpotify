import { defaultRoomSettings, type GameState, type Player, type RoomState } from "../../domain/types"

let idCounter = 0
export function genId(prefix: string): string {
  idCounter += 1
  return `${prefix}_${Date.now().toString(36)}_${idCounter}`
}

export function createHostPlayer(hostId: string, displayName: string): Player {
  return {
    id: hostId,
    displayName,
    isHost: true,
    isConnected: true,
    presence: "local",
    score: 0,
    stealsRemaining: undefined
  }
}

export function createInitialRoomState(input: {
  code: string
  roomNumericId: string
  hostId: string
  hostDisplayName: string
  mode: RoomState["mode"]
}): { room: RoomState; game: GameState } {
  const room: RoomState = {
    id: input.roomNumericId,
    code: input.code,
    mode: input.mode,
    status: "lobby",
    hostId: input.hostId,
    players: [createHostPlayer(input.hostId, input.hostDisplayName)],
    settings: defaultRoomSettings(),
    createdBy: input.hostId,
    connected: input.mode !== "offline",
    connectionLabel: input.mode === "offline" ? "Local" : "Connecting…"
  }

  const game: GameState = {
    turnOrder: [input.hostId],
    activePlayerIndex: 0,
    currentRound: null,
    roundHistory: [],
    timerGeneration: 0,
    phaseDeadlineAt: null,
    phaseStartedAt: null,
    currentRoundNumber: 0
  }

  return { room, game }
}
