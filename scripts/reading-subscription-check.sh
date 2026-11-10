#!/bin/bash
set -euo pipefail
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
# The ASC auth gem is bundled with Homebrew Fastlane, not the system Ruby.
export GEM_PATH="$(brew --prefix fastlane)/libexec${GEM_PATH:+:$GEM_PATH}"
export BUNDLE_ID=com.shawncarpenter.bibleai-companion ASC_APP_ID=6756225286 REQUIRE_SUB=1
exec ruby "$HOME/projects/fastlane-configs/scripts/check_subscription_state.rb"
