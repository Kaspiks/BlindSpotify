import { describe, expect, it, vi } from "vitest"
import { clearLiveRoomPersistence } from "./clearSession"

describe("clearLiveRoomPersistence", () => {
  it("removes live_room keys", () => {
    const remove = vi.fn()
    vi.stubGlobal("localStorage", { removeItem: remove })
    clearLiveRoomPersistence()
    expect(remove).toHaveBeenCalledWith("live_room_room_v1")
    expect(remove).toHaveBeenCalledWith("live_room_game_v1")
    vi.unstubAllGlobals()
  })
})
