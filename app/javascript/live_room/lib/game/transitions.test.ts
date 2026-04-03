import { describe, expect, it } from "vitest"
import { createInitialRoomState } from "./initialState"
import {
  addPlayerToRoomState,
  advanceToNextTurn,
  attachScannedCardToRound,
  beginPlayback,
  claimSteal,
  evaluateGuess,
  expireMainGuess,
  finishGame,
  startGame,
  startTurn,
  submitMainGuess,
  submitStealGuess
} from "./transitions"

describe("transitions", () => {
  const now = 1_700_000_000_000
  const card = {
    cardId: "track:1",
    title: "Test Song",
    artist: "Test Artist",
    deezerPreviewUrl: "https://example.com/preview.mp3"
  }

  function lobbyWithTwoPlayers() {
    const { room, game } = createInitialRoomState({
      code: "ABC123",
      roomNumericId: "1",
      hostId: "host1",
      hostDisplayName: "Host",
      mode: "offline"
    })
    const guest = {
      id: "p2",
      displayName: "Guest",
      isHost: false,
      isConnected: true,
      presence: "local" as const,
      score: 0
    }
    const r = addPlayerToRoomState(room, guest)
    if (!r.ok) throw new Error(r.reason)
    return { room: r.room, game }
  }

  it("startGame creates a round in waiting_for_scan", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const out = startGame(room, game, now)
    expect(out.ok).toBe(true)
    if (!out.ok) return
    expect(out.room.status).toBe("in_round")
    expect(out.game.currentRound?.phase).toBe("waiting_for_scan")
  })

  it("only active player can submit main guess", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const bad = submitMainGuess(g2.room, g2.game, "p2", "Test Song", now)
    expect(bad.ok).toBe(false)
    const good = submitMainGuess(
      g2.room,
      g2.game,
      g2.game.currentRound!.activePlayerId,
      "Test Song",
      now
    )
    expect(good.ok).toBe(true)
  })

  it("wrong main guess opens steal phase", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(
      g2.room,
      g2.game,
      g2.game.currentRound!.activePlayerId,
      "wrong",
      now
    )
    if (!g3.ok) throw new Error()
    expect(g3.game.currentRound?.phase).toBe("steal_open")
  })

  it("expireMainGuess opens steal", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = expireMainGuess(g2.room, g2.game, now)
    if (!g3.ok) throw new Error()
    expect(g3.game.currentRound?.phase).toBe("steal_open")
  })

  it("successful steal updates score", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(
      g2.room,
      g2.game,
      g2.game.currentRound!.activePlayerId,
      "nope",
      now
    )
    if (!g3.ok) throw new Error()
    const g4 = claimSteal(g3.room, g3.game, "p2", now)
    if (!g4.ok) throw new Error()
    const g5 = submitStealGuess(g4.room, g4.game, "p2", "Test Song", now)
    if (!g5.ok) throw new Error()
    const winner = g5.room.players.find((p) => p.id === "p2")
    expect(winner?.score).toBeGreaterThan(0)
    expect(g5.room.status).toBe("round_result")
  })

  it("advanceToNextTurn rotates active player", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(
      g2.room,
      g2.game,
      g2.game.currentRound!.activePlayerId,
      "Test Song",
      now
    )
    if (!g3.ok) throw new Error()
    const g4 = advanceToNextTurn(g3.room, g3.game, now)
    if (!g4.ok) throw new Error()
    expect(g4.game.currentRound?.activePlayerId).toBe("p2")
  })

  it("finishGame sets finished status", () => {
    const { room, game } = createInitialRoomState({
      code: "X",
      roomNumericId: "1",
      hostId: "h",
      hostDisplayName: "H",
      mode: "offline"
    })
    const out = finishGame(room, game)
    expect(out.ok).toBe(true)
    if (!out.ok) return
    expect(out.room.status).toBe("finished")
  })

  it("online mode startGame creates round with loading_track phase", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const onlineRoom = { ...room, mode: "online" as const }
    const out = startGame(onlineRoom, game, now)
    expect(out.ok).toBe(true)
    if (!out.ok) return
    expect(out.game.currentRound?.phase).toBe("loading_track")
  })

  it("attachScannedCardToRound accepts loading_track phase", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const onlineRoom = { ...room, mode: "online" as const }
    const g0 = startGame(onlineRoom, game, now)
    if (!g0.ok) throw new Error()
    expect(g0.game.currentRound?.phase).toBe("loading_track")
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.room.hostId, now)
    expect(g1.ok).toBe(true)
    if (!g1.ok) return
    expect(g1.game.currentRound?.phase).toBe("scanned")
  })

  it("active player cannot claim steal", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(
      g2.room,
      g2.game,
      g2.game.currentRound!.activePlayerId,
      "nope",
      now
    )
    if (!g3.ok) throw new Error()
    const c = claimSteal(g3.room, g3.game, g3.game.currentRound!.activePlayerId, now)
    expect(c.ok).toBe(false)
  })

  it("correct main guess populates matchDetail on result", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(g2.room, g2.game, g2.game.currentRound!.activePlayerId, "Test Song", now)
    if (!g3.ok) throw new Error()
    const result = g3.game.currentRound?.result
    expect(result?.matchDetail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("correct steal guess populates matchDetail on result", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, card, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const g3 = submitMainGuess(g2.room, g2.game, g2.game.currentRound!.activePlayerId, "nope", now)
    if (!g3.ok) throw new Error()
    const g4 = claimSteal(g3.room, g3.game, "p2", now)
    if (!g4.ok) throw new Error()
    const g5 = submitStealGuess(g4.room, g4.game, "p2", "Test Artist", now)
    if (!g5.ok) throw new Error()
    const result = g5.game.currentRound?.result
    expect(result?.matchDetail).toEqual({ titleMatched: false, artistMatched: true, yearMatched: false })
  })

  it("main guess with correct optional year sets yearMatched and awards bonus", () => {
    const { room, game } = lobbyWithTwoPlayers()
    const cardWithYear = { ...card, year: 1999 }
    const g0 = startGame(room, game, now)
    if (!g0.ok) throw new Error()
    const g1 = attachScannedCardToRound(g0.room, g0.game, cardWithYear, g0.game.currentRound!.activePlayerId, now)
    if (!g1.ok) throw new Error()
    const g2 = beginPlayback(g1.room, g1.game, now)
    if (!g2.ok) throw new Error()
    const pid = g2.game.currentRound!.activePlayerId
    const g3 = submitMainGuess(g2.room, g2.game, pid, "Test Song", now, "1999")
    if (!g3.ok) throw new Error()
    const result = g3.game.currentRound?.result
    expect(result?.matchDetail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: true })
    expect(result?.pointsAwarded[pid]).toBe(
      room.settings.pointsMainGuessTitleOnly + room.settings.pointsYearGuessBonus
    )
  })
})

