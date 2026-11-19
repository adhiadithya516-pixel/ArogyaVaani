const fs = require("fs");
const path = require("path");
const express = require("express");
const request = require("supertest");

jest.mock("../src/services/firebaseAdmin", () => ({
  adminAuth: {
    verifyIdToken: jest.fn(),
  },
  adminDb: {
    collection: jest.fn(),
  },
}));

jest.mock("../src/services/geminiService", () => ({
  geminiVisionModel: {
    generateContent: jest.fn(),
  },
}));

const { adminDb } = require("../src/services/firebaseAdmin");
const { geminiVisionModel } = require("../src/services/geminiService");
const { uploadSingleImage } = require("../src/middleware/uploadMiddleware");
const {
  uploadAndAnalyzeReport,
  getUserReports,
  getReportById,
  deleteReport,
} = require("../src/controllers/reportController");

const app = express();
app.use(express.json());

const mockAuth = (req, res, next) => {
  req.user = { uid: "elderly-user-001", email: "user@example.com" };
  next();
};

app.post("/api/reports/upload", mockAuth, uploadSingleImage, uploadAndAnalyzeReport);
app.get("/api/reports", mockAuth, getUserReports);
app.get("/api/reports/:id", mockAuth, getReportById);
app.delete("/api/reports/:id", mockAuth, deleteReport);

describe("Member 4 - Medical Reports & OCR Controller", () => {
  let mockDocRef;

  beforeEach(() => {
    jest.clearAllMocks();

    mockDocRef = {
      id: "report-abc-123",
      set: jest.fn().mockResolvedValue(),
      get: jest.fn(),
      delete: jest.fn().mockResolvedValue(),
    };

    adminDb.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockDocRef),
      where: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          docs: [
            {
              data: () => ({
                id: "report-abc-123",
                uid: "elderly-user-001",
                reportTitle: "Complete Blood Count",
                createdAt: "2026-11-19T12:00:00.000Z",
              }),
            },
          ],
        }),
      }),
    });
  });

  test("POST /api/reports/upload processes sample.jpg via OCR and returns bilingual summary", async () => {
    geminiVisionModel.generateContent.mockResolvedValue({
      text: JSON.stringify({
        reportTitle: "Blood Sugar Report",
        english: {
          summary: "Your fasting blood sugar is slightly above normal.",
          keyFindings: [
            {
              parameter: "Fasting Glucose",
              value: "118 mg/dL",
              status: "High",
              explanation: "Slightly elevated sugar level before breakfast.",
            },
          ],
          nextSteps: ["Reduce sugary drinks and discuss with your doctor."],
          disclaimer: "Consult your doctor.",
        },
        kannada: {
          summary: "Kannada summary for fasting blood sugar.",
          keyFindings: [
            {
              parameter: "Fasting Glucose",
              value: "118 mg/dL",
              status: "High",
              explanation: "Kannada explanation.",
            },
          ],
          nextSteps: ["Consult your doctor."],
          disclaimer: "Consult your doctor.",
        },
      }),
    });

    const sampleImagePath = path.join(__dirname, "fixtures", "sample.jpg");
    expect(fs.existsSync(sampleImagePath)).toBe(true);

    const response = await request(app)
      .post("/api/reports/upload")
      .attach("image", sampleImagePath);

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.report.storageProvider).toBe("pending-supabase");
    expect(response.body.report.english.summary).toContain("blood sugar");
    expect(mockDocRef.set).toHaveBeenCalledTimes(1);
  }, 30000);

  test("GET /api/reports returns reports for authenticated user", async () => {
    const response = await request(app).get("/api/reports");
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.reports).toHaveLength(1);
  });

  test("GET /api/reports/:id blocks access if report belongs to another user", async () => {
    mockDocRef.get.mockResolvedValue({
      exists: true,
      data: () => ({ id: "report-abc-123", uid: "different-user-999" }),
    });

    const response = await request(app).get("/api/reports/report-abc-123");
    expect(response.status).toBe(403);
  });
});
