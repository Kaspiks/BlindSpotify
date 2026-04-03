import { useGameStore } from "../../../stores/gameStore"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { getSessionPlayerId } from "../../../stores/sessionContext"
import { SongPlaybackPanel } from "./SongPlaybackPanel"

export function CurrentRoundPanel() {
  const round = useGameStore((s) => s.currentRound)
  const selfId = getSessionPlayerId()

  if (!round) return null

  return (
    <div className="space-y-4">
      <div className="text-sm text-slate-400">
        Round {round.number} · {round.phase.replace(/_/g, " ")}
      </div>
      {round.card && round.phase !== "waiting_for_scan" ? <SongPlaybackPanel /> : null}
      {round.phase === "scanned" && round.activePlayerId === selfId ? (
        <button
          type="button"
          className="w-full rounded-xl bg-purple-600 py-3 font-semibold text-white hover:bg-purple-500"
          onClick={() => liveRoomActions.beginPlayback()}
        >
          Start guess timer
        </button>
      ) : null}
    </div>
  )
}
