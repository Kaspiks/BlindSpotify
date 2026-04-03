import { useGameStore } from "../stores/gameStore"
import { useRoomStore } from "../stores/roomStore"
import { useSyncStore } from "../stores/syncStore"

export function useLiveRoom() {
  const code = useRoomStore((s) => s.code)
  const status = useRoomStore((s) => s.status)
  const mode = useRoomStore((s) => s.mode)
  const settings = useRoomStore((s) => s.settings)
  const reconcileStatus = useSyncStore((s) => s.reconcileStatus)
  return { code, status, mode, settings, reconcileStatus }
}

export function useLiveRoomShallow() {
  const code = useRoomStore((s) => s.code)
  const status = useRoomStore((s) => s.status)
  const mode = useRoomStore((s) => s.mode)
  const hostId = useRoomStore((s) => s.hostId)
  const connected = useRoomStore((s) => s.connected)
  return { code, status, mode, hostId, connected }
}
