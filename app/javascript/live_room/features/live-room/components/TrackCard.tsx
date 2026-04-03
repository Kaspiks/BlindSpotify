import { useCallback, useEffect, useRef, useState } from "react"
import { useGameStore } from "../../../stores/gameStore"
import { useRoomStore } from "../../../stores/roomStore"
import { liveRoomActions } from "../../../stores/liveRoomActions"
import { getSessionPlayerId } from "../../../stores/sessionContext"
import { useGuessPermissions } from "../../../hooks/useGuessPermissions"
import { useStealPermissions } from "../../../hooks/useStealPermissions"
import { useRemainingMs } from "./timerContext"

export function TrackCard({ isHost, origin }: { isHost: boolean; origin: string }) {
  const round = useGameStore((s) => s.currentRound)
  const status = useRoomStore((s) => s.status)
  const players = useRoomStore((s) => s.players)
  const selfId = getSessionPlayerId()

  if (!round) return null

  const phase = round.phase
  const card = round.card
  const isMyTurn = !!selfId && selfId === round.activePlayerId
  const isRevealed = round.phase === "resolved" || status === "round_result"
  const activePlayer = players.find((p) => p.id === round.activePlayerId)

  return (
    <div className="overflow-hidden rounded-2xl bg-slate-800">
      {/* Artwork area */}
      <div className="relative aspect-video bg-slate-800">
        {isRevealed && card?.artworkUrl ? (
          <img
            src={card.artworkUrl}
            alt=""
            className="h-full w-full object-cover"
            onError={(e) => (e.currentTarget.style.display = "none")}
          />
        ) : (
          <div className="flex h-full w-full flex-col items-center justify-center gap-4">
            {phase === "loading_track" ? (
              <div className="flex flex-col items-center gap-3">
                <div className="h-16 w-16 animate-spin rounded-full border-4 border-slate-600 border-t-purple-500" />
                <span className="text-sm text-slate-400">Loading track…</span>
              </div>
            ) : (
              <div className="flex h-24 w-24 items-center justify-center rounded-full bg-slate-600/50">
                <svg className="h-12 w-12 text-slate-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 18V5l12-2v13" />
                  <circle cx="6" cy="18" r="3" />
                  <circle cx="18" cy="16" r="3" />
                </svg>
              </div>
            )}
          </div>
        )}
        <div className="pointer-events-none absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-slate-800/90 to-transparent" />

        {/* Turn indicator overlay */}
        {!isRevealed && phase !== "loading_track" ? (
          <div className="absolute left-4 top-4">
            <span
              className={`rounded-full px-3 py-1 text-xs font-medium ${
                isMyTurn ? "bg-purple-600 text-white" : "bg-slate-700/80 text-slate-300"
              }`}
            >
              {isMyTurn ? "Your turn" : `${activePlayer?.displayName ?? "?"}'s turn`}
            </span>
          </div>
        ) : null}
      </div>

      {/* Content */}
      <div className="p-6">
        {/* Track info */}
        {phase === "loading_track" ? null : isRevealed ? (
          <div className="mb-6 text-center">
            <h2 className="mb-2 text-2xl font-bold text-white">{card?.title ?? "Unknown Title"}</h2>
            <p className="text-lg text-slate-300">{card?.artist ?? "Unknown Artist"}</p>
            {card?.albumName ? <p className="mt-1 text-sm text-slate-500">{card.albumName}</p> : null}
            {card?.year ? <p className="mt-2 text-sm text-purple-400">{card.year}</p> : null}
          </div>
        ) : card ? (
          <div className="mb-4 text-center">
            <h2 className="text-2xl font-bold text-slate-400">?? Mystery Song ??</h2>
            <p className="text-slate-500">Listen and guess the title or artist</p>
          </div>
        ) : null}

        {/* Audio player */}
        {card?.deezerPreviewUrl && phase !== "loading_track" ? (
          <InlineAudioPlayer url={card.deezerPreviewUrl} />
        ) : null}

        {/* Phase-dependent controls */}
        <PhaseControls
          phase={phase}
          status={status}
          isMyTurn={isMyTurn}
          isHost={isHost}
          selfId={selfId}
          activePlayer={activePlayer}
          round={round}
          isRevealed={isRevealed}
        />
      </div>
    </div>
  )
}

