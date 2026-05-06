const mongoose = require("mongoose");

const predictionSchema = new mongoose.Schema({
  module:       String,
  files_changed: Number,
  lines_added:   Number,
  lines_removed: Number,
  commit_count:  Number,
  risk_score:    Number,
  risk_level:    String,
  confidence:    Number,
  timestamp:     { type: Date, default: Date.now }
});

module.exports = mongoose.model("Prediction", predictionSchema);
