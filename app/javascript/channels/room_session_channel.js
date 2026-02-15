// Pattern B: subscribe to RoomSessionChannel by room code; receive state pushes.
export function subscribeToRoomSession(consumer, code, { received } = {}) {
  if (!code) return null
  return consumer.subscriptions.create(
    { channel: "RoomSessionChannel", code },
    {
      received(data) {
        if (data?.state && typeof received === "function") {
          received(data.state)
        }
      }
    }
  )
}
