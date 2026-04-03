import { useRoomStore } from "../stores/roomStore"

export function useRoomPlayers() {
  return useRoomStore((s) => s.players)
}
