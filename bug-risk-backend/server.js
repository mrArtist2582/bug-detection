const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
require("dotenv").config();

const webhookRoute = require("./routes/webhook");
const setupWebhookRoute = require("./routes/setupWebhook");
const predictionsRoute = require("./routes/predictions");
const authRoute = require("./routes/auth");
const suggestionsRoute = require("./routes/suggestions");

const app = express();

app.use(express.json({ limit: "10mb" }));
app.use(cors());

app.use("/auth", authRoute);
app.use("/suggestions", suggestionsRoute);
app.use("/webhook", webhookRoute);
app.use("/setup-webhook", setupWebhookRoute);
app.use("/predictions", predictionsRoute);
app.get("/health", (req, res) => res.json({ status: "ok" }));

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.error("MongoDB error:", err));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
