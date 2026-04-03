import type { GameEvent } from "../../domain/events"

export type RoomTransport = {
  sendRoomEvent: (event: { type: string; payload?: Record<string, unknown> }) => void
  subscribe: (roomCode: string, onMessage: (msg: unknown) => void) => () => void
  disconnect: () => void
}

export type CableMessage = { state?: Record<string, unknown> }

export function noopTransport(): RoomTransport {
  return {
    sendRoomEvent: () => {},
    subscribe: () => () => {},
    disconnect: () => {}
  }
}

/** Maps high-level client events to Rails RoomSessionChannel `receive` shape. */
export function gameEventToCablePayload(event: GameEvent): { type: string; payload: Record<string, unknown> } | null {
  switch (event.type) {
    case "CARD_SCANNED": {
      const cid = event.payload.card.cardId
      const token = cid.startsWith("token:") ? cid.slice("token:".length) : undefined
      return {
        type: "scan_card",
        payload: {
          track_token: token,
          track_id: event.payload.card.songId,
          by: event.payload.byPlayerId
        }
      }
    }
    default:
      return null
  }
}
