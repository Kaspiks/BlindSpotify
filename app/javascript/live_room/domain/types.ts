import type {
  GuessMethod,
  PlaybackMode,
  PlayerPresence,
  RoomMode,
  RoomSessionStatus,
  RoundPhase,
  ScanMode
} from "./phases"

export interface Player {
  id: string
  displayName: string
  avatarUrl?: string
  isHost: boolean
  isConnected: boolean
  presence: PlayerPresence
  score: number
  stealsRemaining?: number
}

export interface RoomSettings {
  guessTimeLimitSec: number
  stealTimeLimitSec: number
  /** Main guess: points when only the title matches. */
  pointsMainGuessTitleOnly: number
  /** Main guess: points when only the artist matches. */
  pointsMainGuessArtistOnly: number
  /** Main guess: points when both title and artist match. */
  pointsMainGuessBoth: number
  /** Steal: points when only the title matches. */
  pointsStealTitleOnly: number
  /** Steal: points when only the artist matches. */
  pointsStealArtistOnly: number
  /** Steal: points when both title and artist match. */
  pointsStealBoth: number
  /** Extra points when optional release year guess matches the card (main or steal). */
  pointsYearGuessBonus: number
  pointsForTurnParticipation?: number
  allowMultipleSteals: boolean
  /** After a failed steal, reopen steal window until this many total steal attempts or round ends. */
  maxStealAttemptsPerRound: number
  /** 0 = unlimited */
  maxRounds: number
  playbackMode: PlaybackMode
  scanMode: ScanMode
}

export interface CardPayload {
  cardId: string
  songId?: string
  title?: string
  artist?: string
  year?: number | string
  albumName?: string
  /** Relative URL e.g. /q/:token/playback for JSON resolve */
  resolveUrl?: string
  deezerPreviewUrl?: string
  spotifyDeepLink?: string
  artworkUrl?: string
  /** What remote players may see before reveal */
  metadataVisibility?: "hidden_until_reveal" | "title_hidden" | "full"
}

export interface GuessMatchDetail {
  titleMatched: boolean
  artistMatched: boolean
  /** True when player entered a year and it matches the card's release year. */
  yearMatched: boolean
}

export interface Guess {
  id: string
  playerId: string
  text: string
  /** Optional release year the player submitted with this guess. */
  yearGuess?: string
  submittedAt: number
  isCorrect: boolean | null
  matchDetail?: GuessMatchDetail
  method: GuessMethod
}

export type RoundResultKind =
  | "main_correct"
  | "steal_correct"
  | "no_points"
  | "aborted"

export interface RoundResult {
  kind: RoundResultKind
  winnerPlayerId?: string
  pointsAwarded: Record<string, number>
  matchDetail?: GuessMatchDetail
}

export interface Round {
  id: string
  number: number
  activePlayerId: string
  card: CardPayload | null
  phase: RoundPhase
  guesses: Guess[]
  /** Player currently holding exclusive steal slot (after claim). */
  stealLockedPlayerId: string | null
  stealAttemptsCount: number
  mainGuessExpired: boolean
  result: RoundResult | null
  startedAt: number
  /** Dedupe scans per round */
  attachedCardId: string | null
}

export interface GameState {
  turnOrder: string[]
  activePlayerIndex: number
  currentRound: Round | null
  roundHistory: Round[]
  /** Monotonic generation so timer callbacks can detect stale phases */
  timerGeneration: number
  phaseDeadlineAt: number | null
  phaseStartedAt: number | null
  currentRoundNumber: number
}

export interface RoomState {
  id: string
  code: string
  mode: RoomMode
  status: RoomSessionStatus
  hostId: string
  players: Player[]
  settings: RoomSettings
  createdBy: string
  connected: boolean
  connectionLabel?: string
}

export const CLIENT_SCHEMA_VERSION = 1 as const

export const defaultRoomSettings = (): RoomSettings => ({
  guessTimeLimitSec: 45,
  stealTimeLimitSec: 20,
  pointsMainGuessTitleOnly: 2,
  pointsMainGuessArtistOnly: 2,
  pointsMainGuessBoth: 5,
  pointsStealTitleOnly: 1,
  pointsStealArtistOnly: 1,
  pointsStealBoth: 2,
  pointsYearGuessBonus: 5,
  allowMultipleSteals: true,
  maxStealAttemptsPerRound: 8,
  maxRounds: 0,
  playbackMode: "preview",
  scanMode: "qr_physical"
})
