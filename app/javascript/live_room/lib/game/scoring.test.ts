import { describe, expect, it } from "vitest"
import { buildRoundResult, applyScoresToPlayers } from "./scoring"
import { defaultRoomSettings } from "../../domain/types"

describe("buildRoundResult", () => {
  const settings = defaultRoomSettings()

  it("main_correct awards title-only points", () => {
    const r = buildRoundResult("main_correct", "p1", settings, {
      titleMatched: true,
      artistMatched: false,
      yearMatched: false
    })
    expect(r.pointsAwarded.p1).toBe(settings.pointsMainGuessTitleOnly)
  })

  it("main_correct awards artist-only points", () => {
    const r = buildRoundResult("main_correct", "p1", settings, {
      titleMatched: false,
      artistMatched: true,
      yearMatched: false
    })
    expect(r.pointsAwarded.p1).toBe(settings.pointsMainGuessArtistOnly)
  })

  it("main_correct awards both points", () => {
    const r = buildRoundResult("main_correct", "p1", settings, {
      titleMatched: true,
      artistMatched: true,
      yearMatched: false
    })
    expect(r.pointsAwarded.p1).toBe(settings.pointsMainGuessBoth)
  })

  it("steal_correct awards title-only points", () => {
    const r = buildRoundResult("steal_correct", "p2", settings, {
      titleMatched: true,
      artistMatched: false,
      yearMatched: false
    })
    expect(r.pointsAwarded.p2).toBe(settings.pointsStealTitleOnly)
  })

  it("steal_correct awards both points", () => {
    const r = buildRoundResult("steal_correct", "p2", settings, {
      titleMatched: true,
      artistMatched: true,
      yearMatched: false
    })
    expect(r.pointsAwarded.p2).toBe(settings.pointsStealBoth)
  })

  it("no_points awards nothing", () => {
    const r = buildRoundResult("no_points", undefined, settings, {
      titleMatched: true,
      artistMatched: false,
      yearMatched: false
    })
    expect(r.pointsAwarded).toEqual({})
  })

  it("main_correct without matchDetail falls back to both-tier points", () => {
    const r = buildRoundResult("main_correct", "p1", settings, undefined)
    expect(r.pointsAwarded.p1).toBe(settings.pointsMainGuessBoth)
  })

  it("adds year bonus when yearMatched", () => {
    const r = buildRoundResult("main_correct", "p1", settings, {
      titleMatched: true,
      artistMatched: false,
      yearMatched: true
    })
    expect(r.pointsAwarded.p1).toBe(settings.pointsMainGuessTitleOnly + settings.pointsYearGuessBonus)
  })
})

describe("applyScoresToPlayers", () => {
  it("adds awarded points", () => {
    const players = [
      {
        id: "a",
        displayName: "A",
        isHost: true,
        isConnected: true,
        presence: "local" as const,
        score: 5
      }
    ]
    const next = applyScoresToPlayers(players, { a: 2 })
    expect(next[0]!.score).toBe(7)
  })
})
