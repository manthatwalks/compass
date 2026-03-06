import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock Clerk before importing auth
vi.mock("@clerk/nextjs/server", () => ({
  auth: vi.fn().mockResolvedValue({ userId: null }),
  clerkClient: vi.fn().mockReturnValue({
    users: { getUser: vi.fn() },
  }),
}));

vi.mock("@compass/db", () => ({
  prisma: {
    student: { findUnique: vi.fn() },
    counselor: { findUnique: vi.fn() },
  },
}));

const { AuthError, apiError } = await import("@/lib/auth");

describe("AuthError", () => {
  it("defaults to status 401", () => {
    const err = new AuthError("Unauthorized");
    expect(err.status).toBe(401);
    expect(err.message).toBe("Unauthorized");
    expect(err.name).toBe("AuthError");
  });

  it("accepts explicit 403 status", () => {
    const err = new AuthError("Forbidden", 403);
    expect(err.status).toBe(403);
  });

  it("is an instance of Error", () => {
    expect(new AuthError("x")).toBeInstanceOf(Error);
  });
});

describe("apiError", () => {
  it("returns 401 JSON for AuthError with status 401", async () => {
    const res = apiError(new AuthError("Unauthorized", 401));
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error).toBe("Unauthorized");
  });

  it("returns 403 JSON for AuthError with status 403", async () => {
    const res = apiError(new AuthError("Forbidden", 403));
    expect(res.status).toBe(403);
    const json = await res.json();
    expect(json.error).toBe("Forbidden");
  });

  it("returns 500 for unknown errors", async () => {
    const res = apiError(new Error("something broke"));
    expect(res.status).toBe(500);
  });

  it("does not leak internal error details on 500", async () => {
    const res = apiError(new Error("SECRET: db password is hunter2"));
    const json = await res.json();
    expect(json.error).toBe("Internal server error");
    expect(JSON.stringify(json)).not.toContain("hunter2");
  });

  it("handles non-Error throws", async () => {
    const res = apiError("string error");
    expect(res.status).toBe(500);
  });
});
