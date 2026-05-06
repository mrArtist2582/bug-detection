const express = require("express");
const router = express.Router();
const { GoogleGenerativeAI } = require("@google/generative-ai");
const authMiddleware = require("../middleware/auth");
const Prediction = require("../models/Prediction");

const FALLBACK_CASES = {
  High: [
    { title: "Test all modified code paths", description: "Verify every changed function handles both valid and invalid inputs correctly.", expected: "No unexpected exceptions or incorrect outputs.", priority: "High" },
    { title: "Regression test existing features", description: "Run full regression suite to ensure existing functionality is not broken by this commit.", expected: "All existing tests pass without modification.", priority: "High" },
    { title: "Test edge cases and boundary values", description: "Test with minimum, maximum, null, and empty values for all changed parameters.", expected: "Graceful handling of all edge cases.", priority: "High" },
    { title: "Integration test with dependent modules", description: "Test how the changed module interacts with all modules that depend on it.", expected: "No integration failures or data corruption.", priority: "Medium" },
    { title: "Load test the changed endpoints", description: "Simulate high traffic on any changed API endpoints or functions.", expected: "System remains stable under load.", priority: "Medium" },
  ],
  Medium: [
    { title: "Unit test all changed functions", description: "Write unit tests for every function that was added or modified in this commit.", expected: "100% of new functions have passing unit tests.", priority: "High" },
    { title: "Test error handling paths", description: "Verify that error conditions in changed code are properly caught and handled.", expected: "Errors are logged and user receives appropriate feedback.", priority: "Medium" },
    { title: "Validate data transformations", description: "Check that any data processing or transformation logic produces correct results.", expected: "Output data matches expected format and values.", priority: "Medium" },
    { title: "Test with realistic data samples", description: "Use production-like data to test the changed functionality end to end.", expected: "Feature works correctly with real-world data.", priority: "Medium" },
    { title: "Check for memory leaks", description: "Monitor memory usage during extended use of the changed functionality.", expected: "Memory usage remains stable over time.", priority: "Low" },
  ],
  Low: [
    { title: "Basic smoke test", description: "Run a quick smoke test to verify the core functionality still works after this commit.", expected: "Application starts and core features are functional.", priority: "Low" },
    { title: "UI/UX validation", description: "Verify that any UI changes render correctly across different screen sizes.", expected: "UI displays correctly on all target devices.", priority: "Low" },
    { title: "Code review checklist", description: "Ensure the commit follows coding standards and best practices.", expected: "Code passes linting and style checks.", priority: "Low" },
    { title: "Documentation update check", description: "Verify that any changed APIs or functions have updated documentation.", expected: "All public APIs are properly documented.", priority: "Low" },
    { title: "Dependency compatibility check", description: "Ensure no dependency versions were changed that could cause compatibility issues.", expected: "All dependencies remain compatible.", priority: "Low" },
  ],
};

// GET /suggestions/:commitSha
router.get("/:commitSha", authMiddleware, async (req, res) => {
  try {
    const prediction = await Prediction.findOne({ commit_sha: req.params.commitSha });

    if (!prediction) {
      return res.status(404).json({ error: "Prediction not found" });
    }

    if (process.env.GEMINI_API_KEY) {
      try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

        const prompt = `You are a senior software engineer reviewing a GitHub commit.

Commit details:
- Repository: ${prediction.repo_name}
- Module/File changed: ${prediction.module}
- Files changed: ${prediction.files_changed}
- Lines added: ${prediction.lines_added}
- Lines removed: ${prediction.lines_removed}
- Risk level: ${prediction.risk_level}
- Risk score: ${prediction.risk_score}

Suggest exactly 5 specific test cases to prevent bugs. Respond ONLY with this JSON, no extra text:
{"test_cases":[{"title":"...","description":"...","expected":"...","priority":"High"}]}`;

        const result = await model.generateContent(prompt);
        const text = result.response.text();
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.test_cases?.length) {
            return res.json({
              commit_sha: prediction.commit_sha,
              module: prediction.module,
              risk_level: prediction.risk_level,
              test_cases: parsed.test_cases,
              source: "ai",
            });
          }
        }
      } catch (aiErr) {
        console.warn("Gemini failed, using fallback:", aiErr.message);
      }
    }

    const cases = FALLBACK_CASES[prediction.risk_level] || FALLBACK_CASES.Low;
    res.json({
      commit_sha: prediction.commit_sha,
      module: prediction.module,
      risk_level: prediction.risk_level,
      test_cases: cases,
      source: "fallback",
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
