import { useGameStore } from "../../../stores/gameStore"
import { useRoomStore } from "../../../stores/roomStore"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { useUiStore } from "../../../stores/uiStore"

export function RoundResultModal() {
  const open = useUiStore((s) => s.roundResultModalOpen)
  const setOpen = useUiStore((s) => s.setRoundResultModalOpen)
  const round = useGameStore((s) => s.currentRound)
  if (!open || !round?.result) return null

  const yearBonus = useRoomStore((s) => s.settings.pointsYearGuessBonus)
  const { kind, winnerPlayerId, pointsAwarded, matchDetail } = round.result
  const title =
    kind === "main_correct"
      ? "Correct guess"
      : kind === "steal_correct"
        ? "Steal successful"
        : "Round over"

  const matchLabel = matchDetail
    ? (() => {
        const d = matchDetail
        const base =
          d.titleMatched && d.artistMatched
            ? "Guessed both title and artist"
            : d.titleMatched
              ? "Guessed the title"
              : "Guessed the artist"
        return d.yearMatched ? `${base} · Release year (+${yearBonus})` : base
      })()
    : null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="max-w-md rounded-2xl bg-slate-800 p-6 shadow-xl">
        <h3 className="text-xl font-bold text-white">{title}</h3>
        {matchLabel && (
          <p className="mt-1 text-sm text-slate-400">{matchLabel}</p>
        )}
        <p className="mt-2 text-slate-300">
          {winnerPlayerId ? `Winner: ${winnerPlayerId}` : "No points this round"}
        </p>
        {Object.keys(pointsAwarded).length ? (
          <ul className="mt-3 text-sm text-slate-400">
            {Object.entries(pointsAwarded).map(([pid, pts]) => (
              <li key={pid}>
                {pid}: +{pts}
              </li>
            ))}
          </ul>
        ) : null}
        <div className="mt-6 flex gap-3">
          <button
            type="button"
            className="flex-1 rounded-xl bg-purple-600 py-3 font-semibold text-white hover:bg-purple-500"
            onClick={() => {
              setOpen(false)
              liveRoomActions.startTurnFromResult()
            }}
          >
            Next turn
          </button>
          <button
            type="button"
            className="rounded-xl bg-slate-700 px-4 py-3 text-slate-200 hover:bg-slate-600"
            onClick={() => setOpen(false)}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  )
}
