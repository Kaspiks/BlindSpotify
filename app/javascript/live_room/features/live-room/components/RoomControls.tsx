import { liveRoomActions } from "../../../stores/liveRoomActions"

type Props = {
  isHost: boolean
  csrfToken: string
  revealUrl: string
  nextUrl: string
  hasTrackOnServer: boolean
}

export function RoomControls({ isHost, csrfToken, revealUrl, nextUrl, hasTrackOnServer }: Props) {
  if (!isHost) return null

  return (
    <div className="mb-4 flex flex-wrap gap-3">
      <button
        type="button"
        disabled={!hasTrackOnServer}
        className="rounded-xl bg-slate-700 px-4 py-3 font-medium text-white transition-colors hover:bg-slate-600 disabled:opacity-40"
        onClick={() => void liveRoomActions.hostReveal(csrfToken, revealUrl)}
      >
        Reveal (server)
      </button>
      <button
        type="button"
        className="rounded-xl bg-purple-600 px-4 py-3 font-medium text-white transition-colors hover:bg-purple-500"
        onClick={() => void liveRoomActions.hostNext(csrfToken, nextUrl)}
      >
        Next track (server)
      </button>
    </div>
  )
}
