import { create } from "zustand"

export interface ToastItem {
  id: string
  message: string
  tone?: "info" | "error"
}

export type UiStoreState = {
  qrDrawerOpen: boolean
  roundResultModalOpen: boolean
  loading: boolean
  toasts: ToastItem[]
  openQrDrawer: () => void
  closeQrDrawer: () => void
  setRoundResultModalOpen: (open: boolean) => void
  setLoading: (v: boolean) => void
  pushToast: (message: string, tone?: ToastItem["tone"]) => void
  dismissToast: (id: string) => void
}

export const useUiStore = create<UiStoreState>((set) => ({
  qrDrawerOpen: false,
  roundResultModalOpen: false,
  loading: false,
  toasts: [],
  openQrDrawer: () => set({ qrDrawerOpen: true }),
  closeQrDrawer: () => set({ qrDrawerOpen: false }),
  setRoundResultModalOpen: (open) => set({ roundResultModalOpen: open }),
  setLoading: (loading) => set({ loading }),
  pushToast: (message, tone = "info") =>
    set((s) => ({
      toasts: [...s.toasts, { id: `t_${Date.now()}`, message, tone }]
    })),
  dismissToast: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }))
}))
