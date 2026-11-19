const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const SUPABASE_STORAGE_BUCKET =
  process.env.SUPABASE_STORAGE_BUCKET || "medical-reports";

const supabase =
  SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
    ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    : null;

async function uploadReportImage({ buffer, mimetype, originalName, uid }) {
  if (!supabase) {
    return {
      storageProvider: "pending-supabase",
      filePath: null,
      signedUrl: null,
    };
  }

  const sanitizedName = (originalName || "report.jpg").replace(
    /[^a-zA-Z0-9._-]/g,
    "_"
  );
  const filePath = `${uid}/${Date.now()}-${sanitizedName}`;

  const { error: uploadError } = await supabase.storage
    .from(SUPABASE_STORAGE_BUCKET)
    .upload(filePath, buffer, {
      contentType: mimetype,
      upsert: false,
    });

  if (uploadError) {
    const err = new Error(`Storage upload failed: ${uploadError.message}`);
    err.code = "STORAGE_UPLOAD_FAILED";
    throw err;
  }

  const signedUrl = await getSignedReportUrl(filePath);

  return {
    storageProvider: "supabase",
    filePath,
    signedUrl,
  };
}

async function getSignedReportUrl(filePath, expiresInSeconds = 3600) {
  if (!supabase || !filePath) {
    return null;
  }

  const { data, error } = await supabase.storage
    .from(SUPABASE_STORAGE_BUCKET)
    .createSignedUrl(filePath, expiresInSeconds);

  if (error) {
    console.warn("Failed to create signed URL:", error.message);
    return null;
  }

  return data?.signedUrl || null;
}

async function deleteReportImage(filePath) {
  if (!supabase || !filePath) {
    return;
  }

  const { error } = await supabase.storage
    .from(SUPABASE_STORAGE_BUCKET)
    .remove([filePath]);

  if (error) {
    console.warn("Failed to delete storage object:", error.message);
  }
}

module.exports = {
  uploadReportImage,
  getSignedReportUrl,
  deleteReportImage,
};
