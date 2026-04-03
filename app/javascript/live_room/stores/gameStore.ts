import { create } from "zustand"
import { persist, createJSONStorage } from "zustand/middleware"
import type { GameState } from "../domain/types"

export type GameStoreState = GameState & {
  patchGame: (partial: Partial<GameState>) => void
  replaceGame: (game: GameState) => void
}

const baseGame = (): GameState => ({
  turnOrder: [],
  activePlayerIndex: 0,
  currentRound: null,
  roundHistory: [],
  timerGeneration: 0,
  phaseDeadlineAt: null,
  phaseStartedAt: null,
  currentRoundNumber: 0
})

export const useGameStore = create<GameStoreState>()(
  persist(
    (set) => ({
      ...baseGame(),
      patchGame: (partial) => set((s) => ({ ...s, ...partial })),
      replaceGame: (game) =>
        set((s) => ({
          ...game,
          patchGame: s.patchGame,
          replaceGame: s.replaceGame
        }))
    }),
    {
      name: "live_room_game_v1",
      storage: createJSONStorage(() => localStorage),
      partialize: (s): Partial<GameState> => ({
        turnOrder: s.turnOrder,
        activePlayerIndex: s.activePlayerIndex,
        currentRound: s.currentRound,
        roundHistory: s.roundHistory,
        timerGeneration: s.timerGeneration,
        phaseDeadlineAt: s.phaseDeadlineAt,
        phaseStartedAt: s.phaseStartedAt,
        currentRoundNumber: s.currentRoundNumber
      })
    }
  )
)
