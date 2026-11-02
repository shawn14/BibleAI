#!/bin/bash
# Reviewed source publication only. No native archive, upload, App Store write or pricing change.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI check_growth_publication or publish_growth'; exit 1; }
mode=${1:---check}
[[ "$mode" == --check || "$mode" == --publish ]] || exit 2
repo=shawn14/BibleAI
branch=codex/bright-scroll-growth
tested=bcc48933eecf0ed91256deabfed45bdfea50fcb3
[[ "$(git remote get-url origin)" == https://github.com/shawn14/BibleAI.git ]] || { echo 'Wrong repository'; exit 1; }
[[ "$(git branch --show-current)" == "$branch" && -z "$(git status --porcelain)" ]] || { echo 'Require clean reviewed growth branch'; exit 1; }
git fetch --no-tags origin main
for source in origin/main c63c68d 2841df3 "$tested"; do
  git merge-base --is-ancestor "$source" HEAD || { echo "Source ancestry mismatch: $source"; exit 1; }
done
# Documentation/publication wiring may advance; native inputs must remain exactly the reviewed candidate.
git diff --quiet "$tested" HEAD -- BibleAI BibleAI.xcodeproj BibleAIUITests Podfile Podfile.lock || { echo 'Native input changed since reviewed growth run'; exit 1; }
head=$(git rev-parse HEAD)
printf 'Reviewed native source %s; publication source %s; current main %s\n' "$tested" "$head" "$(git rev-parse origin/main)"
[[ "$mode" == --publish ]] || { echo 'CHECK PASSED; no GitHub writes'; exit 0; }
git push --set-upstream origin "HEAD:refs/heads/$branch"
pr=$(gh pr list --repo "$repo" --head "$branch" --base main --state open --json number --jq '.[0].number // empty')
if [[ -z "$pr" ]]; then
  gh pr create --repo "$repo" --head "$branch" --base main --title 'Add Bright Scroll verse sharing and reading invitations' --body-file docs/growth/PR.md
  pr=$(gh pr list --repo "$repo" --head "$branch" --base main --state open --json number --jq '.[0].number // empty')
fi
[[ -n "$pr" && "$(gh pr view "$pr" --repo "$repo" --json headRefOid --jq .headRefOid)" == "$head" ]] || { echo 'PR source mismatch'; exit 1; }
gh pr merge "$pr" --repo "$repo" --merge --match-head-commit "$head"
[[ -n "$(gh pr view "$pr" --repo "$repo" --json mergedAt --jq '.mergedAt // empty')" ]] || { echo 'PR is not merged'; exit 1; }
git fetch --no-tags origin main
git merge-base --is-ancestor "$head" origin/main
# Finish on clean, current main so a later separately approved native release has one source of truth.
git switch main
git pull --ff-only origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" && -z "$(git status --porcelain)" ]]
printf 'PUBLISHED main %s; reviewed source %s preserved\n' "$(git rev-parse HEAD)" "$head"
