import type { GameState, Player, RoomState, Round } from "../../domain/types"

export type GuardFail = { ok: false; reason: string }
export type GuardOk = { ok: true }

export function assertRound(
  game: GameState
): { ok: true; round: Round } | GuardFail {
  const r = game.currentRound
  if (!r) return { ok: false, reason: "no_active_round" }
  return { ok: true, round: r }
}

export function assertPhase(round: Round, phases: Round["phase"][]): GuardOk | GuardFail {
  if (!phases.includes(round.phase)) {
    return { ok: false, reason: `invalid_phase:${round.phase}` }
  }
  return { ok: true }
}

export function assertActivePlayer(playerId: string, round: Round): GuardOk | GuardFail {
  if (round.activePlayerId !== playerId) {
    return { ok: false, reason: "not_active_player" }
  }
  return { ok: true }
}

export function assertNotActivePlayer(playerId: string, round: Round): GuardOk | GuardFail {
  if (round.activePlayerId === playerId) {
    return { ok: false, reason: "active_player_cannot_steal" }
  }
  return { ok: true }
}

export function findPlayer(players: Player[], id: string): Player | undefined {
  return players.find((p) => p.id === id)
}

export function canMainGuess(room: RoomState, game: GameState, playerId: string): boolean {
  if (room.status !== "in_round") return false
  const r = game.currentRound
  if (!r || r.phase !== "main_guess_open") return false
  if (r.activePlayerId !== playerId) return false
  return !r.guesses.some((g) => g.playerId === playerId && g.method === "main_guess")
}

export function canClaimSteal(room: RoomState, game: GameState, playerId: string): boolean {
  if (room.status !== "in_round") return false
  const r = game.currentRound
  if (!r || r.phase !== "steal_open") return false
  if (r.activePlayerId === playerId) return false
  if (r.stealLockedPlayerId && r.stealLockedPlayerId !== playerId) return false
  if (r.stealLockedPlayerId === playerId) return true
  return true
}

export function canSubmitStealGuess(room: RoomState, game: GameState, playerId: string): boolean {
  if (room.status !== "in_round") return false
  const r = game.currentRound
  if (!r || r.phase !== "steal_locked") return false
  return r.stealLockedPlayerId === playerId
}
