import { createConsumer, type Consumer } from "@rails/actioncable"
import type { RoomTransport } from "./transport"

export function createActionCableRoomTransport(cableUrl: string): RoomTransport {
  const consumer: Consumer = createConsumer(cableUrl)
  let subscription: ReturnType<Consumer["subscriptions"]["create"]> | null = null

  return {
    sendRoomEvent: (event) => {
      subscription?.send(event)
    },
    subscribe: (roomCode, onMessage) => {
      subscription?.unsubscribe()
      subscription = consumer.subscriptions.create(
        { channel: "RoomSessionChannel", code: roomCode },
        {
          received: (data: unknown) => onMessage(data)
        }
      )
      return () => {
        subscription?.unsubscribe()
        subscription = null
      }
    },
    disconnect: () => {
      subscription?.unsubscribe()
      subscription = null
      consumer.disconnect()
    }
  }
}
