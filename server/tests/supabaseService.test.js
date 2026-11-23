// Set environment variables before importing the service.
process.env.SUPABASE_URL = "https://example.supabase.co";
process.env.SUPABASE_SECRET_KEY = "test-secret-key";

// Mock Supabase SDK.
const mockUpload = jest.fn();
const mockCreateSignedUrl = jest.fn();
const mockFrom = jest.fn();

jest.mock("@supabase/supabase-js", () => ({
    createClient: jest.fn(() => ({
        storage: {
            from: mockFrom,
        },
    })),
}));

const {
    uploadFile,
    generateSignedUrl,
    STORAGE_BUCKET,
} = require("../src/services/supabaseService");

describe("Supabase Storage Service", () => {

    beforeEach(() => {
        jest.clearAllMocks();

        mockFrom.mockReturnValue({
            upload: mockUpload,
            createSignedUrl: mockCreateSignedUrl,
        });

        mockUpload.mockResolvedValue({
            data: {
                path: "medical-records/test-user-123/test-file-id",
            },
            error: null,
        });

        mockCreateSignedUrl.mockResolvedValue({
            data: {
                signedUrl: "https://example.supabase.co/signed-test-url",
            },
            error: null,
        });
    });


    // ==========================================
    // BUCKET TEST
    // ==========================================

    test("should use the correct private storage bucket", () => {
        expect(STORAGE_BUCKET).toBe("ArogyaVaani-files");
    });


    // ==========================================
    // UPLOAD TESTS
    // ==========================================

    test("should upload a valid PDF successfully", async () => {
        const file = {
            buffer: Buffer.from("%PDF-1.4\nSample PDF"),
            mimetype: "application/pdf",
            size: 20,
        };

        const result = await uploadFile(
            "test-user-123",
            file,
            "medical-records"
        );

        expect(result.fileId).toMatch(
            /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        );

        expect(result.path).toContain(
            "medical-records/test-user-123/"
        );

        expect(result.bucket).toBe("ArogyaVaani-files");

        expect(mockUpload).toHaveBeenCalledTimes(1);
    });


    test("should reject an invalid file signature", async () => {
        const file = {
            buffer: Buffer.from("Not a real PDF"),
            mimetype: "application/pdf",
            size: 14,
        };

        await expect(
            uploadFile(
                "test-user-123",
                file,
                "medical-records"
            )
        ).rejects.toThrow(
            "File content does not match its declared type."
        );

        expect(mockUpload).not.toHaveBeenCalled();
    });


    test("should reject unsupported file types", async () => {
        const file = {
            buffer: Buffer.from("Some text"),
            mimetype: "text/plain",
            size: 9,
        };

        await expect(
            uploadFile(
                "test-user-123",
                file,
                "medical-records"
            )
        ).rejects.toThrow("Unsupported file type.");

        expect(mockUpload).not.toHaveBeenCalled();
    });


    test("should reject invalid storage folders", async () => {
        const file = {
            buffer: Buffer.from("%PDF-1.4\nSample PDF"),
            mimetype: "application/pdf",
            size: 20,
        };

        await expect(
            uploadFile(
                "test-user-123",
                file,
                "unknown-folder"
            )
        ).rejects.toThrow("Invalid storage folder.");

        expect(mockUpload).not.toHaveBeenCalled();
    });


    test("should reject files larger than 5 MB", async () => {
        const file = {
            buffer: Buffer.alloc(5 * 1024 * 1024 + 1),
            mimetype: "application/pdf",
            size: 5 * 1024 * 1024 + 1,
        };

        await expect(
            uploadFile(
                "test-user-123",
                file,
                "medical-records"
            )
        ).rejects.toThrow("Invalid file size.");

        expect(mockUpload).not.toHaveBeenCalled();
    });


    // ==========================================
    // DOWNLOAD TESTS
    // ==========================================

    test("should generate a signed URL for an authorized user", async () => {
        const filePath =
            "medical-records/test-user-123/12345678-1234-4234-8234-123456789abc";

        const result = await generateSignedUrl(
            "test-user-123",
            filePath
        );

        expect(result).toBe(
            "https://example.supabase.co/signed-test-url"
        );

        expect(mockCreateSignedUrl).toHaveBeenCalledWith(
            filePath,
            60
        );
    });


    test("should reject access to another user's file", async () => {
        const filePath =
            "medical-records/another-user/12345678-1234-4234-8234-123456789abc";

        await expect(
            generateSignedUrl(
                "test-user-123",
                filePath
            )
        ).rejects.toThrow("Unauthorized file access.");

        expect(mockCreateSignedUrl).not.toHaveBeenCalled();
    });


    test("should reject invalid file UUIDs", async () => {
        const filePath =
            "medical-records/test-user-123/invalid-file-id";

        await expect(
            generateSignedUrl(
                "test-user-123",
                filePath
            )
        ).rejects.toThrow("Unauthorized file access.");

        expect(mockCreateSignedUrl).not.toHaveBeenCalled();
    });

});