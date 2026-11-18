const { adminAuth, adminDb } = require("../services/firebaseAdmin");

// REGISTER USER
const register = async (req, res) => {
  const { name, email, password } = req.body;

  // Validate required fields
  if (
    typeof name !== "string" ||
    typeof email !== "string" ||
    typeof password !== "string" ||
    !name.trim() ||
    !email.trim() ||
    !password
  ) {
    return res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Valid name, email, and password are required.",
      },
    });
  }

  const cleanName = name.trim();
  const cleanEmail = email.trim();

  // Validate email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(cleanEmail)) {
    return res.status(400).json({
      success: false,
      error: {
        code: "INVALID_EMAIL",
        message: "Please provide a valid email address.",
      },
    });
  }

  // Validate password
  if (password.length < 8) {
    return res.status(400).json({
      success: false,
      error: {
        code: "WEAK_PASSWORD",
        message: "Password must contain at least 8 characters.",
      },
    });
  }

  let userRecord;

  try {
    // Create Firebase Authentication account
    userRecord = await adminAuth.createUser({
      displayName: cleanName,
      email: cleanEmail,
      password,
    });

    const timestamp = new Date().toISOString();

    // Prepare Firestore profile
    const profile = {
      uid: userRecord.uid,
      name: cleanName,
      email: cleanEmail,
      emergencyContacts: [],
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    // Save profile in Firestore
    await adminDb
      .collection("users")
      .doc(userRecord.uid)
      .set(profile);

    return res.status(201).json({
      success: true,
      data: { profile },
    });

  } catch (error) {
    // Remove Auth account if Firestore profile creation fails
    if (userRecord) {
      try {
        await adminAuth.deleteUser(userRecord.uid);
      } catch (cleanupError) {
        console.error(
          "Registration cleanup error:",
          cleanupError.message
        );
      }
    }

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

// GET USER PROFILE
const getProfile = async (req, res) => {
  try {
    const userDoc = await adminDb
      .collection("users")
      .doc(req.user.uid)
      .get();

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

// UPDATE USER PROFILE
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

  updates.updatedAt = new Date().toISOString();

  try {
    const userRef = adminDb
      .collection("users")
      .doc(req.user.uid);

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

module.exports = {
  register,
  getProfile,
  updateProfile,
};