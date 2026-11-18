require("dotenv").config();

const fs = require("node:fs");
const path = require("node:path");

const { geminiVisionModel, GEMINI_MODEL } = require("../src/services/geminiService");

async function testImageAnalysis() {
    try {
        const imagePath = path.join(__dirname, "fixtures", "sample.jpg");

        const imageBuffer = fs.readFileSync(imagePath);

        const response = await geminiVisionModel.generateContent({
            contents: [
                {
                    role: "user",
                    parts: [
                        {
                            text: "Describe what you see in this image in two sentences."
                        },
                        {
                            inlineData: {
                                mimeType: "image/jpeg",
                                data: imageBuffer.toString("base64")
                            }
                        }
                    ]
                }
            ]
        });

        console.log("Model:", GEMINI_MODEL);
        console.log("Image analysis successful!");
        console.log("Gemini response:", response.text);

    } catch (error) {
        console.error("Image analysis failed:", error.message);
        process.exitCode = 1;
    }
}

testImageAnalysis();