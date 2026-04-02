// Structured logging for playback / external handoff (filter logcat by "BlindJam:Playback").
const PREFIX = "[BlindJam:Playback]"

export function playbackLog(level, event, detail = {}) {
  const payload = { event, ...detail }
  const text = `${PREFIX} ${event}`
  if (level === "error") console.error(text, payload)
  else if (level === "warn") console.warn(text, payload)
  else console.info(text, payload)
}
