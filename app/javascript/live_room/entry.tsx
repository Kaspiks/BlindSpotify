import { createRoot } from "react-dom/client"
import type { LiveRoomBootstrapConfig } from "./stores/liveRoomBootstrap"
import { LiveRoomPage } from "./features/live-room/components/LiveRoomPage"

function mount() {
  const el = document.getElementById("live-room-root")
  if (!el) return

  const code = el.dataset.roomCode ?? ""
  const roomNumericId = el.dataset.roomId ?? ""
  const hostId = el.dataset.hostId ?? "host_local"
  const hostDisplayName = el.dataset.hostDisplayName ?? "Host"
  const isHost = el.dataset.isHost === "true"
  const selfPlayerId = el.dataset.playerId?.trim() || null
  const mode = (el.dataset.roomMode as LiveRoomBootstrapConfig["mode"]) || "online"
  const stateUrl = el.dataset.stateUrl ?? ""
  const metaCable = document.querySelector('meta[name="action-cable-url"]')?.getAttribute("content")
  const cableUrl = metaCable?.trim() || el.dataset.cableUrl?.trim() || null
  const csrfToken = el.dataset.csrfToken ?? ""
  const shareUrl = el.dataset.shareUrl ?? ""
  const backUrl = el.dataset.backUrl ?? "/"
  const revealUrl = el.dataset.revealUrl ?? ""
  const nextUrl = el.dataset.nextUrl ?? ""
  const hasTrackOnServer = el.dataset.hasTrack === "true"
  const origin = el.dataset.origin ?? window.location.origin
  const randomTrackUrl = el.dataset.randomTrackUrl || ""
  const hasPlaylist = el.dataset.hasPlaylist === "true"
  const playlistName = el.dataset.playlistName || ""
  const playlistTrackCount = parseInt(el.dataset.playlistTrackCount || "0", 10)

  const bootstrap: LiveRoomBootstrapConfig = {
    roomNumericId,
    code,
    mode,
    hostId,
    hostDisplayName,
    selfPlayerId,
    isHost,
    initialSnapshot: null
  }

  const root = createRoot(el)
  root.render(
    <LiveRoomPage
      bootstrap={bootstrap}
      stateUrl={stateUrl}
      cableUrl={cableUrl}
      csrfToken={csrfToken}
      shareUrl={shareUrl}
      backUrl={backUrl}
      revealUrl={revealUrl}
      nextUrl={nextUrl}
      hasTrackOnServer={hasTrackOnServer}
      initialSnapshot={null}
      origin={origin}
      randomTrackUrl={randomTrackUrl}
      hasPlaylist={hasPlaylist}
      playlistName={playlistName}
      playlistTrackCount={playlistTrackCount}
    />
  )
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", mount)
} else {
  mount()
}
