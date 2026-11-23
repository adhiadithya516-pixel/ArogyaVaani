const {
    uploadFile,
    generateSignedUrl,
} = require("../services/supabaseService");

// Upload a file to Supabase Storage.
const uploadStorageFile = async (req, res) => {
    try {
        const firebaseUid = req.user.uid;
        const file = req.file;
        const { folder } = req.body;

        const result = await uploadFile(firebaseUid, file, folder);

        return res.status(201).json({
            success: true,
            message: "File uploaded successfully.",
            data: result,
        });
    } catch (error) {
        console.error("Storage upload error:", error.message);

        return res.status(400).json({
            success: false,
            error: {
                code: "FILE_UPLOAD_FAILED",
                message: error.message || "Unable to upload file.",
            },
        });
    }
};

// Generate a temporary download URL.
const getStorageDownloadUrl = async (req, res) => {
    try {
        const firebaseUid = req.user.uid;
        const { path } = req.query;

        if (!path) {
            return res.status(400).json({
                success: false,
                error: {
                    code: "FILE_PATH_REQUIRED",
                    message: "File path is required.",
                },
            });
        }

        const signedUrl = await generateSignedUrl(firebaseUid, path);

        return res.status(200).json({
            success: true,
            message: "Download URL generated successfully.",
            data: {
                signedUrl,
                expiresIn: 60,
            },
        });
    } catch (error) {
        console.error("Storage download error:", error.message);

        const isUnauthorized = error.message === "Unauthorized file access.";

        return res.status(isUnauthorized ? 403 : 400).json({
            success: false,
            error: {
                code: isUnauthorized ? "UNAUTHORIZED_FILE_ACCESS" : "DOWNLOAD_URL_FAILED",
                message: isUnauthorized
                    ? "You are not authorized to access this file."
                    : "Unable to generate download URL.",
            },
        });
    }
};

module.exports = {
    uploadStorageFile,
    getStorageDownloadUrl,
};