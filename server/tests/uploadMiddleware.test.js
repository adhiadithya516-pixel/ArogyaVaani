const express = require("express");
const request = require("supertest");
const path = require("path");

const { uploadSingleImage } = require("../src/middleware/uploadMiddleware");

const app = express();

app.post("/test-upload", uploadSingleImage, (req, res) => {
    res.status(200).json({
        success: true,
        filename: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
    });
});

describe("Image Upload Middleware", () => {
    const sampleImage = path.join(__dirname, "fixtures", "sample.jpg");

    test("should accept a valid JPEG image", async () => {
        const response = await request(app)
            .post("/test-upload")
            .attach("image", sampleImage);

        expect(response.status).toBe(200);
        expect(response.body.success).toBe(true);
        expect(response.body.mimetype).toBe("image/jpeg");
    });

    test("should reject requests without an image", async () => {
        const response = await request(app)
            .post("/test-upload");

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe("IMAGE_REQUIRED");
    });

    test("should reject unsupported file types", async () => {
        const response = await request(app)
            .post("/test-upload")
            .attach("image", Buffer.from("sample text"), {
                filename: "document.txt",
                contentType: "text/plain",
            });

        expect(response.status).toBe(415);
        expect(response.body.error.code).toBe("UNSUPPORTED_IMAGE_TYPE");
    });

    test("should reject invalid image content", async () => {
        const response = await request(app)
            .post("/test-upload")
            .attach("image", Buffer.from("not-an-image"), {
                filename: "fake.jpg",
                contentType: "image/jpeg",
            });

        expect(response.status).toBe(415);
        expect(response.body.error.code).toBe("INVALID_IMAGE_CONTENT");
    });

    test("should reject images larger than 5 MB", async () => {
        const largeImage = Buffer.alloc(5 * 1024 * 1024 + 1, 0xff);

        const response = await request(app)
            .post("/test-upload")
            .attach("image", largeImage, {
                filename: "large.jpg",
                contentType: "image/jpeg",
            });

        expect(response.status).toBe(413);
        expect(response.body.error.code).toBe("IMAGE_TOO_LARGE");
    });

    test("should reject an unexpected file field", async () => {
        const response = await request(app)
            .post("/test-upload")
            .attach("photo", sampleImage);

        expect(response.status).toBe(400);
        expect(response.body.error.code).toBe("INVALID_FILE_FIELD");
    });
});