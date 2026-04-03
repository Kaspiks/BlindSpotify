import { useState } from "react"
import { useStealPermissions } from "../../../hooks/useStealPermissions"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { getSessionPlayerId } from "../../../stores/sessionContext"
import { useRemainingMs } from "./timerContext"

export function StealPanel() {
  const { canClaim, canSubmit } = useStealPermissions()
  const remainingMs = useRemainingMs()
  const [text, setText] = useState("")
  const [yearText, setYearText] = useState("")
  const selfId = getSessionPlayerId()

  if (!selfId) return null

  if (canClaim) {
    return (
      <div className="rounded-xl bg-amber-900/30 p-4">
        {remainingMs != null ? (
          <p className="mb-2 text-center text-sm text-amber-200">
            Steal window · {Math.ceil(remainingMs / 1000)}s
          </p>
        ) : null}
        <button
          type="button"
          className="w-full rounded-xl bg-amber-600 py-3 font-semibold text-white hover:bg-amber-500"
          onClick={() => liveRoomActions.claimSteal(selfId)}
        >
          Steal
        </button>
      </div>
    )
  }

  if (canSubmit) {
    return (
      <div className="rounded-xl bg-amber-900/30 p-4">
        {remainingMs != null ? (
          <p className="mb-2 text-center text-sm text-amber-200">
            Your steal · {Math.ceil(remainingMs / 1000)}s
          </p>
        ) : null}
        <input
          className="mb-3 w-full rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-white"
          placeholder="Your steal guess"
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <input
          className="mb-3 w-full rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-white placeholder:text-slate-500"
          placeholder="Year (optional)"
          value={yearText}
          inputMode="numeric"
          onChange={(e) => setYearText(e.target.value.replace(/\D/g, "").slice(0, 4))}
        />
        <button
          type="button"
          className="w-full rounded-xl bg-amber-600 py-3 font-semibold text-white hover:bg-amber-500"
          onClick={() => {
            if (liveRoomActions.submitStealGuess(selfId, text, yearText)) {
              setText("")
              setYearText("")
            }
          }}
        >
          Submit steal
        </button>
      </div>
    )
  }

  return (
    <div className="rounded-xl bg-slate-800/80 p-4 text-center text-slate-500 text-sm">
      Steal not available
    </div>
  )
}
