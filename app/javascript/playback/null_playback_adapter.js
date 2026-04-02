import { playbackLog } from "playback/playback_logger"

// When preview is missing and external open is not desired or failed — host continues manually (reveal/skip).
export class NullPlaybackAdapter {
  static notify({ reason, onNotify }) {
    playbackLog("warn", "manual_playback_fallback", { reason })
    if (typeof onNotify === "function") onNotify(reason)
  }
}
