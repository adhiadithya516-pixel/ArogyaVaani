const express = require("express");
const cors = require("cors");
const healthRoutes = require("./routes/healthRoutes");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use("/api/health", healthRoutes);

app.get("/", (req, res) => {
  res.json({ message: "ArogyaVani API is running" });
});

app.listen(PORT, () => {
  console.log(`ArogyaVani server is running on port ${PORT}`);
});