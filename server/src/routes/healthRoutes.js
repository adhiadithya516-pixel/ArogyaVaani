const express = require("express");

const router = express.Router();

router.get("/", (req, res) => {
  return res.json({
    status: "ok",
    message: "ArogyaVani API is healthy",
  });
});

module.exports = router;