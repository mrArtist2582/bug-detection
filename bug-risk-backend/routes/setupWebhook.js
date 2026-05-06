const express = require("express");
const axios = require("axios");
const router = express.Router();
const authMiddleware = require("../middleware/auth");
const User = require("../models/User");

const REPO_PATTERN = /^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/;
const GITHUB_API_BASE = "https://api.github.com";

// POST /setup-webhook
// Headers: Authorization: Bearer <firebase_id_token>
// Body: { repo: "owner/repo-name", github_token: "ghp_xxx" }
router.post("/", authMiddleware, async (req, res) => {
  const { repo, github_token } = req.body;

  if (!repo || !REPO_PATTERN.test(repo)) {
    return res.status(400).json({ error: "Invalid repo format. Use owner/repo-name" });
  }

  if (!github_token) {
    return res.status(400).json({ error: "GitHub token is required" });
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
          Authorization: `Bearer ${github_token}`,
          Accept: "application/vnd.github+json",
        },
      }
    );

    // Save repo and token to user profile
    await User.findOneAndUpdate(
      { uid: req.uid },
      { repo, github_token },
      { new: true }
    );

    res.status(201).json({
      message: `Webhook registered successfully on ${repo}`,
      webhook_id: response.data.id,
    });
  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    res.status(500).json({ error: msg });
  }
});

module.exports = router;
