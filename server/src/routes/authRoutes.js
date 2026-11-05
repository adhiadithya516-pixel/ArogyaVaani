const express = require("express");
const requireAuth = require("../middleware/authMiddleware");
const { register, getProfile, updateProfile } = require("../controllers/authController");

const router = express.Router();

router.post("/register", register);
router.get("/profile", requireAuth, getProfile);
router.put("/profile", requireAuth, updateProfile);

module.exports = router;