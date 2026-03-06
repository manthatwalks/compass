import { describe, it, expect } from "vitest";
import { COOLDOWN_DAYS } from "@/lib/constants";

describe("COOLDOWN_DAYS", () => {
  it("is 21 days", () => {
    expect(COOLDOWN_DAYS).toBe(21);
  });

  it("is a positive integer", () => {
    expect(Number.isInteger(COOLDOWN_DAYS)).toBe(true);
    expect(COOLDOWN_DAYS).toBeGreaterThan(0);
  });
});
