/** Per-round gameplay phase (client-authoritative; server may lag until Phase 2 Rails). */
export type RoundPhase =
  | "waiting_for_scan"
  | "loading_track"
  | "scanned"
  | "playing"
  | "main_guess_open"
  | "main_guess_locked"
  | "steal_open"
  | "steal_locked"
  | "resolved"

/** Room-level UI / session status. */
export type RoomSessionStatus =
  | "lobby"
  | "countdown"
  | "in_round"
  | "round_result"
  | "finished"

export type RoomMode = "offline" | "hybrid" | "online"

export type PlayerPresence = "local" | "remote"

export type GuessMethod = "main_guess" | "steal"

export type PlaybackMode = "preview" | "full_external" | "manual"

export type ScanMode = "qr_physical" | "qr_digital" | "manual_song_select"