function InlineAudioPlayer({ url }: { url: string }) {
  const audioRef = useRef<HTMLAudioElement>(null)
  const [playing, setPlaying] = useState(false)
  const [progress, setProgress] = useState(0)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)

  useEffect(() => {
    const el = audioRef.current
    if (!el) return

    el.removeAttribute("crossorigin")
    el.src = url
    el.load()
    void el.play().catch(() => { /* autoplay blocked */ })

    const onPlay = () => setPlaying(true)
    const onPause = () => setPlaying(false)
    const onEnded = () => {
      setPlaying(false)
      setProgress(0)
      setCurrentTime(0)
    }
    const onTime = () => {
      const d = el.duration
      if (d && isFinite(d)) {
        setProgress((el.currentTime / d) * 100)
        setCurrentTime(el.currentTime)
      }
    }
    const onMeta = () => {
      if (el.duration && isFinite(el.duration)) setDuration(el.duration)
    }

    el.addEventListener("play", onPlay)
    el.addEventListener("pause", onPause)
    el.addEventListener("ended", onEnded)
    el.addEventListener("timeupdate", onTime)
    el.addEventListener("loadedmetadata", onMeta)
    el.addEventListener("canplay", onMeta)

    return () => {
      el.pause()
      el.removeAttribute("src")
      el.removeEventListener("play", onPlay)
      el.removeEventListener("pause", onPause)
      el.removeEventListener("ended", onEnded)
      el.removeEventListener("timeupdate", onTime)
      el.removeEventListener("loadedmetadata", onMeta)
      el.removeEventListener("canplay", onMeta)
    }
  }, [url])

  const toggle = useCallback(() => {
    const el = audioRef.current
    if (!el) return
    if (el.paused) void el.play().catch(() => {})
    else el.pause()
  }, [])

  const seek = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const el = audioRef.current
    if (!el || !el.duration || !isFinite(el.duration)) return
    const rect = e.currentTarget.getBoundingClientRect()
    const pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width))
    el.currentTime = pct * el.duration
  }, [])

  const fmt = (s: number) => {
    if (!s || !isFinite(s)) return "0:00"
    const m = Math.floor(s / 60)
    const sec = Math.floor(s % 60)
    return `${m}:${sec.toString().padStart(2, "0")}`
  }

  return (
    <div className="mb-6">
      <audio ref={audioRef} preload="auto" />

      <div className="mb-4 flex justify-center">
        <button
          type="button"
          className="flex h-16 w-16 items-center justify-center rounded-full bg-purple-600 text-white transition-colors hover:bg-purple-500"
          onClick={toggle}
        >
          {playing ? (
            <svg className="h-8 w-8" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16" /><rect x="14" y="4" width="4" height="16" /></svg>
          ) : (
            <svg className="ml-0.5 h-8 w-8" viewBox="0 0 24 24" fill="currentColor"><polygon points="5,3 19,12 5,21" /></svg>
          )}
        </button>
      </div>

      <div className="px-2">
        <div
          className="h-2 cursor-pointer overflow-hidden rounded-full bg-slate-700"
          onClick={seek}
        >
          <div
            className="h-full rounded-full bg-purple-500"
            style={{ width: `${progress}%` }}
          />
        </div>
        <div className="mt-2 flex justify-between text-xs text-slate-500">
          <span>{fmt(currentTime)}</span>
          <span>{fmt(duration)}</span>
        </div>
      </div>
    </div>
  )
}

