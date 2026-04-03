import type { CardPayload } from "../../domain/types"
import { genId } from "./initialState"

export type QrPayload =
  | { kind: "track_token"; token: string }
  | { kind: "deck_slot"; deckId: string; position: number }

export function parseQrPayload(raw: string): QrPayload | null {
  const s = raw.trim()
  if (!s) return null
  try {
    if (s.startsWith("http://") || s.startsWith("https://")) {
      const u = new URL(s)
      const path = u.pathname
      const mDeck = path.match(/\/q\/d\/([^/]+)\/(\d+)/)
      if (mDeck) {
        return { kind: "deck_slot", deckId: mDeck[1]!, position: parseInt(mDeck[2]!, 10) }
      }
      const mTok = path.match(/\/q\/([^/]+)$/)
      if (mTok && mTok[1] !== "d") {
        return { kind: "track_token", token: mTok[1]! }
      }
    }
  } catch {
    return null
  }
  if (/^[a-zA-Z0-9_-]{8,}$/.test(s)) {
    return { kind: "track_token", token: s }
  }
  return null
}

/** Build a minimal card payload before playback JSON resolves (online uses server track). */
export function cardPayloadFromQr(qr: QrPayload, origin: string): CardPayload {
  if (qr.kind === "track_token") {
    const path = `/q/${qr.token}`
    return {
      cardId: `token:${qr.token}`,
      resolveUrl: `${origin.replace(/\/$/, "")}${path}/playback`
    }
  }
  return {
    cardId: `deck:${qr.deckId}:${qr.position}`,
    resolveUrl: `${origin.replace(/\/$/, "")}/q/d/${qr.deckId}/${qr.position}/playback`
  }
}

/** After fetching playback JSON from Rails, merge into card. */
export function enrichCardFromPlaybackJson(card: CardPayload, json: Record<string, unknown>): CardPayload {
  const title = typeof json.title === "string" ? json.title : card.title
  const artist =
    typeof json.artist_name === "string"
      ? json.artist_name
      : typeof json.artist === "string"
        ? json.artist
        : card.artist
  const preview =
    typeof json.preview_url === "string"
      ? json.preview_url
      : typeof json.deezer_preview_url === "string"
        ? json.deezer_preview_url
        : card.deezerPreviewUrl
  let year: number | string | undefined = card.year
  if (typeof json.release_year === "number") year = json.release_year
  else if (typeof json.release_year === "string" && json.release_year.trim()) year = json.release_year.trim()
  else if (typeof json.year === "number") year = json.year
  else if (typeof json.year === "string" && json.year.trim()) year = json.year.trim()
  return {
    ...card,
    songId: typeof json.id === "number" ? String(json.id) : card.songId,
    title,
    artist,
    year,
    deezerPreviewUrl: preview,
    artworkUrl: typeof json.album_cover_url === "string" ? json.album_cover_url : card.artworkUrl
  }
}

export function syntheticCardForManual(title: string, artist: string): CardPayload {
  return {
    cardId: genId("manual"),
    title,
    artist,
    metadataVisibility: "full"
  }
}
