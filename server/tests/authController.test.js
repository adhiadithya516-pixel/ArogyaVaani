const express = require("express");
const request = require("supertest");

jest.mock("../src/services/firebaseAdmin", () => ({
  adminAuth: {
    createUser: jest.fn(),
    deleteUser: jest.fn(),
  },
  adminDb: {
    collection: jest.fn(),
  },
}));

const { adminAuth, adminDb } = require("../src/services/firebaseAdmin");

const {
  register,
  getProfile,
  updateProfile,
} = require("../src/controllers/authController");

const app = express();
app.use(express.json());

app.post("/register", register);

app.get("/profile", (req, res, next) => {
  req.user = { uid: "test-user-123" };
  next();
}, getProfile);

app.put("/profile", (req, res, next) => {
  req.user = { uid: "test-user-123" };
  next();
}, updateProfile);

describe("Authentication Controller", () => {
  let mockUserRef;

  beforeEach(() => {
    jest.clearAllMocks();

    mockUserRef = {
      set: jest.fn(),
      get: jest.fn(),
      update: jest.fn(),
    };

    adminDb.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockUserRef),
    });
  });

  test("should reject registration with missing fields", async () => {
    const response = await request(app)
      .post("/register")
      .send({ name: "Test User" });

    expect(response.status).toBe(400);
  });

  test("should register a new user successfully", async () => {
    adminAuth.createUser.mockResolvedValue({
      uid: "test-user-123",
    });

    mockUserRef.set.mockResolvedValue();

    const response = await request(app)
      .post("/register")
      .send({
        name: "Test User",
        email: "test@example.com",
        password: "TestPassword123",
      });

    expect(response.status).toBe(201);
    expect(mockUserRef.set).toHaveBeenCalled();
  });

  test("should reject an already registered email", async () => {
    adminAuth.createUser.mockRejectedValue({
      code: "auth/email-already-exists",
    });

    const response = await request(app)
      .post("/register")
      .send({
        name: "Test User",
        email: "test@example.com",
        password: "TestPassword123",
      });

    expect(response.status).toBe(409);
  });

  test("should retrieve an existing user profile", async () => {
    mockUserRef.get.mockResolvedValue({
      exists: true,
      data: () => ({
        uid: "test-user-123",
        name: "Test User",
      }),
    });

    const response = await request(app).get("/profile");

    expect(response.status).toBe(200);
  });

  test("should return 404 when profile does not exist", async () => {
    mockUserRef.get.mockResolvedValue({
      exists: false,
    });

    const response = await request(app).get("/profile");

    expect(response.status).toBe(404);
  });

  test("should reject an update without fields", async () => {
    const response = await request(app)
      .put("/profile")
      .send({});

    expect(response.status).toBe(400);
  });

  test("should update the user's name successfully", async () => {
    mockUserRef.get
      .mockResolvedValueOnce({ exists: true })
      .mockResolvedValueOnce({
        exists: true,
        data: () => ({
          uid: "test-user-123",
          name: "Updated User",
        }),
      });

    mockUserRef.update.mockResolvedValue();

    const response = await request(app)
      .put("/profile")
      .send({ name: "Updated User" });

    expect(response.status).toBe(200);
  });
});