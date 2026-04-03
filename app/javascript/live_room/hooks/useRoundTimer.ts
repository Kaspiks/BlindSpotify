import { useEffect, useRef, useState } from "react"
import { useGameStore } from "../stores/gameStore"
import { useRoomStore } from "../stores/roomStore"
import { liveRoomActions } from "../stores/liveRoomActions"

/**
 * Derives remaining ms from deadline; triggers phase expiry once (idempotent via phase + generation).
 */
export function useRoundTimer() {
  const deadline = useGameStore((s) => s.phaseDeadlineAt)
  const generation = useGameStore((s) => s.timerGeneration)
  const roundPhase = useGameStore((s) => s.currentRound?.phase)
  const [remainingMs, setRemainingMs] = useState<number | null>(null)
  const fired = useRef<string>("")

  useEffect(() => {
    const key = `${generation}:${deadline}:${roundPhase}`
    if (deadline == null || !roundPhase) {
      setRemainingMs(null)
      return
    }
    const tick = () => {
      const now = Date.now()
      const rem = Math.max(0, deadline - now)
      setRemainingMs(rem)
      if (rem <= 0 && fired.current !== key) {
        fired.current = key
        const room = useRoomStore.getState()
        const game = useGameStore.getState()
        const phase = game.currentRound?.phase
        if (phase === "main_guess_open") liveRoomActions.expireMainGuess()
        else if (phase === "steal_open" || phase === "steal_locked") liveRoomActions.expireStealPhase()
      }
    }
    tick()
    const id = window.setInterval(tick, 250)
    return () => window.clearInterval(id)
  }, [deadline, generation, roundPhase])

  return { remainingMs, deadline }
}
