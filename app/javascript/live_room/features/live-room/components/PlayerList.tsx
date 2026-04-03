import { useRoomPlayers } from "../../../hooks/useRoomPlayers"

export function PlayerList() {
  const players = useRoomPlayers()
  return (
    <div className="rounded-2xl bg-slate-800 p-5">
      <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">Players</h3>
      <ul className="space-y-2">
        {players.map((p) => (
          <li
            key={p.id}
            className="flex items-center justify-between rounded-lg bg-slate-700/50 px-3 py-2 text-sm"
          >
            <span className="text-white">
              {p.displayName}
              {p.isHost ? (
                <span className="ml-2 text-xs text-purple-300">Host</span>
              ) : null}
            </span>
            <span className="font-mono text-amber-200">{p.score}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
