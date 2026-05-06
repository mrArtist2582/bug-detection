const express = require("express");
const router = express.Router();
const extractFeatures = require("../utils/featureExtractor");
const getPrediction = require("../services/mlService");
const Prediction = require("../models/Prediction");
const User = require("../models/User");

router.post("/", async (req, res) => {
  try {
    const repoName = req.body.repository?.full_name;

    // Find which user owns this repo
    const user = await User.findOne({ repo: repoName });

    const features = await extractFeatures(req.body);
    const prediction = await getPrediction(features);

    await Prediction.create({
      uid: user?.uid || null,
      ...features,
      ...prediction,
    });

    res.status(200).json({ message: "Processed successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Something went wrong" });
  }
});

module.exports = router;
