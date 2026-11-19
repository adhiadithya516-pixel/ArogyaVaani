const { adminDb } = require("../services/firebaseAdmin");
const {
  uploadReportImage,
  getSignedReportUrl,
  deleteReportImage,
} = require("../services/storageService");
const {
  extractTextFromImage,
  simplifyMedicalReport,
} = require("../services/reportService");

const REPORTS_COLLECTION = "reports";

const uploadAndAnalyzeReport = async (req, res) => {
  try {
    const { uid } = req.user;
    const { buffer, mimetype, originalname } = req.file;

    const [storageResult, ocrResult] = await Promise.all([
      uploadReportImage({
        buffer,
        mimetype,
        originalName: originalname,
        uid,
      }),
      extractTextFromImage(buffer),
    ]);

    const simplified = await simplifyMedicalReport({
      rawText: ocrResult.rawText,
      buffer,
      mimetype,
    });

    const docRef = adminDb.collection(REPORTS_COLLECTION).doc();
    const now = new Date().toISOString();

    const reportRecord = {
      id: docRef.id,
      uid,
      fileName: originalname || "report.jpg",
      mimeType: mimetype,
      storageProvider: storageResult.storageProvider,
      filePath: storageResult.filePath,
      ocrText: ocrResult.rawText,
      ocrConfidence: ocrResult.confidence,
      reportTitle: simplified.reportTitle || "Medical Report",
      english: simplified.english,
      kannada: simplified.kannada,
      createdAt: now,
    };

    await docRef.set(reportRecord);

    return res.status(201).json({
      success: true,
      report: {
        ...reportRecord,
        signedUrl: storageResult.signedUrl,
      },
    });
  } catch (error) {
    console.error("Error processing medical report:", error);

    return res.status(500).json({
      success: false,
      error: {
        code: error.code || "REPORT_PROCESSING_FAILED",
        message: "Failed to process and simplify the medical report.",
      },
    });
  }
};

const getUserReports = async (req, res) => {
  try {
    const { uid } = req.user;

    const snapshot = await adminDb
      .collection(REPORTS_COLLECTION)
      .where("uid", "==", uid)
      .get();

    const reports = snapshot.docs
      .map((doc) => doc.data())
      .sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""));

    return res.status(200).json({
      success: true,
      reports,
    });
  } catch (error) {
    console.error("Error fetching user reports:", error);

    return res.status(500).json({
      success: false,
      error: {
        code: "REPORTS_FETCH_FAILED",
        message: "Failed to retrieve medical reports.",
      },
    });
  }
};

const getReportById = async (req, res) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const docSnap = await adminDb.collection(REPORTS_COLLECTION).doc(id).get();

    if (!docSnap.exists) {
      return res.status(404).json({
        success: false,
        error: {
          code: "REPORT_NOT_FOUND",
          message: "Medical report not found.",
        },
      });
    }

    const report = docSnap.data();

    if (report.uid !== uid) {
      return res.status(403).json({
        success: false,
        error: {
          code: "FORBIDDEN_REPORT_ACCESS",
          message: "You do not have permission to view this report.",
        },
      });
    }

    const signedUrl = await getSignedReportUrl(report.filePath);

    return res.status(200).json({
      success: true,
      report: {
        ...report,
        signedUrl,
      },
    });
  } catch (error) {
    console.error("Error fetching report details:", error);

    return res.status(500).json({
      success: false,
      error: {
        code: "REPORT_DETAIL_FAILED",
        message: "Failed to retrieve medical report details.",
      },
    });
  }
};

const deleteReport = async (req, res) => {
  try {
    const { uid } = req.user;
    const { id } = req.params;

    const docRef = adminDb.collection(REPORTS_COLLECTION).doc(id);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({
        success: false,
        error: {
          code: "REPORT_NOT_FOUND",
          message: "Medical report not found.",
        },
      });
    }

    const report = docSnap.data();

    if (report.uid !== uid) {
      return res.status(403).json({
        success: false,
        error: {
          code: "FORBIDDEN_REPORT_ACCESS",
          message: "You do not have permission to delete this report.",
        },
      });
    }

    await Promise.all([
      deleteReportImage(report.filePath),
      docRef.delete(),
    ]);

    return res.status(200).json({
      success: true,
      message: "Medical report deleted successfully.",
    });
  } catch (error) {
    console.error("Error deleting report:", error);

    return res.status(500).json({
      success: false,
      error: {
        code: "REPORT_DELETE_FAILED",
        message: "Failed to delete medical report.",
      },
    });
  }
};

module.exports = {
  uploadAndAnalyzeReport,
  getUserReports,
  getReportById,
  deleteReport,
};
