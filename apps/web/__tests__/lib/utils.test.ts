import { describe, it, expect } from "vitest";
import { getISOWeekKey } from "@/lib/utils";

describe("getISOWeekKey", () => {
  it("returns correct ISO week for a typical Monday", () => {
    // Jan 6 2025 is a Monday, ISO week 2
    expect(getISOWeekKey(new Date("2025-01-06"))).toBe("2025-W02");
  });

  it("returns W01 for Jan 1 when it falls in week 1", () => {
    // Jan 1 2024 is a Monday — ISO week 1 of 2024
    expect(getISOWeekKey(new Date("2024-01-01"))).toBe("2024-W01");
  });

  it("handles year-boundary where Jan 1 belongs to previous year's last week", () => {
    // Jan 1 2021 is a Friday — belongs to ISO week 53 of 2020
    expect(getISOWeekKey(new Date("2021-01-01"))).toBe("2020-W53");
  });

  it("handles year-boundary where Dec 31 belongs to next year's week 1", () => {
    // Dec 31 2018 is a Monday — belongs to ISO week 1 of 2019
    expect(getISOWeekKey(new Date("2018-12-31"))).toBe("2019-W01");
  });

  it("pads single-digit week numbers with a leading zero", () => {
    // Jan 8 2024 is a Monday — ISO week 2
    const key = getISOWeekKey(new Date("2024-01-08"));
    expect(key).toMatch(/W\d{2}$/);
  });

  it("returns the same week key for all days in the same ISO week", () => {
    // Week of Jan 6-12, 2025 is ISO week 2
    const days = ["2025-01-06", "2025-01-07", "2025-01-08", "2025-01-09", "2025-01-10", "2025-01-11", "2025-01-12"];
    const keys = days.map((d) => getISOWeekKey(new Date(d)));
    expect(new Set(keys).size).toBe(1);
    expect(keys[0]).toBe("2025-W02");
  });

  it("returns different week keys for days in different weeks", () => {
    expect(getISOWeekKey(new Date("2025-01-05"))).not.toBe(
      getISOWeekKey(new Date("2025-01-06"))
    );
  });
});
