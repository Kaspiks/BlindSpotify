import type { CardPayload, Player } from "../../domain/types"

/** Rails `Rooms::SessionStateBuilder` JSON shape (subset). */
export type RailsRoomSnapshot = {
  v?: number
  phase?: string
  room?: {
    code?: string
    host_player_id?: string | null
    player?: string | null
  }
  players?: Record<
    string,
    {
      name?: string
      score?: number
      connected?: boolean
      /** "host" when this participant is the room owner */
      role?: string
    }
  >
  round?: {
    status?: string
    track_id?: number | null
    revealed?: boolean
    card?: {
      track_id?: number
      title?: string | null
      artist_name?: string | null
      release_year?: number | null
      preview_url?: string | null
      album_cover_url?: string | null
    } | null
  } | null
  last_event?: {
    id?: number
    at?: number
    type?: string
    by?: string | null
  }
}

export function mapRailsPlayersToClient(players: RailsRoomSnapshot["players"], _hostUserIdHint: string): Player[] {
  if (!players) return []
  return Object.entries(players).map(([key, p]) => {
    const id = key
    const name = p?.name ?? "Player"
    const isHost = p?.role === "host"
    return {
      id,
      displayName: name,
      isHost: Boolean(isHost),
      isConnected: p?.connected ?? true,
      presence: "remote" as const,
      score: typeof p?.score === "number" ? p.score : 0
    }
  })
}

export function cardFromRailsRound(round: NonNullable<RailsRoomSnapshot["round"]>): CardPayload | null {
  const c = round.card
  if (!c?.track_id) return null
  return {
    cardId: `track:${c.track_id}`,
    songId: String(c.track_id),
    title: c.title ?? undefined,
    artist: c.artist_name ?? undefined,
    deezerPreviewUrl: c.preview_url ?? undefined,
    artworkUrl: c.album_cover_url ?? undefined,
    metadataVisibility: round.revealed ? "full" : "title_hidden"
  }
}
