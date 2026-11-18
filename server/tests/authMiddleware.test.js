const express = require("express");
const request = require("supertest");

jest.mock("../src/services/firebaseAdmin", () => ({
  adminAuth: {
    verifyIdToken: jest.fn(),
  },
  adminDb: {},
}));

const { adminAuth } = require("../src/services/firebaseAdmin");
const requireAuth = require("../src/middleware/authMiddleware");

const app = express();

app.get("/protected", requireAuth, (req, res) => {
  res.json({
    success: true,
    user: req.user,
  });
});

describe("Authentication Middleware", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("should reject requests without a token", async () => {
    const response = await request(app).get("/protected");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_TOKEN_MISSING");
  });

  test("should reject an empty Bearer token", async () => {
    const response = await request(app)
      .get("/protected")
      .set("Authorization", "Bearer ");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_TOKEN_EMPTY");
  });

  test("should reject an invalid token", async () => {
    adminAuth.verifyIdToken.mockRejectedValue({
      code: "auth/invalid-id-token",
    });

    const response = await request(app)
      .get("/protected")
      .set("Authorization", "Bearer invalid-token");

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("AUTH_TOKEN_INVALID");
  });

  test("should allow a valid token", async () => {
    adminAuth.verifyIdToken.mockResolvedValue({
      uid: "test-user-123",
      email: "test@example.com",
      email_verified: true,
    });

    const response = await request(app)
      .get("/protected")
      .set("Authorization", "Bearer valid-token");

    expect(response.status).toBe(200);
    expect(response.body.user.uid).toBe("test-user-123");
    expect(response.body.user.emailVerified).toBe(true);
  });
});