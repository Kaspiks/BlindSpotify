import { createContext, useContext, type ReactNode } from "react"
import { useRoundTimer } from "../../../hooks/useRoundTimer"

const RemainingMsContext = createContext<number | null>(null)

export function LiveRoomTimerProvider({ children }: { children: ReactNode }) {
  const { remainingMs } = useRoundTimer()
  return <RemainingMsContext.Provider value={remainingMs}>{children}</RemainingMsContext.Provider>
}

export function useRemainingMs(): number | null {
  return useContext(RemainingMsContext)
}
