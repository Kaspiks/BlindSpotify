import type { GameState, RoomState, CardPayload, Guess, GuessMatchDetail, Round, RoomSessionStatus } from "../../domain/types"
import { genId } from "./initialState"
import { applyScoresToPlayers, buildRoundResult } from "./scoring"
import { checkGuess } from "./matching"
import {
  assertActivePlayer,
  assertNotActivePlayer,
  assertPhase,
  assertRound,
  type GuardFail
} from "./guards"

export type TransitionResult =
  | { ok: true; room: RoomState; game: GameState }
  | GuardFail

function fail(reason: string): GuardFail {
  return { ok: false, reason }
}

/** Parse release year from card metadata (number, "1999", "Jan 1999", etc.). */
export function parseReleaseYear(value: number | string | undefined): number | null {
  if (value == null || value === "") return null
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value)
  const s = String(value).trim()
  const m = s.match(/\b(1[0-9]{3}|20[0-9]{2})\b/)
  if (m) return parseInt(m[1]!, 10)
  const n = parseInt(s, 10)
  return Number.isFinite(n) && n >= 1000 && n <= 2999 ? n : null
}

function parseGuessedYear(input: string | undefined): number | null {
  if (input == null) return null
  const t = input.trim()
  if (!t) return null
  const n = parseInt(t, 10)
  return Number.isFinite(n) && n >= 1000 && n <= 2999 ? n : null
}

export function yearGuessMatchesCard(cardYear: number | string | undefined, yearGuess: string | undefined): boolean {
  const cy = parseReleaseYear(cardYear)
  const gy = parseGuessedYear(yearGuess)
  if (cy == null || gy == null) return false
  return cy === gy
}

export function evaluateGuess(card: CardPayload, text: string, yearGuess?: string): GuessMatchDetail | null {
  const t = text.trim()
  if (!t) return null
  const title = card.title?.trim() ?? ""
  const artist = card.artist?.trim() ?? ""
  const titleMatched = !!(title && checkGuess(t, title))
  const artistMatched = !!(artist && checkGuess(t, artist))
  if (!titleMatched && !artistMatched) return null
  const yearMatched = yearGuessMatchesCard(card.year, yearGuess)
  return { titleMatched, artistMatched, yearMatched }
}

export function addPlayerToRoomState(room: RoomState, player: RoomState["players"][0]): { ok: true; room: RoomState } | GuardFail {
  if (room.players.some((p) => p.id === player.id)) return fail("player_already_in_room")
  return { ok: true, room: { ...room, players: [...room.players, player] } }
}

export function removePlayerFromRoomState(room: RoomState, playerId: string): { ok: true; room: RoomState } | GuardFail {
  const next = room.players.filter((p) => p.id !== playerId)
  if (next.length === room.players.length) return fail("player_not_found")
  return { ok: true, room: { ...room, players: next } }
}

export function startGame(room: RoomState, game: GameState, now: number): TransitionResult {
  if (room.status !== "lobby" && room.status !== "countdown") return fail("invalid_room_status")
  if (room.players.length < 1) return fail("need_players")
  const turnOrder = room.players.map((p) => p.id)
  let g: GameState = {
    ...game,
    turnOrder,
    activePlayerIndex: 0,
    currentRound: null,
    roundHistory: game.roundHistory,
    timerGeneration: game.timerGeneration + 1,
    phaseDeadlineAt: null,
    phaseStartedAt: null,
    currentRoundNumber: 0
  }
  const roomNext: RoomState = { ...room, status: "in_round" }
  return startTurn(roomNext, g, now)
}

export function startTurn(room: RoomState, game: GameState, now: number): TransitionResult {
  if (room.status !== "in_round" && room.status !== "round_result") return fail("invalid_room_status")
  const order = game.turnOrder
  if (!order.length) return fail("empty_turn_order")
  const idx = game.activePlayerIndex % order.length
  const activePlayerId = order[idx]!
  const roundNumber = game.currentRoundNumber + 1
  const maxRounds = room.settings.maxRounds
  if (maxRounds > 0 && roundNumber > maxRounds) {
    return finishGame(room, game)
  }

  const initialPhase = room.mode === "online" ? "loading_track" as const : "waiting_for_scan" as const

  const round: Round = {
    id: genId("round"),
    number: roundNumber,
    activePlayerId,
    card: null,
    phase: initialPhase,
    guesses: [],
    stealLockedPlayerId: null,
    stealAttemptsCount: 0,
    mainGuessExpired: false,
    result: null,
    startedAt: now,
    attachedCardId: null
  }

  const roomNext: RoomState = { ...room, status: "in_round" }
  const gameNext: GameState = {
    ...game,
    currentRound: round,
    currentRoundNumber: roundNumber,
    timerGeneration: game.timerGeneration + 1,
    phaseDeadlineAt: null,
    phaseStartedAt: null
  }
  return { ok: true, room: roomNext, game: gameNext }
}

