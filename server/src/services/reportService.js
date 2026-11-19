const { createWorker } = require("tesseract.js");
const { geminiVisionModel } = require("./geminiService");

async function extractTextFromImage(buffer) {
  const worker = await createWorker("eng");
  try {
    const {
      data: { text, confidence },
    } = await worker.recognize(buffer);

    return {
      rawText: (text || "").trim(),
      confidence: typeof confidence === "number" ? Math.round(confidence) : 0,
    };
  } finally {
    await worker.terminate();
  }
}

async function simplifyMedicalReport({ rawText, buffer, mimetype }) {
  const prompt = `You are ArogyaVani, a compassionate medical report assistant for elderly patients in India.
Analyze the attached medical report image and the OCR text extracted from it.

OCR Extracted Text:
"""
${rawText || "(No readable text extracted by OCR; rely directly on the image)"}
"""

Return ONLY valid JSON (no markdown fences) with this exact structure:
{
  "reportTitle": "Short title of the test/report (e.g., Complete Blood Count)",
  "english": {
    "summary": "2-3 simple, reassuring sentences explaining what this report shows in plain everyday English.",
    "keyFindings": [
      {
        "parameter": "Test or marker name",
        "value": "Measured value with unit",
        "status": "Normal | High | Low | Needs Review",
        "explanation": "One simple sentence explaining what this means for the patient"
      }
    ],
    "nextSteps": ["Practical, easy-to-follow advice or questions to ask their doctor"],
    "disclaimer": "This simplified summary is for understanding only and is not a medical diagnosis. Please consult your doctor."
  },
  "kannada": {
    "summary": "2-3 simple, reassuring sentences in natural Kannada explaining the report for an elderly reader.",
    "keyFindings": [
      {
        "parameter": "Test name in Kannada (with English term in brackets)",
        "value": "Measured value with unit",
        "status": "Normal | High | Low | Needs Review",
        "explanation": "Simple Kannada explanation of what this value means"
      }
    ],
    "nextSteps": ["Practical advice in simple Kannada"],
    "disclaimer": "This simplified summary is for understanding only and is not a medical diagnosis. Please consult your doctor."
  }
}`;

  const contents = [
    {
      role: "user",
      parts: [
        { text: prompt },
        ...(buffer && mimetype
          ? [
              {
                inlineData: {
                  mimeType: mimetype,
                  data: buffer.toString("base64"),
                },
              },
            ]
          : []),
      ],
    },
  ];

  const response = await geminiVisionModel.generateContent({ contents });
  const responseText =
    typeof response?.text === "function"
      ? response.text()
      : response?.text ||
        response?.candidates?.[0]?.content?.parts?.[0]?.text ||
        "";

  const cleanedJson = responseText
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();

  try {
    return JSON.parse(cleanedJson);
  } catch {
    return {
      reportTitle: "Medical Report Summary",
      english: {
        summary: cleanedJson || "Unable to parse structured summary.",
        keyFindings: [],
        nextSteps: ["Please share this report with your doctor for review."],
        disclaimer:
          "This simplified summary is for understanding only and is not a medical diagnosis. Please consult your doctor.",
      },
      kannada: {
        summary:
          "Report summary generated. Please consult your doctor for medical advice.",
        keyFindings: [],
        nextSteps: ["Please show this report to your doctor."],
        disclaimer:
          "This simplified summary is for understanding only and is not a medical diagnosis. Please consult your doctor.",
      },
    };
  }
}

module.exports = {
  extractTextFromImage,
  simplifyMedicalReport,
};
