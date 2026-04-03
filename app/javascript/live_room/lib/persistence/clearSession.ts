const ROOM_KEY = "live_room_room_v1"
const GAME_KEY = "live_room_game_v1"

export function clearLiveRoomPersistence(): void {
  try {
    localStorage.removeItem(ROOM_KEY)
    localStorage.removeItem(GAME_KEY)
  } catch {
    /* private mode */
  }
}
