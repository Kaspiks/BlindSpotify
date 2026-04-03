import { useState } from "react"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { useUiStore } from "../../../stores/uiStore"
import { getSessionPlayerId } from "../../../stores/sessionContext"

type Props = {
  origin: string
}

export function QrScanDrawer({ origin }: Props) {
  const open = useUiStore((s) => s.qrDrawerOpen)
  const close = useUiStore((s) => s.closeQrDrawer)
  const [raw, setRaw] = useState("")

  if (!open) return null

  const selfId = getSessionPlayerId()

  return (
    <div className="fixed inset-0 z-40 flex flex-col justify-end bg-black/50">
      <div className="rounded-t-2xl bg-slate-800 p-5 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-white">Scan or paste QR</h3>
          <button
            type="button"
            className="text-slate-400 hover:text-white"
            onClick={close}
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        <p className="mb-2 text-sm text-slate-400">
          Paste a track URL (<code className="text-xs">/q/…</code>) or raw token.
        </p>
        <textarea
          className="mb-3 min-h-[88px] w-full rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-sm text-white"
          placeholder="https://…/q/abcd1234"
          value={raw}
          onChange={(e) => setRaw(e.target.value)}
        />
        <button
          type="button"
          className="w-full rounded-xl bg-purple-600 py-3 font-semibold text-white hover:bg-purple-500 disabled:opacity-50"
          disabled={!raw.trim() || !selfId}
          onClick={() => {
            if (selfId) void liveRoomActions.handleQrScan(raw.trim(), selfId, origin)
            setRaw("")
          }}
        >
          Apply
        </button>
      </div>
    </div>
  )
}
