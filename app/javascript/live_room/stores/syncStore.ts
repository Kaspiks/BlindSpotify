import { create } from "zustand"

export type SyncStoreState = {
  lastRemoteEventId: number
  lastSnapshotVersion: number
  reconcileStatus: "idle" | "syncing" | "error"
  setLastRemoteEventId: (id: number) => void
  setLastSnapshotVersion: (v: number) => void
  setReconcileStatus: (s: SyncStoreState["reconcileStatus"]) => void
  resetSyncMeta: () => void
}

export const useSyncStore = create<SyncStoreState>((set) => ({
  lastRemoteEventId: 0,
  lastSnapshotVersion: 0,
  reconcileStatus: "idle",
  setLastRemoteEventId: (lastRemoteEventId) => set({ lastRemoteEventId }),
  setLastSnapshotVersion: (lastSnapshotVersion) => set({ lastSnapshotVersion }),
  setReconcileStatus: (reconcileStatus) => set({ reconcileStatus }),
  resetSyncMeta: () =>
    set({ lastRemoteEventId: 0, lastSnapshotVersion: 0, reconcileStatus: "idle" })
}))
