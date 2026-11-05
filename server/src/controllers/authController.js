const { adminAuth, adminDb } = require("../services/firebaseAdmin");

const register = async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Name, email, and password are required.",
      },
    });
  }

  try {
    const userRecord = await adminAuth.createUser({
      displayName: name.trim(),
      email: email.trim(),
      password,
    });

    const profile = {
      uid: userRecord.uid,
      name: name.trim(),
      email: email.trim(),
      emergencyContacts: [],
      createdAt: new Date().toISOString(),
    };

    await adminDb.collection("users").doc(userRecord.uid).set(profile);

    return res.status(201).json({
      success: true,
      data: { profile },
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      return res.status(409).json({
        success: false,
        error: {
          code: "EMAIL_ALREADY_EXISTS",
          message: "An account with this email already exists.",
        },
      });
    }

    console.error("Registration error:", error.message);

    return res.status(500).json({
      success: false,
      error: {
        code: "REGISTRATION_FAILED",
        message: "Could not create the account.",
      },
    });
  }
};

const getProfile = async (req, res) => {
  try {
    const userDoc = await adminDb.collection("users").doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: {
          code: "PROFILE_NOT_FOUND",
          message: "User profile not found.",
        },
      });
    }

    return res.json({
      success: true,
      data: { profile: userDoc.data() },
    });
  } catch (error) {
    console.error("Get profile error:", error.message);

    return res.status(500).json({
      success: false,
      error: {
        code: "PROFILE_FETCH_FAILED",
        message: "Could not retrieve the user profile.",
      },
    });
  }
};
const updateProfile = async (req, res) => {
  const { name, emergencyContacts } = req.body;

  if (name === undefined && emergencyContacts === undefined) {
    return res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Provide a name or emergency contacts to update.",
      },
    });
  }

  if (
    emergencyContacts !== undefined &&
    !Array.isArray(emergencyContacts)
  ) {
    return res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Emergency contacts must be an array.",
      },
    });
  }

  const updates = {};

  if (name !== undefined) {
    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Name must be a non-empty string.",
        },
      });
    }

    updates.name = name.trim();
  }

  if (emergencyContacts !== undefined) {
    updates.emergencyContacts = emergencyContacts;
  }

  try {
    const userRef = adminDb.collection("users").doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: {
          code: "PROFILE_NOT_FOUND",
          message: "User profile not found.",
        },
      });
    }

    await userRef.update(updates);
    const updatedDoc = await userRef.get();

    return res.json({
      success: true,
      data: { profile: updatedDoc.data() },
    });
  } catch (error) {
    console.error("Update profile error:", error.message);

    return res.status(500).json({
      success: false,
      error: {
        code: "PROFILE_UPDATE_FAILED",
        message: "Could not update the user profile.",
      },
    });
  }
};

module.exports = { register, getProfile, updateProfile };