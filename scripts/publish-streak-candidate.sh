#!/bin/bash
# Publish exactly the signed-off candidate so the canonical archive can run on main.
set -euo pipefail
cd "$(dirname "$0")/.."
branch=codex/streak-listing
repo=shawn14/BibleAI
[[ "$(git branch --show-current)" == "$branch" && -z "$(git status --porcelain)" ]]
[[ "$(git remote get-url origin)" == "https://github.com/$repo.git" ]]
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
git merge-base --is-ancestor 57c7e65 HEAD
head=$(git rev-parse HEAD)
signoff=docs/testing/build11-qa-signoff.md
test -s "$signoff"
ci=$(sed -n 's/^CI run \([0-9][0-9]*\)$/\1/p' "$signoff")
test -n "$ci"
cihead=$(gh api "repos/$repo/actions/runs/$ci" --jq 'select(.conclusion=="success" and .name=="BibleAI release journeys")|.head_sha')
test -n "$cihead"
git diff --exit-code "$cihead" "$head" -- BibleAI BibleAIUITests BibleAI.xcodeproj BibleAI.xcworkspace Podfile Podfile.lock .github/workflows
digest=$(git ls-tree -r "$head" -- BibleAI BibleAIUITests BibleAI.xcodeproj BibleAI.xcworkspace Podfile Podfile.lock .github/workflows | shasum -a 256 | awk '{print $1}')
git push origin "HEAD:refs/heads/$branch" "HEAD:refs/heads/release-proof/$digest"
pr=$(gh pr list --head "$branch" --base main --repo "$repo" --json number --jq '.[0].number // empty')
if [[ -z "$pr" ]]; then
  gh pr create --repo "$repo" --head "$branch" --base main --title 'Prepare BibleAI 2.0.3 with streak tracking and reading plan screenshots' --body-file "$signoff"
  pr=$(gh pr list --head "$branch" --base main --repo "$repo" --json number --jq '.[0].number')
fi
test "$(gh pr view "$pr" --repo "$repo" --json headRefOid --jq .headRefOid)" = "$head"
gh pr merge "$pr" --repo "$repo" --merge --match-head-commit "$head"
git fetch origin main
git merge-base --is-ancestor "$head" origin/main
git switch main
git merge --ff-only origin/main
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)"
