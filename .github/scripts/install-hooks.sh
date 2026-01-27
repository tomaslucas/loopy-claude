#!/usr/bin/env bash
#
# Install git hooks to prevent accidental pushes to main branch
#
# This script installs a pre-push hook that blocks direct pushes to the
# main branch, enforcing the branch protection policy locally.
#
# Usage: ./install-hooks.sh
#
# The hook will:
#   - Block direct pushes to main branch
#   - Allow pushes to feature branches
#   - Provide clear error messages
#
# Exit codes:
#   0 - Hooks installed successfully
#   1 - Not in a git repository
#   2 - Hook installation failed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "Installing git hooks for loopy-claude..."
echo ""

# Verify we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ ERROR: Not in a git repository${NC}"
    exit 1
fi

HOOKS_DIR=".git/hooks"
PRE_PUSH_HOOK="$HOOKS_DIR/pre-push"

# Check if hook already exists
if [ -f "$PRE_PUSH_HOOK" ]; then
    echo -e "${YELLOW}⚠️  Pre-push hook already exists${NC}"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo ""
fi

# Create the pre-push hook
echo "Creating pre-push hook..."
cat > "$PRE_PUSH_HOOK" << 'HOOK_CONTENT'
#!/usr/bin/env bash
#
# Pre-push hook to prevent direct pushes to main branch
#
# This hook enforces the branch protection policy locally by blocking
# direct pushes to the main branch. All changes to main must go through
# pull requests.

# Read stdin (format: <local ref> <local sha> <remote ref> <remote sha>)
while read local_ref local_sha remote_ref remote_sha; do
    # Check if pushing to main branch
    if [[ "$remote_ref" == "refs/heads/main" ]]; then
        echo ""
        echo "❌ BLOCKED: Direct push to main branch is not allowed"
        echo ""
        echo "The main branch is protected. All changes must go through pull requests."
        echo ""
        echo "To make changes:"
        echo "  1. Create a feature branch:"
        echo "     git checkout -b feature/your-feature-name"
        echo ""
        echo "  2. Make your changes and commit them"
        echo ""
        echo "  3. Push your feature branch:"
        echo "     git push -u origin feature/your-feature-name"
        echo ""
        echo "  4. Create a pull request on GitHub"
        echo ""
        echo "If you need to bypass this hook (NOT RECOMMENDED):"
        echo "  git push --no-verify"
        echo ""
        exit 1
    fi
done

exit 0
HOOK_CONTENT

# Make hook executable
chmod +x "$PRE_PUSH_HOOK"

echo -e "${GREEN}✅ Pre-push hook installed successfully${NC}"
echo ""

# Test the hook
echo "Testing the hook..."
echo ""

# Create a test by checking current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${YELLOW}⚠️  You are currently on the main branch${NC}"
    echo ""
    echo "The hook will prevent you from pushing directly to main."
    echo "To test it, try: git push origin main"
    echo ""
    echo "To work on a feature branch:"
    echo "  git checkout -b feature/test-branch"
else
    echo -e "${GREEN}✅ You are on branch: $CURRENT_BRANCH${NC}"
    echo ""
    echo "You can safely push this branch: git push origin $CURRENT_BRANCH"
fi

echo ""
echo "========================================"
echo -e "${BLUE}Hook Installation Complete${NC}"
echo ""
echo "The pre-push hook will now:"
echo "  ✓ Block direct pushes to main"
echo "  ✓ Allow pushes to feature branches"
echo "  ✓ Provide helpful error messages"
echo ""
echo "This is a local safety net. The main protection is GitHub's"
echo "branch protection rules, which you should also configure."
echo ""
echo "See .github/SECURITY_CHECKLIST.md for full security setup."

exit 0
