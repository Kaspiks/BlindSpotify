import { useEffect } from "react"
import type { RailsRoomSnapshot } from "../../../lib/realtime/mapRailsSnapshot"
import type { LiveRoomBootstrapConfig } from "../../../stores/liveRoomBootstrap"
import {
  fetchInitialState,
  initLiveRoomFromDom,
  setRandomTrackUrl
} from "../../../stores/liveRoomActions"
import { setSessionPlayerId } from "../../../stores/sessionContext"
import { useUiStore } from "../../../stores/uiStore"
import { useGameStore } from "../../../stores/gameStore"
import { useRoomStore } from "../../../stores/roomStore"
import { getSessionPlayerId } from "../../../stores/sessionContext"
import { LiveRoomTimerProvider } from "./timerContext"
import { QrScanDrawer } from "./QrScanDrawer"
import { RoomLobby } from "./RoomLobby"
import { TrackCard } from "./TrackCard"
import { GameFinished } from "./GameFinished"
import { ConnectionStatusBadge } from "./ConnectionStatusBadge"

export type LiveRoomPageProps = {
  bootstrap: LiveRoomBootstrapConfig
  stateUrl: string
  cableUrl: string | null
  csrfToken: string
  shareUrl: string
  backUrl: string
  revealUrl: string
  nextUrl: string
  hasTrackOnServer: boolean
  initialSnapshot: RailsRoomSnapshot | null
  origin: string
  randomTrackUrl: string
  hasPlaylist: boolean
  playlistName: string
  playlistTrackCount: number
}

