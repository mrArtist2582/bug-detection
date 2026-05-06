const express = require("express");
const router = express.Router();
const { GoogleGenerativeAI } = require("@google/generative-ai");
const authMiddleware = require("../middleware/auth");
const Prediction = require("../models/Prediction");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// GET /suggestions/:commitSha
router.get("/:commitSha", authMiddleware, async (req, res) => {
  try {
    const prediction = await Prediction.findOne({
      commit_sha: req.params.commitSha,
      uid: req.uid,
    });

    if (!prediction) {
      return res.status(404).json({ error: "Prediction not found" });
    }

    const prompt = `
You are a senior software engineer reviewing a GitHub commit.

Commit details:
- Repository: ${prediction.repo_name}
- Module/File changed: ${prediction.module}
- Files changed: ${prediction.files_changed}
- Lines added: ${prediction.lines_added}
- Lines removed: ${prediction.lines_removed}
- Commit count: ${prediction.commit_count}
- Risk level: ${prediction.risk_level}
- Risk score: ${prediction.risk_score}
- Pushed by: ${prediction.pushed_by}

Based on these commit details, suggest exactly 5 specific test cases that should be written to prevent bugs in this area.

For each test case provide:
1. A short title (max 8 words)
2. What to test (1-2 sentences)
3. Expected outcome (1 sentence)
4. Priority: High / Medium / Low

Respond in this exact JSON format:
{
  "test_cases": [
    {
      "title": "...",
      "description": "...",
      "expected": "...",
      "priority": "High"
    }
  ]
}
`;

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const result = await model.generateContent(prompt);
    const text = result.response.text();

    // Extract JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return res.status(500).json({ error: "Failed to parse AI response" });
    }

    const parsed = JSON.parse(jsonMatch[0]);
    res.json({
      commit_sha: prediction.commit_sha,
      module: prediction.module,
      risk_level: prediction.risk_level,
      test_cases: parsed.test_cases,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
