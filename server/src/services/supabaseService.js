const { createClient } = require("@supabase/supabase-js");
const { randomUUID } = require("crypto");

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;

if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
    throw new Error("Supabase environment variables are missing.");
}

const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_SECRET_KEY
);

const STORAGE_BUCKET = "ArogyaVaani-files";
const MAX_FILE_SIZE = 5 * 1024 * 1024;

const ALLOWED_FOLDERS = [
    "medical-records",
    "medicine-images",
    "medical-reports",
];

const ALLOWED_TYPES = [
    "image/jpeg",
    "image/png",
    "application/pdf",
];

// Validate the uploaded file's actual content.
function hasValidFileSignature(buffer, mimetype) {
    if (!Buffer.isBuffer(buffer) || buffer.length < 8) {
        return false;
    }

    const isJPEG =
        buffer[0] === 0xff &&
        buffer[1] === 0xd8 &&
        buffer[2] === 0xff;

    const isPNG =
        buffer.subarray(0, 8).equals(
            Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
        );

    const isPDF =
        buffer.subarray(0, 5).toString() === "%PDF-";

    return (
        (mimetype === "image/jpeg" && isJPEG) ||
        (mimetype === "image/png" && isPNG) ||
        (mimetype === "application/pdf" && isPDF)
    );
}

// Upload a file for an authenticated user.
async function uploadFile(firebaseUid, file, folder) {
    if (!firebaseUid || !file || !folder) {
        throw new Error("User ID, file and folder are required.");
    }

    if (
        typeof firebaseUid !== "string" ||
        firebaseUid.length > 128 ||
        firebaseUid.includes("/") ||
        firebaseUid.includes("\\")
    ) {
        throw new Error("Invalid user ID.");
    }

    if (!ALLOWED_FOLDERS.includes(folder)) {
        throw new Error("Invalid storage folder.");
    }

    if (!ALLOWED_TYPES.includes(file.mimetype)) {
        throw new Error("Unsupported file type.");
    }

    if (
        !Buffer.isBuffer(file.buffer) ||
        file.buffer.length === 0 ||
        file.buffer.length > MAX_FILE_SIZE ||
        (file.size !== undefined && file.size > MAX_FILE_SIZE)
    ) {
        throw new Error("Invalid file size.");
    }

    if (!hasValidFileSignature(file.buffer, file.mimetype)) {
        throw new Error("File content does not match its declared type.");
    }

    const fileId = randomUUID();
    const filePath = `${folder}/${firebaseUid}/${fileId}`;

    const { data, error } = await supabase.storage
        .from(STORAGE_BUCKET)
        .upload(filePath, file.buffer, {
            contentType: file.mimetype,
            upsert: false,
        });

    if (error) throw error;

    return {
        fileId,
        path: data.path,
        bucket: STORAGE_BUCKET,
    };
}

// Generate a temporary download URL.
async function generateSignedUrl(firebaseUid, filePath) {
    if (!firebaseUid || !filePath) {
        throw new Error("User ID and file path are required.");
    }

    if (typeof filePath !== "string") {
        throw new Error("Invalid file path.");
    }

    const pathParts = filePath.split("/");

    const [folder, ownerUid, fileId] = pathParts;

    const validUUID =
        /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

    if (
        pathParts.length !== 3 ||
        !ALLOWED_FOLDERS.includes(folder) ||
        ownerUid !== firebaseUid ||
        !validUUID.test(fileId)
    ) {
        throw new Error("Unauthorized file access.");
    }

    const { data, error } = await supabase.storage
        .from(STORAGE_BUCKET)
        .createSignedUrl(filePath, 60);

    if (error) throw error;

    return data.signedUrl;
}

module.exports = {
    supabase,
    STORAGE_BUCKET,
    uploadFile,
    generateSignedUrl,
};