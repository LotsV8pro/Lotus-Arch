#!/bin/bash
# Quick re-sync: deploy ONLY the dotfiles (Phase 6) with the same logic as
# the full installer. Use after editing configs in the repo.
#   bash tools/deploy-dotfiles.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/../install-scripts/06-dotfiles.sh"
