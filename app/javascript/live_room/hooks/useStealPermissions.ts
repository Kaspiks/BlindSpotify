import { useMemo } from "react"
import { canClaimSteal, canSubmitStealGuess } from "../lib/game/guards"
import { useGameStore } from "../stores/gameStore"
import { useRoomStore } from "../stores/roomStore"
import { getSessionPlayerId } from "../stores/sessionContext"

export function useStealPermissions() {
  const status = useRoomStore((s) => s.status)
  const currentRound = useGameStore((s) => s.currentRound)
  const selfId = getSessionPlayerId()
  return useMemo(() => {
    if (!selfId) return { canClaim: false, canSubmit: false }
    const room = useRoomStore.getState()
    const game = useGameStore.getState()
    return {
      canClaim: canClaimSteal(room, game, selfId),
      canSubmit: canSubmitStealGuess(room, game, selfId)
    }
  }, [selfId, status, currentRound])
}
