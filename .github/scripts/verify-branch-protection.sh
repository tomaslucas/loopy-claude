#!/usr/bin/env bash
#
# Verify GitHub branch protection settings for the main branch
#
# This script checks that critical branch protection rules are configured
# via the GitHub API using the gh CLI tool.
#
# Usage: ./verify-branch-protection.sh
#
# Requirements:
#   - gh CLI installed and authenticated
#   - Repository must be public or you must have appropriate permissions
#
# Exit codes:
#   0 - All critical protections are configured
#   1 - Missing or misconfigured protections
#   2 - Script error (gh not installed, not authenticated, etc.)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository details
REPO_OWNER="tomaslucas"
REPO_NAME="loopy-claude"
BRANCH="main"

echo "Verifying branch protection for ${REPO_OWNER}/${REPO_NAME}:${BRANCH}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ ERROR: gh CLI is not installed${NC}"
    echo "Install from: https://cli.github.com/"
    exit 2
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ ERROR: Not authenticated with GitHub${NC}"
    echo "Run: gh auth login"
    exit 2
fi

# Fetch branch protection settings
echo "Fetching branch protection settings..."
if ! PROTECTION=$(gh api "repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" 2>&1); then
    if echo "$PROTECTION" | grep -q "Branch not protected"; then
        echo -e "${RED}❌ CRITICAL: Branch '${BRANCH}' has NO protection rules configured${NC}"
        echo ""
        echo "Configure branch protection at:"
        echo "https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
        exit 1
    else
        echo -e "${RED}❌ ERROR: Failed to fetch branch protection settings${NC}"
        echo "$PROTECTION"
        exit 2
    fi
fi

echo -e "${GREEN}✅ Branch protection is enabled${NC}"
echo ""

# Track overall status
ALL_CHECKS_PASSED=true

# Check required pull request reviews
echo "Checking required pull request reviews..."
if echo "$PROTECTION" | jq -e '.required_pull_request_reviews' > /dev/null; then
    REQUIRED_APPROVALS=$(echo "$PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count')
    echo -e "${GREEN}✅ Required PR reviews: ${REQUIRED_APPROVALS} approval(s)${NC}"

    DISMISS_STALE=$(echo "$PROTECTION" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews')
    if [ "$DISMISS_STALE" = "true" ]; then
        echo -e "${GREEN}✅ Dismiss stale reviews: enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Dismiss stale reviews: disabled (recommended: enable)${NC}"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}❌ CRITICAL: Required PR reviews not configured${NC}"
    ALL_CHECKS_PASSED=false
fi

# Check restrictions (push access)
echo ""
echo "Checking push restrictions..."
if echo "$PROTECTION" | jq -e '.restrictions' > /dev/null; then
    if [ "$(echo "$PROTECTION" | jq -r '.restrictions')" = "null" ]; then
        echo -e "${YELLOW}⚠️  No push restrictions (anyone with write access can push)${NC}"
    else
        echo -e "${GREEN}✅ Push restrictions: configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Push restrictions: not configured${NC}"
fi

# Check enforce admins
echo ""
echo "Checking admin enforcement..."
ENFORCE_ADMINS=$(echo "$PROTECTION" | jq -r '.enforce_admins.enabled')
if [ "$ENFORCE_ADMINS" = "true" ]; then
    echo -e "${GREEN}✅ Enforce rules for admins: enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Enforce rules for admins: disabled (recommended: enable)${NC}"
    ALL_CHECKS_PASSED=false
fi

# Check required linear history
echo ""
echo "Checking linear history requirement..."
REQUIRED_LINEAR=$(echo "$PROTECTION" | jq -r '.required_linear_history.enabled')
if [ "$REQUIRED_LINEAR" = "true" ]; then
    echo -e "${GREEN}✅ Required linear history: enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Required linear history: disabled (recommended: enable)${NC}"
fi

# Check allow force pushes
echo ""
echo "Checking force push protection..."
ALLOW_FORCE=$(echo "$PROTECTION" | jq -r '.allow_force_pushes.enabled')
if [ "$ALLOW_FORCE" = "false" ]; then
    echo -e "${GREEN}✅ Block force pushes: enabled${NC}"
else
    echo -e "${RED}❌ CRITICAL: Force pushes are ALLOWED${NC}"
    ALL_CHECKS_PASSED=false
fi

# Check allow deletions
echo ""
echo "Checking deletion protection..."
ALLOW_DELETE=$(echo "$PROTECTION" | jq -r '.allow_deletions.enabled')
if [ "$ALLOW_DELETE" = "false" ]; then
    echo -e "${GREEN}✅ Block branch deletion: enabled${NC}"
else
    echo -e "${RED}❌ CRITICAL: Branch deletion is ALLOWED${NC}"
    ALL_CHECKS_PASSED=false
fi

# Summary
echo ""
echo "========================================"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✅ PASS: All critical branch protections are configured${NC}"
    echo ""
    echo "Your main branch is protected against:"
    echo "  • Direct pushes (requires PR)"
    echo "  • Force pushes"
    echo "  • Branch deletion"
    echo "  • Admin bypass"
    exit 0
else
    echo -e "${RED}❌ FAIL: Some critical protections are missing or misconfigured${NC}"
    echo ""
    echo "Review and fix issues at:"
    echo "https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/branches"
    exit 1
fi
