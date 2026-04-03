import { create } from "zustand"
import { persist, createJSONStorage } from "zustand/middleware"
import type { RoomMode, RoomSessionStatus, RoomState, RoomSettings, Player } from "../domain/types"
import { defaultRoomSettings } from "../domain/types"

export type RoomStoreState = RoomState & {
  patchRoom: (partial: Partial<RoomState>) => void
  replaceRoom: (room: RoomState) => void
}

const baseRoom = (): RoomState => ({
  id: "",
  code: "",
  mode: "online",
  status: "lobby",
  hostId: "",
  players: [],
  settings: defaultRoomSettings(),
  createdBy: "",
  connected: true,
  connectionLabel: undefined
})

export const useRoomStore = create<RoomStoreState>()(
  persist(
    (set, _get) => ({
      ...baseRoom(),
      patchRoom: (partial) => set((s) => ({ ...s, ...partial })),
      replaceRoom: (room) =>
        set((s) => ({
          ...s,
          ...room,
          connected: room.connected ?? true,
          connectionLabel: room.connectionLabel
        }))
    }),
    {
      name: "live_room_room_v1",
      storage: createJSONStorage(() => localStorage),
      partialize: (s): Partial<RoomState> => ({
        id: s.id,
        code: s.code,
        mode: s.mode,
        status: s.status,
        hostId: s.hostId,
        players: s.players,
        settings: s.settings,
        createdBy: s.createdBy
      }),
      merge: (persisted, current) => {
        const p = persisted as Partial<RoomState>
        return {
          ...current,
          ...p,
          settings: { ...defaultRoomSettings(), ...p.settings } as RoomSettings,
          players: (p.players ?? current.players) as Player[],
          connected: true,
          connectionLabel: undefined
        }
      }
    }
  )
)
