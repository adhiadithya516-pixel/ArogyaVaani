const express = require("express");

const router = express.Router();

const requireAuth = require("../middleware/authMiddleware");
const { uploadSingleFile } = require("../middleware/storageUploadMiddleware");

const {
    uploadStorageFile,
    getStorageDownloadUrl,
} = require("../controllers/storageController");

// Upload a file (Firebase authentication required).
router.post(
    "/upload",
    requireAuth,
    uploadSingleFile,
    uploadStorageFile
);

// Generate a temporary download URL.
router.get(
    "/download",
    requireAuth,
    getStorageDownloadUrl
);

module.exports = router;