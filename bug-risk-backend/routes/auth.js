const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/auth");
const User = require("../models/User");

// POST /auth/verify — called after Firebase login/signup
// Creates user in MongoDB if not exists
router.post("/verify", authMiddleware, async (req, res) => {
  try {
    let user = await User.findOne({ uid: req.uid });
    if (!user) {
      user = await User.create({ uid: req.uid, email: req.email });
    }
    res.json({
      uid: user.uid,
      email: user.email,
      repo: user.repo,
      hasRepo: !!user.repo,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /auth/me — get current user profile
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const user = await User.findOne({ uid: req.uid });
    if (!user) return res.status(404).json({ error: "User not found" });
    res.json({ uid: user.uid, email: user.email, repo: user.repo, hasRepo: !!user.repo });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
