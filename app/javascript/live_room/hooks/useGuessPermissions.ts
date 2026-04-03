import { useMemo } from "react"
import { canMainGuess } from "../lib/game/guards"
import { useGameStore } from "../stores/gameStore"
import { useRoomStore } from "../stores/roomStore"
import { getSessionPlayerId } from "../stores/sessionContext"

export function useGuessPermissions() {
  const status = useRoomStore((s) => s.status)
  const currentRound = useGameStore((s) => s.currentRound)
  const selfId = getSessionPlayerId()
  return useMemo(() => {
    if (!selfId) return { canGuess: false, reason: "no_session" as const }
    const ok = canMainGuess(useRoomStore.getState(), useGameStore.getState(), selfId)
    return { canGuess: ok, reason: ok ? ("ok" as const) : ("not_permitted" as const) }
  }, [selfId, status, currentRound])
}
