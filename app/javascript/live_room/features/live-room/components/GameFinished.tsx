import { useMemo } from "react"
import { useGameStore } from "../../../stores/gameStore"
import { useRoomStore } from "../../../stores/roomStore"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { getSessionPlayerId } from "../../../stores/sessionContext"

export function GameFinished({ backUrl }: { backUrl: string }) {
  const players = useRoomStore((s) => s.players)
  const roundHistory = useGameStore((s) => s.roundHistory)
  const selfId = getSessionPlayerId()

  const sorted = useMemo(
    () => [...players].sort((a, b) => b.score - a.score),
    [players]
  )

  const myRounds = roundHistory.filter((r) => r.activePlayerId === selfId)
  const totalRounds = myRounds.length
  const correctGuesses = myRounds.filter(
    (r) => r.result?.kind === "main_correct"
  ).length
  const stealsWon = roundHistory.filter(
    (r) => r.result?.kind === "steal_correct" && r.result?.winnerPlayerId === selfId
  ).length

  return (
    <div className="overflow-hidden rounded-2xl bg-slate-800 p-8 text-center">
      <div className="mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full bg-purple-600">
        <svg className="h-12 w-12 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6" />
          <path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18" />
          <path d="M4 22h16" />
          <path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" />
          <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" />
          <path d="M18 2H6v7a6 6 0 0 0 12 0V2Z" />
        </svg>
      </div>

      <h2 className="mb-2 text-3xl font-bold text-white">Game Over!</h2>
      <p className="mb-8 text-slate-400">
        {roundHistory.length} round{roundHistory.length !== 1 ? "s" : ""} played
      </p>

      {/* Per-player stats */}
      <div className="mb-8 grid grid-cols-4 gap-3">
        <div className="rounded-xl bg-slate-700 p-4">
          <div className="text-3xl font-bold text-purple-400">{totalRounds}</div>
          <div className="text-sm text-slate-400">Your turns</div>
        </div>
        <div className="rounded-xl bg-slate-700 p-4">
          <div className="text-3xl font-bold text-green-400">{correctGuesses}</div>
          <div className="text-sm text-slate-400">Correct</div>
        </div>
        <div className="rounded-xl bg-slate-700 p-4">
          <div className="text-3xl font-bold text-amber-300">{stealsWon}</div>
          <div className="text-sm text-slate-400">Steals</div>
        </div>
        <div className="rounded-xl bg-slate-700 p-4">
          <div className="text-3xl font-bold text-slate-300">{totalRounds - correctGuesses}</div>
          <div className="text-sm text-slate-400">Missed</div>
        </div>
      </div>

      {/* Final standings */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">
          Final standings
        </h3>
        <ol className="space-y-2">
          {sorted.map((p, i) => (
            <li
              key={p.id}
              className={`flex items-center justify-between rounded-lg px-4 py-3 ${
                i === 0 ? "bg-purple-900/40" : "bg-slate-700/40"
              }`}
            >
              <span className="text-white">
                <span className="mr-2 font-mono text-slate-500">{i + 1}.</span>
                {p.displayName}
                {i === 0 && sorted.length > 1 ? (
                  <span className="ml-2 text-xs text-amber-300">Winner!</span>
                ) : null}
              </span>
              <span className="font-mono text-lg text-amber-200">{p.score}</span>
            </li>
          ))}
        </ol>
      </div>

      {/* Actions */}
      <div className="flex gap-4 justify-center">
        <a
          href={backUrl}
          className="inline-flex items-center gap-2 rounded-xl bg-slate-700 px-6 py-3 font-semibold text-white transition-colors hover:bg-slate-600"
        >
          Back to home
        </a>
        <button
          type="button"
          className="inline-flex items-center gap-2 rounded-xl bg-purple-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-purple-500"
          onClick={() => {
            liveRoomActions.clearAfterGame()
            window.location.reload()
          }}
        >
          Play again
        </button>
      </div>
    </div>
  )
}
