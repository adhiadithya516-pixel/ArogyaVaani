const { adminAuth } = require("../services/firebaseAdmin");

const requireAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({
      success: false,
      error: {
        code: "AUTH_TOKEN_MISSING",
        message: "A valid Bearer token is required.",
      },
    });
  }

  const token = authHeader.slice("Bearer ".length).trim();

  if (!token) {
    return res.status(401).json({
      success: false,
      error: {
        code: "AUTH_TOKEN_EMPTY",
        message: "The authorization token is empty.",
      },
    });
  }

  try {
    const decodedToken = await adminAuth.verifyIdToken(token);

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || "",
      emailVerified: decodedToken.email_verified || false,
    };

    return next();
  } catch (error) {
    const expired = error.code === "auth/id-token-expired";

    return res.status(401).json({
      success: false,
      error: {
        code: expired ? "AUTH_TOKEN_EXPIRED" : "AUTH_TOKEN_INVALID",
        message: expired
          ? "Your session has expired. Please log in again."
          : "The authorization token is invalid.",
      },
    });
  }
};

module.exports = requireAuth;