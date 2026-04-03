import { useGameStore } from "../stores/gameStore"
import { useRoomStore } from "../stores/roomStore"

export function useActiveTurn() {
  const round = useGameStore((s) => s.currentRound)
  const turnOrder = useGameStore((s) => s.turnOrder)
  const idx = useGameStore((s) => s.activePlayerIndex)
  const players = useRoomStore((s) => s.players)
  const activeId = round?.activePlayerId ?? (turnOrder.length ? turnOrder[idx % turnOrder.length] : null)
  const activePlayer = activeId ? players.find((p) => p.id === activeId) : null
  return { activePlayerId: activeId, activePlayer, round }
}
