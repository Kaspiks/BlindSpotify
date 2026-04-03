import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "node",
    include: ["app/javascript/live_room/**/*.test.ts"]
  }
})
