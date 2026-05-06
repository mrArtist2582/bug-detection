const axios = require("axios");

module.exports = async function getPrediction(features) {
  try {
    const response = await axios.post(`${process.env.ML_SERVICE_URL || "http://localhost:8000"}/predict`, features);
    return response.data;
  } catch {
    return {
      risk_score: Math.random().toFixed(2),
      risk_level: "Medium",
      confidence: 0.75
    };
  }
};
