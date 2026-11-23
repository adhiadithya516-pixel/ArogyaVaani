const express = require("express");
const request = require("supertest");

// Mock Firebase Admin authentication.
jest.mock("../src/services/firebaseAdmin", () => ({
    adminAuth: {
        verifyIdToken: jest.fn(),
    },
    adminDb: {},
}));

// Mock Supabase Storage service.
jest.mock("../src/services/supabaseService", () => ({
    uploadFile: jest.fn(),
    generateSignedUrl: jest.fn(),
    supabase: {},
    STORAGE_BUCKET: "ArogyaVaani-files",
}));

const { adminAuth } = require("../src/services/firebaseAdmin");

const {
    uploadFile,
    generateSignedUrl,
} = require("../src/services/supabaseService");

const storageRoutes = require("../src/routes/storageRoutes");

const app = express();

app.use(express.json());
app.use("/api/storage", storageRoutes);


describe("Supabase Storage Routes", () => {

    beforeEach(() => {
        jest.clearAllMocks();

        // Mock valid Firebase authentication.
        adminAuth.verifyIdToken.mockResolvedValue({
            uid: "test-user-123",
            email: "test@example.com",
            email_verified: true,
        });

        // Mock successful file upload.
        uploadFile.mockResolvedValue({
            fileId: "12345678-1234-4234-8234-123456789abc",
            path: "medical-records/test-user-123/12345678-1234-4234-8234-123456789abc",
            bucket: "ArogyaVaani-files",
        });

        // Mock signed URL generation with ownership validation.
        generateSignedUrl.mockImplementation((uid, path) => {
            const ownerUid = path.split("/")[1];

            if (ownerUid !== uid) {
                return Promise.reject(
                    new Error("Unauthorized file access.")
                );
            }

            return Promise.resolve(
                "https://example.supabase.co/signed-test-url"
            );
        });
    });


    // ==========================================
    // UPLOAD TESTS
    // ==========================================

    test("should reject upload without authentication", async () => {
        const response = await request(app)
            .post("/api/storage/upload");

        expect(response.status).toBe(401);
        expect(uploadFile).not.toHaveBeenCalled();
    });


    test("should reject an invalid Firebase token", async () => {
        adminAuth.verifyIdToken.mockRejectedValue({
            code: "auth/invalid-id-token",
        });

        const response = await request(app)
            .post("/api/storage/upload")
            .set("Authorization", "Bearer invalid-token");

        expect(response.status).toBe(401);
        expect(uploadFile).not.toHaveBeenCalled();
    });


    test("should upload a valid authenticated PDF", async () => {
        const pdfBuffer = Buffer.from(
            "%PDF-1.4\nSample medical document"
        );

        const response = await request(app)
            .post("/api/storage/upload")
            .set("Authorization", "Bearer valid-token")
            .field("folder", "medical-records")
            .attach("file", pdfBuffer, {
                filename: "medical-record.pdf",
                contentType: "application/pdf",
            });

        expect(response.status).toBe(201);
        expect(response.body.success).toBe(true);

        expect(uploadFile).toHaveBeenCalledTimes(1);

        expect(uploadFile.mock.calls[0][0]).toBe(
            "test-user-123"
        );
    });


    test("should reject an upload without a file", async () => {
        const response = await request(app)
            .post("/api/storage/upload")
            .set("Authorization", "Bearer valid-token")
            .field("folder", "medical-records");

        expect(response.status).toBe(400);

        expect(response.body.error.code).toBe(
            "FILE_REQUIRED"
        );

        expect(uploadFile).not.toHaveBeenCalled();
    });


    test("should reject unsupported file formats", async () => {
        const textBuffer = Buffer.from(
            "This is a text file."
        );

        const response = await request(app)
            .post("/api/storage/upload")
            .set("Authorization", "Bearer valid-token")
            .field("folder", "medical-records")
            .attach("file", textBuffer, {
                filename: "document.txt",
                contentType: "text/plain",
            });

        expect(response.status).toBe(415);

        expect(response.body.error.code).toBe(
            "UNSUPPORTED_FILE_TYPE"
        );

        expect(uploadFile).not.toHaveBeenCalled();
    });


    test("should reject files larger than 5 MB", async () => {
        const largeBuffer = Buffer.alloc(
            5 * 1024 * 1024 + 1,
            "a"
        );

        const response = await request(app)
            .post("/api/storage/upload")
            .set("Authorization", "Bearer valid-token")
            .field("folder", "medical-records")
            .attach("file", largeBuffer, {
                filename: "large-document.pdf",
                contentType: "application/pdf",
            });

        expect(response.status).toBe(413);

        expect(response.body.error.code).toBe(
            "FILE_TOO_LARGE"
        );

        expect(uploadFile).not.toHaveBeenCalled();
    });


    // ==========================================
    // DOWNLOAD TESTS
    // ==========================================

    test("should reject download without authentication", async () => {
        const response = await request(app)
            .get("/api/storage/download")
            .query({
                path: "medical-records/test-user-123/12345678-1234-4234-8234-123456789abc",
            });

        expect(response.status).toBe(401);

        expect(generateSignedUrl).not.toHaveBeenCalled();
    });


    test("should reject download without a file path", async () => {
        const response = await request(app)
            .get("/api/storage/download")
            .set("Authorization", "Bearer valid-token");

        expect(response.status).toBe(400);

        expect(response.body.error.code).toBe(
            "FILE_PATH_REQUIRED"
        );
    });


    test("should generate a signed URL for the authenticated user", async () => {
        const filePath =
            "medical-records/test-user-123/12345678-1234-4234-8234-123456789abc";

        const response = await request(app)
            .get("/api/storage/download")
            .set("Authorization", "Bearer valid-token")
            .query({
                path: filePath,
            });

        expect(response.status).toBe(200);

        expect(response.body.success).toBe(true);

        expect(response.body.data.signedUrl).toBe(
            "https://example.supabase.co/signed-test-url"
        );

        expect(response.body.data.expiresIn).toBe(60);

        expect(generateSignedUrl).toHaveBeenCalledWith(
            "test-user-123",
            filePath
        );
    });


    test("should prevent access to another user's file", async () => {
        const otherUserPath =
            "medical-records/another-user/12345678-1234-4234-8234-123456789abc";

        const response = await request(app)
            .get("/api/storage/download")
            .set("Authorization", "Bearer valid-token")
            .query({
                path: otherUserPath,
            });

        expect(response.status).toBe(403);

        expect(response.body.error.code).toBe(
            "UNAUTHORIZED_FILE_ACCESS"
        );
    });

});