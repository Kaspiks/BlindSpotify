/**
 * Guess-matching utilities: normalisation, artist aliases, and fuzzy matching via fast-fuzzy.
 */
import { fuzzy } from "fast-fuzzy"

export function normalize(s: string): string {
  return s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/['']/g, "")
    .replace(/[^a-z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
}

export const artistAliases: Record<string, string[]> = {
  "pink": ["p!nk"],
  "the weeknd": ["weeknd"],
  "acdc": ["ac/dc", "ac dc"],
  "guns n roses": ["guns and roses", "gnr"],
  "the beatles": ["beatles"],
  "the rolling stones": ["rolling stones"],
  "led zeppelin": ["led zep"],
  "red hot chili peppers": ["rhcp", "red hot chilli peppers"],
  "outkast": ["out kast"],
  "n sync": ["nsync", "*nsync"],
  "ke ha": ["kesha", "ke$ha"],
  "sia": ["sia furler"],
}

const FUZZY_THRESHOLD = 0.75

export function isCloseMatch(input: string, correct: string): boolean {
  if (!input || !correct) return false
  return fuzzy(input, correct) >= FUZZY_THRESHOLD
}

export function checkGuess(input: string, correct: string): boolean {
  const normInput = normalize(input)
  const normCorrect = normalize(correct)
  if (!normInput || !normCorrect) return false

  if (normInput === normCorrect) return true

  const aliases = artistAliases[normCorrect]
  if (aliases?.some((a) => normalize(a) === normInput)) return true

  if (isCloseMatch(normInput, normCorrect)) return true

  if (normInput.includes(normCorrect) || normCorrect.includes(normInput)) return true

  return false
}
