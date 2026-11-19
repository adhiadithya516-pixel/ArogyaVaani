process.env.GEMINI_API_KEY = process.env.GEMINI_API_KEY || "test-gemini-key";

jest.mock("../src/services/firebaseAdmin", () => ({
  adminAuth: {
    verifyIdToken: jest.fn(),
  },
  adminDb: {
    collection: jest.fn(),
  },
}));

const request = require("supertest");
const app = require("../src/app");

describe("Health Check Route", () => {
  test("GET /api/health returns 200 ok", async () => {
    const response = await request(app).get("/api/health");
    expect(response.status).toBe(200);
    expect(response.body.status).toBe("ok");
  });
});