export function LiveRoomPage({
  bootstrap,
  stateUrl,
  cableUrl,
  csrfToken,
  shareUrl,
  backUrl,
  revealUrl,
  nextUrl,
  hasTrackOnServer,
  initialSnapshot,
  origin,
  randomTrackUrl,
  hasPlaylist,
  playlistName,
  playlistTrackCount
}: LiveRoomPageProps) {
  const status = useRoomStore((s) => s.status)
  const mode = useRoomStore((s) => s.mode)
  const roundNumber = useGameStore((s) => s.currentRoundNumber)
  const maxRounds = useRoomStore((s) => s.settings.maxRounds)
  const toasts = useUiStore((s) => s.toasts)
  const dismissToast = useUiStore((s) => s.dismissToast)
  const openQrDrawer = useUiStore((s) => s.openQrDrawer)
  const activePlayerId = useGameStore((s) => s.currentRound?.activePlayerId)
  const roundPhase = useGameStore((s) => s.currentRound?.phase)
  const selfId = getSessionPlayerId()

  const canScan =
    mode !== "online" &&
    status === "in_round" &&
    roundPhase === "waiting_for_scan" &&
    (bootstrap.isHost || (!!activePlayerId && !!selfId && activePlayerId === selfId))

  useEffect(() => {
    const self =
      bootstrap.selfPlayerId ?? (bootstrap.isHost ? bootstrap.hostId : null)
    setSessionPlayerId(self)
    setRandomTrackUrl(randomTrackUrl || null)
    const cfg: LiveRoomBootstrapConfig = {
      ...bootstrap,
      initialSnapshot: initialSnapshot ?? bootstrap.initialSnapshot ?? null
    }
    const cleanup = initLiveRoomFromDom(cfg, cableUrl)
    if (bootstrap.mode !== "offline") {
      void fetchInitialState(stateUrl)
    }
    return () => {
      cleanup()
      setSessionPlayerId(null)
      setRandomTrackUrl(null)
    }
  }, [
    bootstrap.code,
    bootstrap.mode,
    bootstrap.hostId,
    bootstrap.hostDisplayName,
    bootstrap.isHost,
    bootstrap.roomNumericId,
    bootstrap.selfPlayerId,
    stateUrl,
    cableUrl,
    initialSnapshot,
    randomTrackUrl
  ])

  return (
    <LiveRoomTimerProvider>
      <div className="mx-auto max-w-2xl px-4 py-8">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <a
            href={backUrl}
            className="flex items-center gap-2 text-slate-400 transition-colors hover:text-white"
          >
            <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
            <span>Back</span>
          </a>
          <div className="flex items-center gap-3">
            {status === "in_round" || status === "round_result" ? (
              <span className="text-sm text-slate-400">
                Round {roundNumber}{maxRounds > 0 ? ` / ${maxRounds}` : ""}
              </span>
            ) : null}
            <span className="rounded-lg bg-slate-700 px-3 py-1.5 font-mono text-sm font-bold text-white">
              {bootstrap.code}
            </span>
            <ConnectionStatusBadge />
            <button
              type="button"
              className="rounded-lg bg-slate-700 px-3 py-1.5 text-xs text-slate-300 transition-colors hover:bg-slate-600"
              onClick={() => void navigator.clipboard.writeText(shareUrl)}
            >
              Copy link
            </button>
          </div>
        </div>

        {/* Progress bar */}
        {maxRounds > 0 && (status === "in_round" || status === "round_result") ? (
          <div className="mb-8">
            <div className="h-2 overflow-hidden rounded-full bg-slate-700">
              <div
                className="h-full bg-purple-600 transition-[width] duration-300 ease-out"
                style={{ width: `${Math.min(100, (roundNumber / maxRounds) * 100)}%` }}
              />
            </div>
            <div className="mt-2 flex justify-between text-xs text-slate-500">
              <span>Round {roundNumber}</span>
              <span>{maxRounds - roundNumber} remaining</span>
            </div>
          </div>
        ) : null}

        {/* Main content by status */}
        {status === "lobby" || status === "countdown" ? (
          <RoomLobby
            isHost={bootstrap.isHost}
            hasPlaylist={hasPlaylist}
            playlistName={playlistName}
            playlistTrackCount={playlistTrackCount}
            shareUrl={shareUrl}
            mode={mode}
          />
        ) : status === "finished" ? (
          <GameFinished backUrl={backUrl} />
        ) : (
          <TrackCard isHost={bootstrap.isHost} origin={origin} />
        )}

        {/* Scoreboard - shown during game */}
        {(status === "in_round" || status === "round_result") ? (
          <div className="mt-8 rounded-2xl bg-slate-800 p-5">
            <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">
              Scoreboard
            </h3>
            <ScoreList />
          </div>
        ) : null}
      </div>

      {/* QR scan button (offline/hybrid only) */}
      {canScan ? (
        <button
          type="button"
          className="fixed bottom-6 right-6 z-30 rounded-full bg-purple-600 px-5 py-3 font-semibold text-white shadow-lg hover:bg-purple-500"
          onClick={() => openQrDrawer()}
        >
          Scan QR
        </button>
      ) : null}
      <QrScanDrawer origin={origin} />

      {/* Toasts */}
      {toasts.length > 0 ? (
        <div className="fixed bottom-6 left-6 z-50 space-y-2">
          {toasts.map((t) => (
            <div
              key={t.id}
              className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm shadow-lg ${
                t.tone === "error" ? "bg-red-900/90 text-red-100" : "bg-slate-700/90 text-slate-100"
              }`}
            >
              <span className="flex-1">{t.message}</span>
              <button
                type="button"
                className="text-slate-400 hover:text-white"
                onClick={() => dismissToast(t.id)}
              >
                ✕
              </button>
            </div>
          ))}
        </div>
      ) : null}
    </LiveRoomTimerProvider>
  )
}

function ScoreList() {
  const players = useRoomStore((s) => s.players)
  const sorted = [...players].sort((a, b) => b.score - a.score || a.displayName.localeCompare(b.displayName))

  return (
    <ol className="space-y-2">
      {sorted.map((p, i) => (
        <li
          key={p.id}
          className="flex items-center justify-between rounded-lg bg-slate-700/40 px-3 py-2 text-sm"
        >
          <span className="text-slate-300">
            <span className="mr-2 font-mono text-slate-500">{i + 1}.</span>
            {p.displayName}
            {p.isHost ? <span className="ml-2 text-xs text-purple-300">Host</span> : null}
          </span>
          <span className="font-mono text-amber-200">{p.score}</span>
        </li>
      ))}
    </ol>
  )
}
