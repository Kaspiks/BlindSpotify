import { useEffect, useRef } from "react"
import { useGameStore } from "../../../stores/gameStore"

export function SongPlaybackPanel() {
  const card = useGameStore((s) => s.currentRound?.card)
  const audioRef = useRef<HTMLAudioElement>(null)

  useEffect(() => {
    const el = audioRef.current
    if (!el || !card?.deezerPreviewUrl) return
    el.src = card.deezerPreviewUrl
    void el.play().catch(() => {
      /* autoplay policy */
    })
    return () => {
      el.pause()
      el.removeAttribute("src")
    }
  }, [card?.deezerPreviewUrl])

  if (!card) {
    return (
      <div className="rounded-xl bg-slate-800 p-6 text-center text-slate-400">No track loaded</div>
    )
  }

  return (
    <div className="rounded-xl bg-slate-800 p-6">
      {card.artworkUrl ? (
        <img
          src={card.artworkUrl}
          alt=""
          className="mx-auto mb-4 h-40 w-40 rounded-lg object-cover"
        />
      ) : null}
      <p className="text-center text-lg font-medium text-white">
        {card.title ?? "Unknown title"}
      </p>
      <p className="text-center text-slate-400">{card.artist ?? "Unknown artist"}</p>
      <audio ref={audioRef} controls className="mt-4 w-full" />
    </div>
  )
}
