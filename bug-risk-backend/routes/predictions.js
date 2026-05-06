const express = require("express");
const router = express.Router();
const Prediction = require("../models/Prediction");
const authMiddleware = require("../middleware/auth");

// GET /predictions?limit=50
router.get("/", authMiddleware, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const predictions = await Prediction.find({ uid: req.uid })
      .sort({ timestamp: -1 })
      .limit(limit);
    res.json(predictions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /predictions/:id
router.get("/:id", authMiddleware, async (req, res) => {
  try {
    const prediction = await Prediction.findOne({ _id: req.params.id, uid: req.uid });
    if (!prediction) return res.status(404).json({ error: "Not found" });
    res.json(prediction);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /predictions/:id
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    await Prediction.findOneAndDelete({ _id: req.params.id, uid: req.uid });
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