function PhaseControls({
  phase,
  status,
  isMyTurn,
  isHost,
  selfId,
  activePlayer,
  round,
  isRevealed
}: {
  phase: string
  status: string
  isMyTurn: boolean
  isHost: boolean
  selfId: string | null
  activePlayer: { displayName: string } | undefined
  round: NonNullable<ReturnType<typeof useGameStore.getState>["currentRound"]>
  isRevealed: boolean
}) {
  const { canGuess } = useGuessPermissions()
  const { canClaim, canSubmit } = useStealPermissions()
  const remainingMs = useRemainingMs()
  const [guessText, setGuessText] = useState("")
  const [guessYearText, setGuessYearText] = useState("")
  const [stealText, setStealText] = useState("")
  const [stealYearText, setStealYearText] = useState("")

  useEffect(() => {
    setGuessText("")
    setGuessYearText("")
    setStealText("")
    setStealYearText("")
  }, [round.number])

  if (phase === "loading_track") {
    return null
  }

  if (isRevealed) {
    return <RoundResult round={round} isHost={isHost} />
  }

  if (phase === "waiting_for_scan") {
    return (
      <div className="text-center text-slate-400">
        <p className="mb-2 text-lg font-medium">Waiting for QR scan…</p>
        <p className="text-sm">Scan a card to load the track for this round.</p>
      </div>
    )
  }

  if (phase === "scanned") {
    return (
      <div className="text-center text-slate-400">
        <p>Card scanned! Starting playback…</p>
      </div>
    )
  }

  const timer = remainingMs != null ? (
    <span className={`inline-flex items-center gap-1 text-sm font-medium ${remainingMs < 10000 ? "text-red-400" : "text-amber-200"}`}>
      <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><polyline points="12,6 12,12 16,14" /></svg>
      {Math.ceil(remainingMs / 1000)}s
    </span>
  ) : null

  if (phase === "main_guess_open") {
    if (canGuess && selfId) {
      return (
        <div>
          <div className="mb-3 flex items-center justify-between">
            <span className="text-sm font-medium text-purple-300">Your guess</span>
            {timer}
          </div>
          <input
            className="mb-3 w-full rounded-xl border border-slate-600 bg-slate-700 px-4 py-3 text-white placeholder:text-slate-500 focus:border-purple-500 focus:outline-none"
            placeholder="Type the title or artist…"
            value={guessText}
            onChange={(e) => setGuessText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && guessText.trim()) {
                if (liveRoomActions.submitMainGuess(selfId, guessText, guessYearText)) {
                  setGuessText("")
                  setGuessYearText("")
                }
              }
            }}
            autoFocus
          />
          <label className="mb-1 block text-xs font-medium text-slate-400" htmlFor="main-year-guess">
            Release year (optional)
          </label>
          <input
            id="main-year-guess"
            className="mb-3 w-full rounded-xl border border-slate-600 bg-slate-700 px-4 py-3 text-white placeholder:text-slate-500 focus:border-purple-500 focus:outline-none"
            placeholder="e.g. 1984"
            inputMode="numeric"
            value={guessYearText}
            onChange={(e) => setGuessYearText(e.target.value.replace(/\D/g, "").slice(0, 4))}
          />
          <button
            type="button"
            className="w-full rounded-xl bg-emerald-600 py-4 font-semibold text-white transition-colors hover:bg-emerald-500 disabled:opacity-40"
            disabled={!guessText.trim()}
            onClick={() => {
              if (liveRoomActions.submitMainGuess(selfId, guessText, guessYearText)) {
                setGuessText("")
                setGuessYearText("")
              }
            }}
          >
            Submit guess
          </button>
        </div>
      )
    }

    return (
      <div className="text-center">
        <p className="mb-1 text-slate-300">
          Waiting for <span className="font-semibold text-white">{activePlayer?.displayName ?? "?"}</span> to guess…
        </p>
        {timer ? <div className="mt-2">{timer}</div> : null}
      </div>
    )
  }

  if (phase === "steal_open" || phase === "steal_locked") {
    if (isMyTurn) {
      return (
        <div className="text-center">
          <p className="mb-1 text-amber-200">You missed it! Others can steal.</p>
          {timer ? <div className="mt-2">{timer}</div> : null}
        </div>
      )
    }

    if (canClaim && selfId) {
      return (
        <div>
          <div className="mb-3 flex items-center justify-between">
            <span className="text-sm font-medium text-amber-300">Steal opportunity!</span>
            {timer}
          </div>
          <button
            type="button"
            className="w-full rounded-xl bg-amber-600 py-4 font-semibold text-white transition-colors hover:bg-amber-500"
            onClick={() => liveRoomActions.claimSteal(selfId)}
          >
            Claim steal
          </button>
        </div>
      )
    }

    if (canSubmit && selfId) {
      return (
        <div>
          <div className="mb-3 flex items-center justify-between">
            <span className="text-sm font-medium text-amber-300">Your steal guess</span>
            {timer}
          </div>
          <input
            className="mb-3 w-full rounded-xl border border-slate-600 bg-slate-700 px-4 py-3 text-white placeholder:text-slate-500 focus:border-amber-500 focus:outline-none"
            placeholder="Title or artist…"
            value={stealText}
            onChange={(e) => setStealText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && stealText.trim()) {
                if (liveRoomActions.submitStealGuess(selfId, stealText, stealYearText)) {
                  setStealText("")
                  setStealYearText("")
                }
              }
            }}
            autoFocus
          />
          <label className="mb-1 block text-xs font-medium text-slate-400" htmlFor="steal-year-guess">
            Release year (optional)
          </label>
          <input
            id="steal-year-guess"
            className="mb-3 w-full rounded-xl border border-slate-600 bg-slate-700 px-4 py-3 text-white placeholder:text-slate-500 focus:border-amber-500 focus:outline-none"
            placeholder="e.g. 1984"
            inputMode="numeric"
            value={stealYearText}
            onChange={(e) => setStealYearText(e.target.value.replace(/\D/g, "").slice(0, 4))}
          />
          <button
            type="button"
            className="w-full rounded-xl bg-amber-600 py-4 font-semibold text-white transition-colors hover:bg-amber-500 disabled:opacity-40"
            disabled={!stealText.trim()}
            onClick={() => {
              if (liveRoomActions.submitStealGuess(selfId, stealText, stealYearText)) {
                setStealText("")
                setStealYearText("")
              }
            }}
          >
            Submit steal
          </button>
        </div>
      )
    }

    return (
      <div className="text-center">
        <p className="mb-1 text-slate-400">Steal phase — waiting for someone to claim…</p>
        {timer ? <div className="mt-2">{timer}</div> : null}
      </div>
    )
  }

  return null
}

