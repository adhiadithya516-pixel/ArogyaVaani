const multer = require("multer");

const MAX_FILE_SIZE = 5 * 1024 * 1024;

const storage = multer.memoryStorage();

const fileFilter = (req, file, callback) => {
    const allowedTypes = ["image/jpeg", "image/png"];

    if (!allowedTypes.includes(file.mimetype)) {
        const error = new Error("Only JPEG and PNG images are allowed.");
        error.code = "UNSUPPORTED_IMAGE_TYPE";
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

function hasValidImageSignature(buffer, mimetype) {
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

    return (
        (mimetype === "image/jpeg" && isJPEG) ||
        (mimetype === "image/png" && isPNG)
    );
}

const uploadSingleImage = (req, res, next) => {
    upload.single("image")(req, res, (error) => {
        if (error) {
            if (error.code === "LIMIT_FILE_SIZE") {
                return res.status(413).json({
                    success: false,
                    error: {
                        code: "IMAGE_TOO_LARGE",
                        message: "Image must not exceed 5 MB.",
                    },
                });
            }

            if (error.code === "UNSUPPORTED_IMAGE_TYPE") {
                return res.status(415).json({
                    success: false,
                    error: {
                        code: "UNSUPPORTED_IMAGE_TYPE",
                        message: error.message,
                    },
                });
            }

            if (error.code === "LIMIT_UNEXPECTED_FILE") {
                return res.status(400).json({
                    success: false,
                    error: {
                        code: "INVALID_FILE_FIELD",
                        message: "Upload exactly one image using the field 'image'.",
                    },
                });
            }

            return res.status(400).json({
                success: false,
                error: {
                    code: "INVALID_UPLOAD",
                    message: "The image upload could not be processed.",
                },
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: {
                    code: "IMAGE_REQUIRED",
                    message: "Please upload an image.",
                },
            });
        }

        if (!hasValidImageSignature(req.file.buffer, req.file.mimetype)) {
            return res.status(415).json({
                success: false,
                error: {
                    code: "INVALID_IMAGE_CONTENT",
                    message: "The uploaded file is not a valid JPEG or PNG image.",
                },
            });
        }

        next();
    });
};

module.exports = {
    uploadSingleImage,
};