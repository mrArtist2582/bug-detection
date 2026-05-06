const express = require("express");
const axios = require("axios");

const router = express.Router();

const REPO_PATTERN = /^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/;
const GITHUB_API_BASE = "https://api.github.com";

function validateCsrf(req, res, next) {
  const clientSecret = req.headers["x-setup-secret"];
  if (!clientSecret || clientSecret !== process.env.SETUP_SECRET) {
    return res.status(403).json({ error: "Forbidden" });
  }
  next();
}

// POST /setup-webhook
// Headers: x-setup-secret: <SETUP_SECRET>
// Body: { repo: "owner/repo-name" }
router.post("/", validateCsrf, async (req, res) => {
  const { repo } = req.body;

  if (!repo || !REPO_PATTERN.test(repo)) {
    return res.status(400).json({ error: "Invalid repo format. Use owner/repo-name" });
  }

  const webhookUrl = `${process.env.DEPLOYED_URL}/webhook`;

  try {
    const response = await axios.post(
      `${GITHUB_API_BASE}/repos/${repo}/hooks`,
      {
        name: "web",
        active: true,
        events: ["push"],
        config: {
          url: webhookUrl,
          content_type: "json",
          insecure_ssl: "0",
        },
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
          Accept: "application/vnd.github+json",
        },
      }
    );

    res.status(201).json({
      message: `Webhook registered successfully on ${repo}`,
      webhook_id: response.data.id,
      webhook_url: webhookUrl,
    });
  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    res.status(500).json({ error: msg });
  }
});

module.exports = router;
