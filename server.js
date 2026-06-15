require("dotenv").config();

const express = require("express");
const path = require("path");
const cookieParser = require("cookie-parser");

const authRoutes = require("./routes/auth");

const app = express();

app.use(express.json());
app.use(cookieParser());

// ---- API routes ----
app.use("/api/auth", authRoutes);

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", time: new Date().toISOString() });
});

// ---- Static frontend ----
const publicDir = path.join(__dirname, "..", "public");
app.use(express.static(publicDir));

// Fallback to the homepage for any unmatched non-API route
app.get("*", (req, res, next) => {
  if (req.path.startsWith("/api")) return next();
  res.sendFile(path.join(publicDir, "index.html"));
});

// ---- 404 for unmatched API routes ----
app.use("/api", (req, res) => {
  res.status(404).json({ error: "Not found" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`GEMSTORE backend running on http://localhost:${PORT}`);
});
