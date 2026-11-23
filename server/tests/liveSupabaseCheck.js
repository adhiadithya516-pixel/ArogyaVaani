require("dotenv").config();

const fs = require("fs");
const path = require("path");

const {
    supabase,
    STORAGE_BUCKET,
    uploadFile,
    generateSignedUrl,
} = require("../src/services/supabaseService");

async function testSupabaseStorage() {
    let uploadedPath = null;

    const firebaseUid = "supabase-live-test-user";

    const imagePath = path.join(
        __dirname,
        "fixtures",
        "sample.jpg"
    );

    try {
        console.log("\n--- SUPABASE LIVE STORAGE TEST ---\n");

        // Read the test image.
        const buffer = fs.readFileSync(imagePath);

        const file = {
            buffer,
            mimetype: "image/jpeg",
            size: buffer.length,
        };

        console.log("1. Test image loaded successfully.");

        // Upload to Supabase.
        const uploadResult = await uploadFile(
            firebaseUid,
            file,
            "medicine-images"
        );

        uploadedPath = uploadResult.path;

        console.log("2. Upload successful.");
        console.log("   Bucket:", uploadResult.bucket);
        console.log("   File ID:", uploadResult.fileId);

        // Generate signed URL.
        const signedUrl = await generateSignedUrl(
            firebaseUid,
            uploadedPath
        );

        console.log("3. Signed URL generated successfully.");
        console.log("   URL generated (not displayed for security).");

        // Download the uploaded file.
        const { data, error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .download(uploadedPath);

        if (error) throw error;

        const downloadedBuffer = Buffer.from(
            await data.arrayBuffer()
        );

        console.log("4. Download successful.");
        console.log("   Downloaded size:", downloadedBuffer.length);

        // Verify downloaded content.
        if (!downloadedBuffer.equals(buffer)) {
            throw new Error("Downloaded file does not match uploaded file.");
        }

        console.log("5. File integrity verified.");

        // Test cross-user access protection.
        try {
            await generateSignedUrl(
                "another-test-user",
                uploadedPath
            );

            throw new Error("Cross-user access was unexpectedly allowed.");
        } catch (error) {
            if (error.message !== "Unauthorized file access.") {
                throw error;
            }

            console.log("6. Cross-user access correctly rejected.");
        }

        console.log("\nALL LIVE STORAGE TESTS PASSED.");

    } catch (error) {
        console.error("\nStorage test failed:", error.message);

    } finally {
        // Delete the temporary test image.
        if (uploadedPath) {
            const { error } = await supabase.storage
                .from(STORAGE_BUCKET)
                .remove([uploadedPath]);

            if (error) {
                console.error("Test file cleanup failed:", error.message);
            } else {
                console.log("\nTemporary test file deleted.");
            }
        }
    }
}

testSupabaseStorage();