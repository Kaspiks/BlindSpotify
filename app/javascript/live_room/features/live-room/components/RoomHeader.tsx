import { ConnectionStatusBadge } from "./ConnectionStatusBadge"

type Props = {
  code: string
  shareUrl: string
  backUrl: string
}

export function RoomHeader({ code, shareUrl, backUrl }: Props) {
  return (
    <header className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <a
        href={backUrl}
        className="inline-flex items-center gap-2 text-slate-400 transition-colors hover:text-white"
      >
        ← Back
      </a>
      <div className="flex flex-wrap items-center gap-2">
        <span className="rounded-lg bg-slate-700 px-3 py-1.5 font-mono text-lg font-bold text-white">
          {code}
        </span>
        <ConnectionStatusBadge />
        <button
          type="button"
          className="rounded-lg bg-slate-700 px-3 py-1.5 text-sm text-slate-300 transition-colors hover:bg-slate-600"
          onClick={() => void navigator.clipboard.writeText(shareUrl)}
        >
          Copy link
        </button>
      </div>
    </header>
  )
}