export function attachScannedCardToRound(
  room: RoomState,
  game: GameState,
  card: CardPayload,
  scannerId: string,
  now: number
): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["waiting_for_scan", "loading_track"])
  if (!ph.ok) return ph
  if (round.attachedCardId === card.cardId) return fail("duplicate_card_scan")
  const hostScan = scannerId === room.hostId
  if (!hostScan && scannerId !== round.activePlayerId) {
    return fail("only_active_player_or_host_scans")
  }

  const nextRound: Round = {
    ...round,
    card,
    phase: "scanned",
    attachedCardId: card.cardId
  }
  return {
    ok: true,
    room,
    game: { ...game, currentRound: nextRound, timerGeneration: game.timerGeneration + 1 }
  }
}

export function beginPlayback(room: RoomState, game: GameState, now: number): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["scanned"])
  if (!ph.ok) return ph
  const deadline = now + room.settings.guessTimeLimitSec * 1000
  const nextRound: Round = {
    ...round,
    phase: "main_guess_open"
  }
  return {
    ok: true,
    room,
    game: {
      ...game,
      currentRound: nextRound,
      phaseStartedAt: now,
      phaseDeadlineAt: deadline,
      timerGeneration: game.timerGeneration + 1
    }
  }
}

function guessId() {
  return genId("guess")
}

export function submitMainGuess(
  room: RoomState,
  game: GameState,
  playerId: string,
  text: string,
  now: number,
  yearGuess?: string
): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["main_guess_open"])
  if (!ph.ok) return ph
  const ap = assertActivePlayer(playerId, round)
  if (!ap.ok) return ap
  if (round.guesses.some((g) => g.playerId === playerId && g.method === "main_guess")) {
    return fail("duplicate_main_guess")
  }
  if (!round.card) return fail("no_card")

  const yearTrimmed = yearGuess?.trim() || undefined
  const matchDetail = evaluateGuess(round.card, text, yearTrimmed)
  const correct = matchDetail !== null
  const guess: Guess = {
    id: guessId(),
    playerId,
    text,
    yearGuess: yearTrimmed,
    submittedAt: now,
    isCorrect: correct,
    matchDetail: matchDetail ?? undefined,
    method: "main_guess"
  }
  const guesses = [...round.guesses, guess]

  if (correct) {
    const result = buildRoundResult("main_correct", playerId, room.settings, matchDetail ?? undefined)
    const players = applyScoresToPlayers(room.players, result.pointsAwarded)
    const resolvedRound: Round = {
      ...round,
      guesses,
      phase: "resolved",
      result,
      mainGuessExpired: false
    }
    const gameNext: GameState = {
      ...game,
      currentRound: resolvedRound,
      roundHistory: [...game.roundHistory, resolvedRound],
      phaseDeadlineAt: null,
      phaseStartedAt: null,
      timerGeneration: game.timerGeneration + 1
    }
    return {
      ok: true,
      room: { ...room, status: "round_result", players },
      game: gameNext
    }
  }

  const nextRound: Round = {
    ...round,
    guesses,
    phase: "steal_open",
    stealLockedPlayerId: null,
    mainGuessExpired: false
  }
  const stealDeadline = now + room.settings.stealTimeLimitSec * 1000
  return {
    ok: true,
    room,
    game: {
      ...game,
      currentRound: nextRound,
      phaseStartedAt: now,
      phaseDeadlineAt: stealDeadline,
      timerGeneration: game.timerGeneration + 1
    }
  }
}

export function expireMainGuess(room: RoomState, game: GameState, now: number): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["main_guess_open"])
  if (!ph.ok) return ph

  const nextRound: Round = {
    ...round,
    phase: "steal_open",
    mainGuessExpired: true,
    stealLockedPlayerId: null
  }
  const stealDeadline = now + room.settings.stealTimeLimitSec * 1000
  return {
    ok: true,
    room,
    game: {
      ...game,
      currentRound: nextRound,
      phaseStartedAt: now,
      phaseDeadlineAt: stealDeadline,
      timerGeneration: game.timerGeneration + 1
    }
  }
}

export function claimSteal(room: RoomState, game: GameState, playerId: string, now: number): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["steal_open"])
  if (!ph.ok) return ph
  const nap = assertNotActivePlayer(playerId, round)
  if (!nap.ok) return nap
  if (round.stealLockedPlayerId && round.stealLockedPlayerId !== playerId) {
    return fail("steal_held_by_other")
  }

  const nextRound: Round = {
    ...round,
    phase: "steal_locked",
    stealLockedPlayerId: playerId
  }
  const deadline = now + room.settings.stealTimeLimitSec * 1000
  return {
    ok: true,
    room,
    game: {
      ...game,
      currentRound: nextRound,
      phaseStartedAt: now,
      phaseDeadlineAt: deadline,
      timerGeneration: game.timerGeneration + 1
    }
  }
}

