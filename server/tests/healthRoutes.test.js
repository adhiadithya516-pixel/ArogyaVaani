const request = require("supertest");

jest.mock("../src/services/firebaseAdmin", () => ({
  initializeFirebaseAdmin: jest.fn(),
  adminAuth: {},
  adminDb: {},
}));

const app = require("../src/app");

describe("Health API", () => {
  test("GET /api/health should return API health status", async () => {
    const response = await request(app).get("/api/health");

    expect(response.status).toBe(200);
    expect(response.body.status).toBe("ok");
    expect(response.body.message).toBe("ArogyaVani API is healthy");
  });
});