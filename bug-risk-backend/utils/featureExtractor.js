const axios = require("axios");

module.exports = async function extractFeatures(payload) {
  const commits = payload.commits || [];
  const repoFullName = payload.repository?.full_name;

  let filesChanged = 0;
  let linesAdded = 0;
  let linesRemoved = 0;

  for (const commit of commits) {
    filesChanged += commit.added.length + commit.removed.length + commit.modified.length;

    if (repoFullName && process.env.GITHUB_TOKEN) {
      try {
        const { data } = await axios.get(
          `https://api.github.com/repos/${repoFullName}/commits/${commit.id}`,
          { headers: { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` } }
        );
        linesAdded   += data.stats?.additions || 0;
        linesRemoved += data.stats?.deletions  || 0;
      } catch {
        // fallback: estimate from file-level stats if available
        for (const file of commit.modified || []) {
          linesAdded   += 5;
          linesRemoved += 2;
        }
      }
    }
  }

  const moduleName = commits[0]?.modified[0]?.split("/")[0] || "core";

  return {
    module: moduleName,
    files_changed: filesChanged,
    lines_added:   linesAdded,
    lines_removed: linesRemoved,
    commit_count:  commits.length,
  };
};
