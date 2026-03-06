import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/auth", () => ({
  requireStudent: vi.fn(),
  apiError: (err: unknown) => {
    if (err && typeof err === "object" && "status" in err) {
      return Response.json({ error: (err as unknown as { message: string }).message }, {
        status: (err as { status: number }).status,
      });
    }
    return Response.json({ error: "Internal server error" }, { status: 500 });
  },
}));

vi.mock("@compass/db", () => ({
  prisma: {
    reflectionSession: {
      findFirst: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
    },
    reflectionTemplate: {
      findFirst: vi.fn(),
    },
  },
}));

vi.mock("@/lib/redis", () => ({
  rateLimiters: {
    sessionCreate: { limit: vi.fn().mockResolvedValue({ success: true }) },
  },
}));

const { requireStudent } = await import("@/lib/auth");
const { prisma } = await import("@compass/db");
const { rateLimiters } = await import("@/lib/redis");
const { POST } = await import("@/app/api/sessions/route");

const mockRequireStudent = vi.mocked(requireStudent);
const mockFindFirst = vi.mocked(prisma.reflectionSession.findFirst);
const mockFindMany = vi.mocked(prisma.reflectionSession.findMany);
const mockCount = vi.mocked(prisma.reflectionSession.count);
const mockCreate = vi.mocked(prisma.reflectionSession.create);
const mockTemplateFindFirst = vi.mocked(prisma.reflectionTemplate.findFirst);
const mockRateLimit = vi.mocked(rateLimiters.sessionCreate.limit);

const STUDENT = { id: "student-1" };
const TEMPLATE = { id: "tmpl-1", title: "Test", orderNum: 1, isActive: true };

beforeEach(() => {
  vi.clearAllMocks();
  mockRequireStudent.mockResolvedValue(STUDENT as never);
  mockRateLimit.mockResolvedValue({ success: true } as never);
});

describe("POST /api/sessions", () => {
  it("returns existing in-progress session if one exists", async () => {
    const existing = { id: "session-1", completedAt: null };
    mockFindFirst.mockResolvedValueOnce(existing as never); // in-progress check

    const res = await POST();
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.id).toBe("session-1");
    expect(mockCreate).not.toHaveBeenCalled();
  });

  it("returns 403 with daysLeft when in cooldown", async () => {
    mockFindFirst.mockResolvedValueOnce(null as never); // no in-progress session

    const completedRecently = new Date();
    completedRecently.setDate(completedRecently.getDate() - 5); // 5 days ago, still in 21-day cooldown
    mockFindFirst.mockResolvedValueOnce({ completedAt: completedRecently } as never);

    const res = await POST();
    const json = await res.json();
    expect(res.status).toBe(403);
    expect(json.error).toBe("cooldown");
    expect(json.daysLeft).toBeGreaterThan(0);
    expect(json.daysLeft).toBeLessThanOrEqual(21);
  });

  it("creates a new session when cooldown has passed", async () => {
    mockFindFirst.mockResolvedValueOnce(null as never); // no in-progress
    const longAgo = new Date();
    longAgo.setDate(longAgo.getDate() - 30); // 30 days ago, past 21-day cooldown
    mockFindFirst.mockResolvedValueOnce({ completedAt: longAgo } as never);
    mockFindMany.mockResolvedValue([] as never); // no started templates
    mockTemplateFindFirst.mockResolvedValue(TEMPLATE as never);
    mockCount.mockResolvedValue(0 as never);
    const newSession = { id: "new-session", templateId: "tmpl-1" };
    mockCreate.mockResolvedValue(newSession as never);

    const res = await POST();
    expect(res.status).toBe(200);
    expect(mockCreate).toHaveBeenCalled();
  });

  it("returns 429 when rate limit exceeded", async () => {
    mockRateLimit.mockResolvedValue({ success: false } as never);

    const res = await POST();
    expect(res.status).toBe(429);
  });

  it("returns 403 all_complete when no templates remain", async () => {
    mockFindFirst.mockResolvedValueOnce(null as never); // no in-progress
    mockFindFirst.mockResolvedValueOnce(null as never); // no recent completed (no cooldown)
    mockFindMany.mockResolvedValue([{ templateId: "tmpl-1" }] as never);
    mockTemplateFindFirst.mockResolvedValue(null as never); // all templates started

    const res = await POST();
    const json = await res.json();
    expect(res.status).toBe(403);
    expect(json.error).toBe("all_complete");
  });
});
