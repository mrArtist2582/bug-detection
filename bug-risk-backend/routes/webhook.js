const express = require("express");
const router = express.Router();
const extractFeatures = require("../utils/featureExtractor");
const getPrediction = require("../services/mlService");
const Prediction = require("../models/Prediction");

router.post("/", async (req, res) => {
  try {
    const features = await extractFeatures(req.body);
    console.log("Extracted Features:", features);
    const prediction = await getPrediction(features);
    console.log("Prediction:", prediction);

    await Prediction.create({ ...features, ...prediction });

    res.status(200).json({ module: features.module, ...prediction, message: "Processed successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Something went wrong" });
  }
});

module.exports = router;
       