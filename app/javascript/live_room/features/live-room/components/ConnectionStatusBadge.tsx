import { useLiveRoomShallow } from "../../../hooks/useLiveRoom"
import { useSyncStore } from "../../../stores/syncStore"

export function ConnectionStatusBadge() {
  const { connected, mode } = useLiveRoomShallow()
  const reconcileStatus = useSyncStore((s) => s.reconcileStatus)
  if (mode === "offline") {
    return (
      <span className="rounded-full bg-slate-700 px-2 py-0.5 text-xs text-slate-300">Local</span>
    )
  }
  const label =
    reconcileStatus === "error" ? "Sync error" : connected ? "Live" : "Offline"
  const cls =
    reconcileStatus === "error"
      ? "bg-red-900/50 text-red-200"
      : connected
        ? "bg-emerald-900/40 text-emerald-200"
        : "bg-slate-700 text-slate-300"
  return <span className={`rounded-full px-2 py-0.5 text-xs ${cls}`}>{label}</span>
}
