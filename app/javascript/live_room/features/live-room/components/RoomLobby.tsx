import { useState } from "react"
import type { Player, RoomMode } from "../../../domain/types"
import { genId } from "../../../lib/game/initialState"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { useRoomStore } from "../../../stores/roomStore"

type Props = {
  isHost: boolean
  hasPlaylist: boolean
  playlistName: string
  playlistTrackCount: number
  shareUrl: string
  mode: RoomMode
}

export function RoomLobby({
  isHost,
  hasPlaylist,
  playlistName,
  playlistTrackCount,
  shareUrl,
  mode
}: Props) {
  const status = useRoomStore((s) => s.status)
  const players = useRoomStore((s) => s.players)
  const [name, setName] = useState("")

  if (status !== "lobby" && status !== "countdown") return null

  const addGuest = () => {
    const n = name.trim() || "Player"
    const p: Player = {
      id: genId("p"),
      displayName: n,
      isHost: false,
      isConnected: true,
      presence: mode === "offline" ? "local" : "remote",
      score: 0
    }
    if (liveRoomActions.addPlayer(p)) setName("")
  }

  return (
    <div className="space-y-6">
      {/* Playlist info */}
      {hasPlaylist ? (
        <div className="flex items-center gap-4 rounded-2xl bg-slate-800 p-5">
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-purple-900/50">
            <svg className="h-6 w-6 text-purple-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 18V5l12-2v13" />
              <circle cx="6" cy="18" r="3" />
              <circle cx="18" cy="16" r="3" />
            </svg>
          </div>
          <div className="flex-1">
            <p className="text-sm text-slate-500">Playing from</p>
            <p className="font-medium text-white">{playlistName}</p>
          </div>
          <span className="rounded-full bg-slate-700 px-3 py-1 text-xs text-slate-300">
            {playlistTrackCount} tracks
          </span>
        </div>
      ) : mode === "online" ? (
        <div className="rounded-2xl border border-amber-800/50 bg-amber-950/30 p-5">
          <p className="text-sm text-amber-200">
            No playlist selected. Create a new room with a playlist to enable auto-play, or use QR cards.
          </p>
        </div>
      ) : null}

      {/* Players */}
      <div className="rounded-2xl bg-slate-800 p-6">
        <h2 className="mb-4 text-xl font-bold text-white">Players</h2>
        <ul className="mb-4 space-y-2">
          {players.map((p) => (
            <li
              key={p.id}
              className="flex items-center justify-between rounded-lg bg-slate-700/50 px-4 py-3"
            >
              <span className="text-white">
                {p.displayName}
                {p.isHost ? (
                  <span className="ml-2 rounded bg-purple-600/30 px-2 py-0.5 text-xs text-purple-300">
                    Host
                  </span>
                ) : null}
              </span>
              {!p.isHost && isHost ? (
                <button
                  type="button"
                  className="text-xs text-slate-500 hover:text-red-400"
                  onClick={() => liveRoomActions.removePlayer(p.id)}
                >
                  Remove
                </button>
              ) : null}
            </li>
          ))}
        </ul>

        {/* Local-only seating; online guests join via link (server participants) */}
        {mode === "offline" ? (
          <div className="flex gap-2">
            <input
              className="min-w-0 flex-1 rounded-lg border border-slate-600 bg-slate-700 px-3 py-2 text-white placeholder:text-slate-500"
              placeholder="Player name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") addGuest()
              }}
            />
            <button
              type="button"
              className="rounded-xl bg-slate-600 px-4 py-2 font-medium text-white transition-colors hover:bg-slate-500"
              onClick={addGuest}
            >
              Add
            </button>
          </div>
        ) : null}

        {/* Share link for online */}
        {mode !== "offline" ? (
          <div className="mt-4 rounded-lg bg-slate-700/50 p-3">
            <p className="mb-2 text-xs text-slate-400">Share this link for others to join:</p>
            <div className="flex gap-2">
              <input
                className="min-w-0 flex-1 rounded bg-slate-600 px-2 py-1.5 text-xs text-slate-300"
                readOnly
                value={shareUrl}
              />
              <button
                type="button"
                className="rounded bg-slate-600 px-3 py-1.5 text-xs text-slate-300 hover:bg-slate-500"
                onClick={() => void navigator.clipboard.writeText(shareUrl)}
              >
                Copy
              </button>
            </div>
          </div>
        ) : null}
      </div>

      {/* Start game */}
      {isHost ? (
        <button
          type="button"
          className="w-full rounded-xl bg-purple-600 py-4 text-lg font-semibold text-white transition-colors hover:bg-purple-500 disabled:opacity-40"
          disabled={players.length < 1}
          onClick={() => liveRoomActions.startGame()}
        >
          Start game
        </button>
      ) : (
        <div className="rounded-xl bg-slate-800 p-4 text-center text-slate-400">
          Waiting for the host to start the game…
        </div>
      )}
    </div>
  )
}