describe("evaluateGuess", () => {
  it("returns null for empty text", () => {
    expect(evaluateGuess({ cardId: "c1", title: "Song", artist: "Band" }, "")).toBeNull()
    expect(evaluateGuess({ cardId: "c1", title: "Song", artist: "Band" }, "   ")).toBeNull()
  })

  it("returns null when nothing matches", () => {
    expect(evaluateGuess({ cardId: "c1", title: "Song", artist: "Band" }, "completely wrong")).toBeNull()
  })

  it("returns titleMatched when only title matches", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Bohemian Rhapsody", artist: "Queen" }, "bohemian rhapsody")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("returns artistMatched when only artist matches", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Bohemian Rhapsody", artist: "Queen" }, "queen")
    expect(detail).toEqual({ titleMatched: false, artistMatched: true, yearMatched: false })
  })

  it("returns both matched when text matches both title and artist", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Queen", artist: "Queen" }, "queen")
    expect(detail).toEqual({ titleMatched: true, artistMatched: true, yearMatched: false })
  })

  it("matches case-insensitively", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "test SONG", artist: "Test ARTIST" }, "TEST song")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("matches when guess is substring of title", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Bohemian Rhapsody", artist: "Queen" }, "bohemian")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("matches when title is substring of guess", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Song", artist: "Artist" }, "the song is great")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("matches fuzzy typo in title", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Bohemian Rhapsody", artist: "Queen" }, "Bohemain Rhapsody")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("matches artist alias (p!nk → Pink)", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Raise Your Glass", artist: "Pink" }, "p!nk")
    expect(detail).toEqual({ titleMatched: false, artistMatched: true, yearMatched: false })
  })

  it("sets yearMatched when optional year matches card", () => {
    const detail = evaluateGuess(
      { cardId: "c1", title: "Song", artist: "Band", year: 1984 },
      "song",
      "1984"
    )
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: true })
  })

  it("yearMatched false when year guess wrong", () => {
    const detail = evaluateGuess(
      { cardId: "c1", title: "Song", artist: "Band", year: 1984 },
      "song",
      "1999"
    )
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("yearMatched false when card has no year", () => {
    const detail = evaluateGuess({ cardId: "c1", title: "Song", artist: "Band" }, "song", "1984")
    expect(detail).toEqual({ titleMatched: true, artistMatched: false, yearMatched: false })
  })

  it("rejects distant strings", () => {
    expect(evaluateGuess({ cardId: "c1", title: "Bohemian Rhapsody", artist: "Queen" }, "xyz totally off")).toBeNull()
  })
})
