import { useMemo } from "react"
import { useRoomPlayers } from "../../../hooks/useRoomPlayers"

export function Scoreboard() {
  const players = useRoomPlayers()
  const sorted = useMemo(
    () => [...players].sort((a, b) => b.score - a.score || a.displayName.localeCompare(b.displayName)),
    [players]
  )
  return (
    <div className="rounded-2xl bg-slate-800 p-5">
      <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">Scoreboard</h3>
      <ol className="space-y-2">
        {sorted.map((p, i) => (
          <li
            key={p.id}
            className="flex items-center justify-between rounded-lg bg-slate-700/40 px-3 py-2 text-sm"
          >
            <span className="text-slate-300">
              <span className="mr-2 font-mono text-slate-500">{i + 1}.</span>
              {p.displayName}
            </span>
            <span className="font-mono text-amber-200">{p.score}</span>
          </li>
        ))}
      </ol>
    </div>
  )
}
