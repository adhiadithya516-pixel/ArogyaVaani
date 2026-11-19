const express = require("express");
const requireAuth = require("../middleware/authMiddleware");
const { uploadSingleImage } = require("../middleware/uploadMiddleware");
const {
  uploadAndAnalyzeReport,
  getUserReports,
  getReportById,
  deleteReport,
} = require("../controllers/reportController");

const router = express.Router();

router.post("/upload", requireAuth, uploadSingleImage, uploadAndAnalyzeReport);
router.get("/", requireAuth, getUserReports);
router.get("/:id", requireAuth, getReportById);
router.delete("/:id", requireAuth, deleteReport);

module.exports = router;
