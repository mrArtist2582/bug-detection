const express = require("express");
const Prediction = require("../models/Prediction");
const router = express.Router();

// GET /predictions?repo=owner/repo&limit=50
router.get("/", async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const filter = {};
    if (req.query.repo) filter.repo_name = req.query.repo;
    const predictions = await Prediction.find(filter)
      .sort({ timestamp: -1 })
      .limit(limit);
    res.json(predictions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /predictions/:id
router.get("/:id", async (req, res) => {
  try {
    const prediction = await Prediction.findById(req.params.id);
    if (!prediction) return res.status(404).json({ error: "Not found" });
    res.json(prediction);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /predictions/:id
router.delete("/:id", async (req, res) => {
  try {
    await Prediction.findByIdAndDelete(req.params.id);
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
