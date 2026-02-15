import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"
import { subscribeToRoomSession } from "channels/room_session_channel"

// Pattern B: subscribes to RoomSessionChannel when on a live room page.
// Receives state pushes and dispatches room_session:state for other components.
export default class extends Controller {
  static values = { code: String }

  connect() {
    if (!this.codeValue) return
    this.subscription = subscribeToRoomSession(consumer, this.codeValue, {
      received: (state) => this.handleState(state)
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  handleState(state) {
    this.dispatch("state", { detail: { state }, prefix: "room_session" })
  }
}
