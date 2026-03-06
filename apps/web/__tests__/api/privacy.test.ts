import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/auth", () => ({
  requireStudent: vi.fn(),
  apiError: (err: unknown) => {
    if (err && typeof err === "object" && "status" in err && "message" in err) {
      return Response.json({ error: (err as unknown as { message: string }).message }, {
        status: (err as { status: number }).status,
      });
    }
    return Response.json({ error: "Internal server error" }, { status: 500 });
  },
}));

vi.mock("@compass/db", () => ({
  prisma: {
    studentPrivacySettings: {
      findUnique: vi.fn(),
      upsert: vi.fn(),
    },
  },
}));

const { requireStudent } = await import("@/lib/auth");
const { prisma } = await import("@compass/db");
const { GET, PUT } = await import("@/app/api/privacy/route");
const { withShareSignals } = await import("@/lib/privacy-utils");

const mockRequireStudent = vi.mocked(requireStudent);
const mockFindUnique = vi.mocked(prisma.studentPrivacySettings.findUnique);
const mockUpsert = vi.mocked(prisma.studentPrivacySettings.upsert);

const STUDENT = { id: "student-1" };
const BASE_SETTINGS = {
  studentId: "student-1",
  shareInterestClusters: true,
  shareBreadthScore: true,
  shareTrajectoryShifts: true,
  shareCharacterSignals: true,
  shareSummary: true,
  updatedAt: new Date(),
};

beforeEach(() => {
  vi.clearAllMocks();
  mockRequireStudent.mockResolvedValue(STUDENT as never);
});

describe("withShareSignals", () => {
  it("returns shareSignals=true when all 4 fields are true", () => {
    const result = withShareSignals(BASE_SETTINGS);
    expect(result.shareSignals).toBe(true);
  });

  it("returns shareSignals=false when any field is false", () => {
    expect(withShareSignals({ ...BASE_SETTINGS, shareBreadthScore: false }).shareSignals).toBe(false);
    expect(withShareSignals({ ...BASE_SETTINGS, shareInterestClusters: false }).shareSignals).toBe(false);
    expect(withShareSignals({ ...BASE_SETTINGS, shareTrajectoryShifts: false }).shareSignals).toBe(false);
    expect(withShareSignals({ ...BASE_SETTINGS, shareCharacterSignals: false }).shareSignals).toBe(false);
  });

  it("returns shareSignals=false when all 4 fields are false", () => {
    expect(withShareSignals({
      ...BASE_SETTINGS,
      shareInterestClusters: false,
      shareBreadthScore: false,
      shareTrajectoryShifts: false,
      shareCharacterSignals: false,
    }).shareSignals).toBe(false);
  });
});

describe("GET /api/privacy", () => {
  it("returns settings with derived shareSignals=true", async () => {
    mockFindUnique.mockResolvedValue(BASE_SETTINGS as never);
    const res = await GET();
    const json = await res.json();
    expect(res.status).toBe(200);
    expect(json.shareSignals).toBe(true);
    expect(json.shareSummary).toBe(true);
  });

  it("returns shareSignals=false when breadthScore is hidden", async () => {
    mockFindUnique.mockResolvedValue({ ...BASE_SETTINGS, shareBreadthScore: false } as never);
    const res = await GET();
    const json = await res.json();
    expect(json.shareSignals).toBe(false);
  });

  it("returns default settings when no record exists", async () => {
    mockFindUnique.mockResolvedValue(null as never);
    const res = await GET();
    const json = await res.json();
    expect(json.shareSignals).toBe(true);
    expect(json.shareSummary).toBe(true);
  });
});

describe("PUT /api/privacy — shareSignals fan-out", () => {
  it("fans shareSignals=false out to all 4 DB fields", async () => {
    mockUpsert.mockResolvedValue({ ...BASE_SETTINGS, shareInterestClusters: false, shareBreadthScore: false, shareTrajectoryShifts: false, shareCharacterSignals: false } as never);

    const req = new Request("http://localhost/api/privacy", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ shareSignals: false }),
    });

    await PUT(req);

    expect(mockUpsert).toHaveBeenCalledWith(expect.objectContaining({
      update: expect.objectContaining({
        shareInterestClusters: false,
        shareBreadthScore: false,
        shareTrajectoryShifts: false,
        shareCharacterSignals: false,
      }),
    }));
  });

  it("fans shareSignals=true out to all 4 DB fields", async () => {
    mockUpsert.mockResolvedValue(BASE_SETTINGS as never);

    const req = new Request("http://localhost/api/privacy", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ shareSignals: true }),
    });

    await PUT(req);

    expect(mockUpsert).toHaveBeenCalledWith(expect.objectContaining({
      update: expect.objectContaining({
        shareInterestClusters: true,
        shareBreadthScore: true,
        shareTrajectoryShifts: true,
        shareCharacterSignals: true,
      }),
    }));
  });

  it("updates shareSummary independently", async () => {
    mockUpsert.mockResolvedValue({ ...BASE_SETTINGS, shareSummary: false } as never);

    const req = new Request("http://localhost/api/privacy", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ shareSummary: false }),
    });

    await PUT(req);

    expect(mockUpsert).toHaveBeenCalledWith(expect.objectContaining({
      update: expect.objectContaining({ shareSummary: false }),
    }));
    // Should NOT have changed the signal fields
    const callArg = mockUpsert.mock.calls[0]![0] as { update: Record<string, unknown> };
    expect(callArg.update.shareInterestClusters).toBeUndefined();
  });

  it("returns 400 for invalid payload", async () => {
    const req = new Request("http://localhost/api/privacy", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ shareSignals: "yes please" }), // wrong type
    });

    const res = await PUT(req);
    expect(res.status).not.toBe(200);
  });
});
