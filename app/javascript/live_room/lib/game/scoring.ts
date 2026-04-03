import type { GuessMatchDetail, Player, RoomSettings, RoundResult } from "../../domain/types"

function pointsForCorrectGuess(
  kind: "main_correct" | "steal_correct",
  settings: RoomSettings,
  matchDetail: GuessMatchDetail | undefined
): number {
  const title = matchDetail?.titleMatched ?? false
  const artist = matchDetail?.artistMatched ?? false
  if (kind === "main_correct") {
    if (title && artist) return settings.pointsMainGuessBoth
    if (title) return settings.pointsMainGuessTitleOnly
    if (artist) return settings.pointsMainGuessArtistOnly
    return settings.pointsMainGuessBoth
  }
  if (title && artist) return settings.pointsStealBoth
  if (title) return settings.pointsStealTitleOnly
  if (artist) return settings.pointsStealArtistOnly
  return settings.pointsStealBoth
}

function withYearBonus(
  base: number,
  settings: RoomSettings,
  matchDetail: GuessMatchDetail | undefined
): number {
  if (matchDetail?.yearMatched) return base + settings.pointsYearGuessBonus
  return base
}

export function applyScoresToPlayers(
  players: Player[],
  deltas: Record<string, number>
): Player[] {
  return players.map((p) => {
    const d = deltas[p.id]
    if (!d) return p
    return { ...p, score: p.score + d }
  })
}

export function buildRoundResult(
  kind: RoundResult["kind"],
  winnerPlayerId: string | undefined,
  settings: RoomSettings,
  matchDetail?: GuessMatchDetail
): RoundResult {
  const pointsAwarded: Record<string, number> = {}
  if (winnerPlayerId) {
    if (kind === "main_correct") {
      const base = pointsForCorrectGuess("main_correct", settings, matchDetail)
      pointsAwarded[winnerPlayerId] = withYearBonus(base, settings, matchDetail)
    }
    if (kind === "steal_correct") {
      const base = pointsForCorrectGuess("steal_correct", settings, matchDetail)
      pointsAwarded[winnerPlayerId] = withYearBonus(base, settings, matchDetail)
    }
  }
  return { kind, winnerPlayerId, pointsAwarded, matchDetail }
}
