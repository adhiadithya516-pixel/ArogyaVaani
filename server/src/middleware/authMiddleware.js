const { adminAuth } = require("../services/firebaseAdmin");

const requireAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  // 1. Check whether the Authorization header exists
  if (!authHeader) {
    return res.status(401).json({
      success: false,
      error: {
        code: "AUTH_TOKEN_MISSING",
        message: "A valid Bearer token is required.",
      },
    });
  }

  // 2. Validate Bearer token format
  const bearerMatch = authHeader.match(/^Bearer(?:\s+(.*))?$/i);

  if (!bearerMatch) {
    return res.status(401).json({
      success: false,
      error: {
        code: "AUTH_TOKEN_MISSING",
        message: "A valid Bearer token is required.",
      },
    });
  }

  // 3. Extract token
  const token = (bearerMatch[1] || "").trim();

  // 4. Check whether token is empty
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
    // 5. Verify Firebase ID token
    const decodedToken = await adminAuth.verifyIdToken(token);

    // 6. Attach authenticated user information
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || "",
      emailVerified: decodedToken.email_verified || false,
    };

    // 7. Continue to the next middleware/controller
    return next();

  } catch (error) {
    // 8. Handle expired and invalid tokens
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