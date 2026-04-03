import { useState } from "react"
import { useGuessPermissions } from "../../../hooks/useGuessPermissions"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { getSessionPlayerId } from "../../../stores/sessionContext"
import { useRemainingMs } from "./timerContext"

export function GuessPanel() {
  const { canGuess } = useGuessPermissions()
  const remainingMs = useRemainingMs()
  const [text, setText] = useState("")
  const [yearText, setYearText] = useState("")
  const selfId = getSessionPlayerId()

  if (!canGuess || !selfId) {
    return (
      <div className="rounded-xl bg-slate-800/80 p-4 text-center text-slate-400">
        Waiting for the active player to guess…
      </div>
    )
  }

  const submit = () => {
    if (!text.trim()) return
    if (liveRoomActions.submitMainGuess(selfId, text, yearText)) {
      setText("")
      setYearText("")
    }
  }

  return (
    <div className="rounded-xl bg-slate-800 p-4">
      {remainingMs != null ? (
        <p className="mb-2 text-center text-sm text-amber-200">
          {Math.ceil(remainingMs / 1000)}s left
        </p>
      ) : null}

      <label className="sr-only" htmlFor="main-guess">
        Your guess
      </label>

      <input
        id="main-guess"
        className="mb-3 w-full rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-white placeholder:text-slate-500"
        placeholder="Title or artist…"
        value={text}
        onChange={(e) => setText(e.target.value)}
      />

      <label className="sr-only" htmlFor="year-guess">
        Release year (optional)
      </label>

      <input
        id="year-guess"
        className="mb-3 w-full rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-white placeholder:text-slate-500"
        placeholder="Year (optional)…"
        value={yearText}
        inputMode="numeric"
        onChange={(e) => setYearText(e.target.value.replace(/\D/g, "").slice(0, 4))}
      />

      <button
        type="button"
        className="w-full rounded-xl bg-emerald-600 py-3 font-semibold text-white hover:bg-emerald-500 disabled:opacity-40"
        disabled={!text.trim()}
        onClick={submit}
      >
        Submit guess
      </button>
    </div>
  )
}
