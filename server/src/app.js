    require("dotenv").config();

const express = require("express");
const cors = require("cors");

const healthRoutes = require("./routes/healthRoutes");
const authRoutes = require("./routes/authRoutes");
const storageRoutes = require("./routes/storageRoutes");
const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/health", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/storage", storageRoutes);
app.get("/", (req, res) => {
  res.json({ message: "ArogyaVani API is running" });
});

module.exports = app;