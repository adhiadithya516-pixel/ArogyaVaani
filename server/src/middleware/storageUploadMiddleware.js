const multer = require("multer");

const MAX_FILE_SIZE = 5 * 1024 * 1024;

const ALLOWED_TYPES = [
    "image/jpeg",
    "image/png",
    "application/pdf",
];

const storage = multer.memoryStorage();

const fileFilter = (req, file, callback) => {
    if (!ALLOWED_TYPES.includes(file.mimetype)) {
        const error = new Error("Only PDF, JPEG and PNG files are allowed.");
        error.code = "UNSUPPORTED_FILE_TYPE";
        return callback(error);
    }

    callback(null, true);
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: MAX_FILE_SIZE,
        files: 1,
    },
});

function hasValidFileSignature(buffer, mimetype) {
    if (!buffer || buffer.length < 8) {
        return false;
    }

    const isJPEG =
        buffer[0] === 0xff &&
        buffer[1] === 0xd8 &&
        buffer[2] === 0xff;

    const isPNG =
        buffer[0] === 0x89 &&
        buffer[1] === 0x50 &&
        buffer[2] === 0x4e &&
        buffer[3] === 0x47 &&
        buffer[4] === 0x0d &&
        buffer[5] === 0x0a &&
        buffer[6] === 0x1a &&
        buffer[7] === 0x0a;

    const isPDF = buffer.subarray(0, 5).toString() === "%PDF-";

    return (
        (mimetype === "image/jpeg" && isJPEG) ||
        (mimetype === "image/png" && isPNG) ||
        (mimetype === "application/pdf" && isPDF)
    );
}

const uploadSingleFile = (req, res, next) => {
    upload.single("file")(req, res, (error) => {
        if (error) {
            if (error.code === "LIMIT_FILE_SIZE") {
                return res.status(413).json({
                    success: false,
                    error: {
                        code: "FILE_TOO_LARGE",
                        message: "File must not exceed 5 MB.",
                    },
                });
            }

            if (error.code === "UNSUPPORTED_FILE_TYPE") {
                return res.status(415).json({
                    success: false,
                    error: {
                        code: "UNSUPPORTED_FILE_TYPE",
                        message: error.message,
                    },
                });
            }

            if (error.code === "LIMIT_UNEXPECTED_FILE") {
                return res.status(400).json({
                    success: false,
                    error: {
                        code: "INVALID_FILE_FIELD",
                        message: "Upload one file using the field 'file'.",
                    },
                });
            }

            return res.status(400).json({
                success: false,
                error: {
                    code: "INVALID_UPLOAD",
                    message: "The file upload could not be processed.",
                },
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: {
                    code: "FILE_REQUIRED",
                    message: "Please select a file to upload.",
                },
            });
        }

        if (!hasValidFileSignature(req.file.buffer, req.file.mimetype)) {
            return res.status(415).json({
                success: false,
                error: {
                    code: "INVALID_FILE_CONTENT",
                    message: "The file content does not match its declared type.",
                },
            });
        }

        next();
    });
};

module.exports = {
    uploadSingleFile,
};