export function submitStealGuess(
  room: RoomState,
  game: GameState,
  playerId: string,
  text: string,
  now: number,
  yearGuess?: string
): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["steal_locked"])
  if (!ph.ok) return ph
  if (round.stealLockedPlayerId !== playerId) return fail("not_steal_holder")
  if (!round.card) return fail("no_card")

  const yearTrimmed = yearGuess?.trim() || undefined
  const matchDetail = evaluateGuess(round.card, text, yearTrimmed)
  const correct = matchDetail !== null
  const guess: Guess = {
    id: guessId(),
    playerId,
    text,
    yearGuess: yearTrimmed,
    submittedAt: now,
    isCorrect: correct,
    matchDetail: matchDetail ?? undefined,
    method: "steal"
  }
  const guesses = [...round.guesses, guess]
  const attempts = round.stealAttemptsCount + 1
  const { allowMultipleSteals, maxStealAttemptsPerRound } = room.settings

  if (correct) {
    const result = buildRoundResult("steal_correct", playerId, room.settings, matchDetail ?? undefined)
    const players = applyScoresToPlayers(room.players, result.pointsAwarded)
    const resolvedRound: Round = {
      ...round,
      guesses,
      stealAttemptsCount: attempts,
      phase: "resolved",
      result,
      stealLockedPlayerId: null
    }
    const gameNext: GameState = {
      ...game,
      currentRound: resolvedRound,
      roundHistory: [...game.roundHistory, resolvedRound],
      phaseDeadlineAt: null,
      phaseStartedAt: null,
      timerGeneration: game.timerGeneration + 1
    }
    return {
      ok: true,
      room: { ...room, status: "round_result", players },
      game: gameNext
    }
  }

  if (allowMultipleSteals && attempts < maxStealAttemptsPerRound) {
    const nextRound: Round = {
      ...round,
      guesses,
      stealAttemptsCount: attempts,
      phase: "steal_open",
      stealLockedPlayerId: null
    }
    const stealDeadline = now + room.settings.stealTimeLimitSec * 1000
    return {
      ok: true,
      room,
      game: {
        ...game,
        currentRound: nextRound,
        phaseStartedAt: now,
        phaseDeadlineAt: stealDeadline,
        timerGeneration: game.timerGeneration + 1
      }
    }
  }

  const result = buildRoundResult("no_points", undefined, room.settings)
  const resolvedRound: Round = {
    ...round,
    guesses,
    stealAttemptsCount: attempts,
    phase: "resolved",
    result,
    stealLockedPlayerId: null
  }
  const gameNext: GameState = {
    ...game,
    currentRound: resolvedRound,
    roundHistory: [...game.roundHistory, resolvedRound],
    phaseDeadlineAt: null,
    phaseStartedAt: null,
    timerGeneration: game.timerGeneration + 1
  }
  return {
    ok: true,
    room: { ...room, status: "round_result" },
    game: gameNext
  }
}

export function expireStealPhase(room: RoomState, game: GameState, now: number): TransitionResult {
  const ar = assertRound(game)
  if (!ar.ok) return ar
  const { round } = ar
  const ph = assertPhase(round, ["steal_open", "steal_locked"])
  if (!ph.ok) return ph

  const result = buildRoundResult("no_points", undefined, room.settings)
  const resolvedRound: Round = {
    ...round,
    phase: "resolved",
    result,
    stealLockedPlayerId: null
  }
  const gameNext: GameState = {
    ...game,
    currentRound: resolvedRound,
    roundHistory: [...game.roundHistory, resolvedRound],
    phaseDeadlineAt: null,
    phaseStartedAt: null,
    timerGeneration: game.timerGeneration + 1
  }
  return {
    ok: true,
    room: { ...room, status: "round_result" },
    game: gameNext
  }
}

export function advanceToNextTurn(room: RoomState, game: GameState, now: number): TransitionResult {
  if (room.status !== "round_result") return fail("not_round_result")
  const order = game.turnOrder
  if (!order.length) return fail("empty_turn_order")
  const nextIndex = (game.activePlayerIndex + 1) % order.length
  const gameBase: GameState = {
    ...game,
    activePlayerIndex: nextIndex,
    currentRound: null,
    timerGeneration: game.timerGeneration + 1,
    phaseDeadlineAt: null,
    phaseStartedAt: null
  }
  return startTurn({ ...room, status: "in_round" }, gameBase, now)
}

export function finishGame(room: RoomState, game: GameState): TransitionResult {
  return {
    ok: true,
    room: { ...room, status: "finished" as RoomSessionStatus },
    game: {
      ...game,
      currentRound: null,
      phaseDeadlineAt: null,
      phaseStartedAt: null,
      timerGeneration: game.timerGeneration + 1
    }
  }
}

export function addPlayer(room: RoomState, player: RoomState["players"][0]): { ok: true; room: RoomState } | GuardFail {
  return addPlayerToRoomState(room, player)
}
