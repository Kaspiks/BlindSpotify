import { describe, expect, it } from "vitest"
import { normalize, isCloseMatch, checkGuess, artistAliases } from "./matching"

describe("normalize", () => {
  it("lowercases and trims", () => {
    expect(normalize("  Hello World  ")).toBe("hello world")
  })

  it("strips diacritics", () => {
    expect(normalize("Beyoncé")).toBe("beyonce")
    expect(normalize("Mötorhëad")).toBe("motorhead")
  })

  it("replaces special chars with spaces", () => {
    expect(normalize("AC/DC")).toBe("ac dc")
    expect(normalize("Guns N' Roses")).toBe("guns n roses")
  })

  it("collapses multiple spaces", () => {
    expect(normalize("a   b    c")).toBe("a b c")
  })

  it("returns empty for empty input", () => {
    expect(normalize("")).toBe("")
    expect(normalize("   ")).toBe("")
  })
})

describe("isCloseMatch", () => {
  it("returns true for identical strings", () => {
    expect(isCloseMatch("queen", "queen")).toBe(true)
  })

  it("returns true for small typos", () => {
    expect(isCloseMatch("bohemain rhapsody", "bohemian rhapsody")).toBe(true)
  })

  it("returns false for completely different strings", () => {
    expect(isCloseMatch("apple", "orange")).toBe(false)
  })

  it("returns false for empty input", () => {
    expect(isCloseMatch("", "test")).toBe(false)
    expect(isCloseMatch("test", "")).toBe(false)
  })
})

describe("checkGuess", () => {
  it("exact match", () => {
    expect(checkGuess("Queen", "Queen")).toBe(true)
  })

  it("case-insensitive exact match", () => {
    expect(checkGuess("QUEEN", "queen")).toBe(true)
  })

  it("diacritic-insensitive match", () => {
    expect(checkGuess("Beyonce", "Beyoncé")).toBe(true)
  })

  it("alias match: p!nk → pink", () => {
    expect(checkGuess("p!nk", "Pink")).toBe(true)
  })

  it("alias match: weeknd → the weeknd", () => {
    expect(checkGuess("weeknd", "The Weeknd")).toBe(true)
  })

  it("alias match: AC/DC", () => {
    expect(checkGuess("AC/DC", "ACDC")).toBe(true)
  })

  it("alias match: RHCP", () => {
    expect(checkGuess("rhcp", "Red Hot Chili Peppers")).toBe(true)
  })

  it("fuzzy match with typo", () => {
    expect(checkGuess("Bohemain Rhapsody", "Bohemian Rhapsody")).toBe(true)
  })

  it("substring match (guess is part of correct)", () => {
    expect(checkGuess("bohemian", "Bohemian Rhapsody")).toBe(true)
  })

  it("substring match (correct is part of guess)", () => {
    expect(checkGuess("the song bohemian rhapsody is great", "Bohemian Rhapsody")).toBe(true)
  })

  it("rejects completely wrong guess", () => {
    expect(checkGuess("xyz totally wrong", "Bohemian Rhapsody")).toBe(false)
  })

  it("rejects empty input", () => {
    expect(checkGuess("", "Queen")).toBe(false)
  })

  it("rejects empty correct", () => {
    expect(checkGuess("Queen", "")).toBe(false)
  })
})

describe("artistAliases", () => {
  it("has entries for common alternate spellings", () => {
    expect(artistAliases["pink"]).toContain("p!nk")
    expect(artistAliases["the weeknd"]).toContain("weeknd")
    expect(artistAliases["acdc"]).toContain("ac/dc")
    expect(artistAliases["red hot chili peppers"]).toContain("rhcp")
    expect(artistAliases["ke ha"]).toContain("ke$ha")
  })
})
