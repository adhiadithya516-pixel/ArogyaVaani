jest.mock("@google/genai", () => ({
    GoogleGenAI: jest.fn(),
}));

const { GoogleGenAI } = require("@google/genai");

let mockGenerateContent = jest.fn();

process.env.GEMINI_API_KEY = "test-api-key";
process.env.GEMINI_MODEL = "test-gemini-model";

GoogleGenAI.mockImplementation(() => ({
    models: {
        generateContent: mockGenerateContent,
    },
}));

const {
    geminiVisionModel,
    GEMINI_MODEL,
} = require("../src/services/geminiService");

describe("Gemini Service", () => {

    beforeEach(() => {
        mockGenerateContent.mockReset();
        jest.clearAllMocks();

        jest.spyOn(console, "warn").mockImplementation(() => {});
    });

    afterEach(() => {
        jest.useRealTimers();
        jest.restoreAllMocks();
    });

    test("should use the configured Gemini model", async () => {
        const response = { text: "Test successful" };

        mockGenerateContent.mockResolvedValue(response);

        const result = await geminiVisionModel.generateContent({
            contents: "Hello Gemini",
        });

        expect(result).toBe(response);

        expect(mockGenerateContent).toHaveBeenCalledWith({
            contents: "Hello Gemini",
            model: "test-gemini-model",
        });

        expect(GEMINI_MODEL).toBe("test-gemini-model");
    });

    test("should retry when Gemini returns 503", async () => {
        jest.useFakeTimers();

        const response = { text: "Recovered successfully" };

        const serviceError = Object.assign(
            new Error("Service unavailable"),
            { status: 503 }
        );

        mockGenerateContent
            .mockRejectedValueOnce(serviceError)
            .mockResolvedValueOnce(response);

        const promise = geminiVisionModel.generateContent({
            contents: "Test retry",
        });

        await jest.advanceTimersByTimeAsync(1000);

        await expect(promise).resolves.toBe(response);

        expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    });

    test("should retry when Gemini returns 429", async () => {
        jest.useFakeTimers();

        const response = { text: "Request successful" };

        const serviceError = Object.assign(
            new Error("Rate limit exceeded"),
            { status: 429 }
        );

        mockGenerateContent
            .mockRejectedValueOnce(serviceError)
            .mockResolvedValueOnce(response);

        const promise = geminiVisionModel.generateContent({
            contents: "Test rate limit",
        });

        await jest.advanceTimersByTimeAsync(1000);

        await expect(promise).resolves.toBe(response);

        expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    });

    test("should not retry permanent errors", async () => {
        const serviceError = Object.assign(
            new Error("Invalid API key"),
            { status: 403 }
        );

        mockGenerateContent.mockRejectedValue(serviceError);

        await expect(
            geminiVisionModel.generateContent({
                contents: "Test permanent error",
            })
        ).rejects.toThrow("Invalid API key");

        expect(mockGenerateContent).toHaveBeenCalledTimes(1);
    });

        test("should reject requests without contents", async () => {
        await expect(
            geminiVisionModel.generateContent({})
        ).rejects.toThrow(
            "Gemini request must contain contents."
        );

        expect(mockGenerateContent).not.toHaveBeenCalled();
    });

    test("should stop after three failed attempts", async () => {
        jest.useFakeTimers();

        const serviceError = Object.assign(
            new Error("Service unavailable"),
            { status: 503 }
        );

        mockGenerateContent.mockRejectedValue(serviceError);

        const promise = geminiVisionModel.generateContent({
            contents: "Test maximum retries",
        });

        const assertion = expect(promise).rejects.toThrow(
            "Service unavailable"
        );

        await jest.runAllTimersAsync();

        await assertion;

        expect(mockGenerateContent).toHaveBeenCalledTimes(3);
    });
});