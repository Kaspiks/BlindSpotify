import { useActiveTurn } from "../../../hooks/useActiveTurn"
import { getSessionPlayerId } from "../../../stores/sessionContext"

export function TurnBanner() {
  const { activePlayer, round } = useActiveTurn()
  const self = getSessionPlayerId()
  if (!round || !activePlayer) {
    return (
      <div className="mb-4 rounded-xl bg-slate-800 px-4 py-3 text-center text-slate-300">
        Waiting to start…
      </div>
    )
  }
  const yours = self === activePlayer.id
  return (
    <div
      className={`mb-4 rounded-xl px-4 py-3 text-center text-lg font-semibold ${
        yours ? "bg-purple-900/40 text-purple-100" : "bg-slate-800 text-slate-200"
      }`}
    >
      {yours ? "Your turn" : `${activePlayer.displayName}'s turn`}
      <span className="mt-1 block text-xs font-normal uppercase tracking-wide text-slate-400">
        {round.phase.replace(/_/g, " ")}
      </span>
    </div>
  )
}
