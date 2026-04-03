let selfPlayerId: string | null = null

export function setSessionPlayerId(id: string | null): void {
  selfPlayerId = id
}

export function getSessionPlayerId(): string | null {
  return selfPlayerId
}
