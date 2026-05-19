#!/usr/bin/env bash

# Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
# Licensed under the Business Source License 1.1 (BUSL-1.1).
# See the LICENSE file in the project root for details.

# Exit on error
set -e

HOOK_PATH=".git/hooks/pre-commit"

echo "Installing local git pre-commit safety hook..."

# Ensure the .git/hooks directory exists
mkdir -p .git/hooks

# Write pre-commit hook code
cat << 'EOF' > "$HOOK_PATH"
#!/usr/bin/env bash

# Get the name of the current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

# Define protected branches list
PROTECTED_BRANCHES=("master" "dev")

for BRANCH in "${PROTECTED_BRANCHES[@]}"; do
    if [ "$CURRENT_BRANCH" = "$BRANCH" ]; then
        echo -e "\033[1;31m[ERROR] Direct commits to the '$CURRENT_BRANCH' branch are prohibited by SarvMD Git Flow!\033[0m"
        echo -e "\033[33mPlease branch off to a 'feature/*', 'bugfix/*', or 'hotfix/*' branch to make changes:\033[0m"
        echo -e "  git checkout -b feature/your-feature-name"
        exit 1
    fi
done

exit 0
EOF

# Make hook executable
chmod +x "$HOOK_PATH"

echo -e "\033[1;32m[SUCCESS] Local pre-commit guard hook installed successfully!\033[0m"
echo "It will now block accidental commits directly on the 'master' and 'dev' branches."
