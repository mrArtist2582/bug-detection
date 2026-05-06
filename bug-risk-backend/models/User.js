const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  uid:          { type: String, required: true, unique: true, index: true },
  email:        { type: String, required: true },
  repo:         { type: String, default: null },
  github_token: { type: String, default: null },
  created_at:   { type: Date, default: Date.now },
});

module.exports = mongoose.model("User", userSchema);
