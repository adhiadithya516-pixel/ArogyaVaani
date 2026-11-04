const express = require("express");
const cors = require("cors");
const healthRoutes = require("./routes/healthRoutes");
const { initializeFirebaseAdmin } = require("./services/firebaseAdmin");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use("/api/health", healthRoutes);

app.get("/", (req, res) => {
  res.json({ message: "ArogyaVani API is running" });
});
initializeFirebaseAdmin();

app.listen(PORT, () => {
  console.log(`ArogyaVani server is running on port ${PORT}`);
});