function RoundResult({
  round,
  isHost
}: {
  round: NonNullable<ReturnType<typeof useGameStore.getState>["currentRound"]>
  isHost: boolean
}) {
  const players = useRoomStore((s) => s.players)
  const yearBonus = useRoomStore((s) => s.settings.pointsYearGuessBonus)
  const result = round.result
  if (!result) return null

  const winner = result.winnerPlayerId ? players.find((p) => p.id === result.winnerPlayerId) : null

  const title =
    result.kind === "main_correct"
      ? "Correct!"
      : result.kind === "steal_correct"
        ? "Stolen!"
        : "No one scored"

  const accent =
    result.kind === "main_correct"
      ? "text-emerald-400"
      : result.kind === "steal_correct"
        ? "text-amber-400"
        : "text-slate-400"

  const matchLabel = result.matchDetail
    ? (() => {
        const d = result.matchDetail
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
    <div>
      <div className="mb-6 text-center">
        <p className={`mb-1 text-xl font-bold ${accent}`}>{title}</p>
        {matchLabel && (
          <p className="mb-1 text-sm text-slate-400">{matchLabel}</p>
        )}
        {winner ? (
          <p className="text-slate-300">
            {winner.displayName} earned{" "}
            <span className="font-semibold text-amber-200">
              +{result.pointsAwarded[winner.id] ?? 0}
            </span>{" "}
            point{(result.pointsAwarded[winner.id] ?? 0) !== 1 ? "s" : ""}
          </p>
        ) : (
          <p className="text-slate-500">No points awarded this round.</p>
        )}
      </div>

      <div className="grid grid-cols-2 gap-3">
        {isHost ? (
          <>
            <button
              type="button"
              className="col-span-2 inline-flex items-center justify-center gap-2 rounded-xl bg-purple-600 py-4 font-semibold text-white transition-colors hover:bg-purple-500"
              onClick={() => liveRoomActions.startTurnFromResult()}
            >
              <span>Next round</span>
              <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
            </button>
            <button
              type="button"
              className="col-span-2 rounded-xl border border-slate-600 py-3 text-sm text-slate-300 transition-colors hover:bg-slate-700"
              onClick={() => liveRoomActions.finishGame()}
            >
              End game
            </button>
          </>
        ) : (
          <p className="col-span-2 text-center text-sm text-slate-500">
            Waiting for host to start next round…
          </p>
        )}
      </div>
    </div>
  )
}
