const { GoogleGenAI } = require("@google/genai");

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.5-flash-lite";

const MAX_RETRIES = 3;
const INITIAL_RETRY_DELAY = 1000;

if (!GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is missing from environment variables.");
}

const ai = new GoogleGenAI({
    apiKey: GEMINI_API_KEY,
});

// Identify temporary errors that can be retried.
function isRetryableError(error) {
    const status = Number(error.status || error.code);

    return (
        status === 429 ||
        status === 500 ||
        status === 502 ||
        status === 503 ||
        status === 504
    );
}

// Wait before retrying.
function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

// Shared Gemini interface.
const geminiVisionModel = {
    generateContent: async (request) => {
        if (!request || !request.contents) {
            throw new Error("Gemini request must contain contents.");
        }

        for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                return await ai.models.generateContent({
                    ...request,
                    model: GEMINI_MODEL,
                });

            } catch (error) {
                const shouldRetry =
                    isRetryableError(error) && attempt < MAX_RETRIES;

                if (!shouldRetry) {
                    throw error;
                }

                const waitTime =
                    INITIAL_RETRY_DELAY * Math.pow(2, attempt - 1);

                console.warn(
                    `Gemini request failed. Retrying in ${waitTime}ms. Attempt ${attempt}/${MAX_RETRIES}`
                );

                await delay(waitTime);
            }
        }
    },
};

module.exports = {
    ai,
    geminiVisionModel,
    GEMINI_MODEL,
};