import type { CardPayload } from "./types"

/** Wire/sync events for transport and reducers (extend as Rails grows). */
export type GameEvent =
  | { type: "ROOM_CREATED"; payload: { roomId: string; hostId: string } }
  | { type: "PLAYER_JOINED"; payload: { playerId: string; name: string } }
  | { type: "PLAYER_LEFT"; payload: { playerId: string } }
  | { type: "TURN_STARTED"; payload: { activePlayerId: string; roundNumber: number } }
  | { type: "CARD_SCANNED"; payload: { card: CardPayload; byPlayerId: string } }
  | { type: "SONG_PLAYBACK_STARTED"; payload: { roundId: string } }
  | { type: "MAIN_GUESS_SUBMITTED"; payload: { playerId: string; text: string; yearGuess?: string } }
  | { type: "MAIN_GUESS_TIMEOUT"; payload: { roundId: string } }
  | { type: "STEAL_OPENED"; payload: { roundId: string } }
  | { type: "STEAL_ATTEMPTED"; payload: { playerId: string; text: string; yearGuess?: string } }
  | { type: "ROUND_RESOLVED"; payload: { roundId: string } }
  | { type: "SCORE_UPDATED"; payload: { scores: Record<string, number> } }
  | { type: "NEXT_TURN_STARTED"; payload: { activePlayerId: string } }
  | { type: "ROOM_SYNCED"; payload: { lastEventId: number } }
