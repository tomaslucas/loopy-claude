#!/usr/bin/env bash
#
# Scan for potential secrets and credentials in the repository
#
# This script searches for common patterns that might indicate exposed secrets:
#   - API keys and tokens
#   - Passwords and credentials
#   - Private keys
#   - AWS/GCP/Azure credentials
#   - Email addresses (to verify no personal info leaked)
#
# Usage: ./verify-no-secrets.sh
#
# Exit codes:
#   0 - No critical issues found
#   1 - Potential secrets detected
#   2 - Script error

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "Scanning repository for potential secrets..."
echo "Repository: $REPO_ROOT"
echo ""

# Verify we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ ERROR: Not in a git repository${NC}"
    exit 2
fi

# Track issues
CRITICAL_ISSUES=0
WARNINGS=0

# Get list of git-tracked files (excludes everything in .gitignore)
# This ensures we only scan files that would be committed
GIT_FILES=$(git ls-files)

# Additional patterns to exclude from content scanning
EXCLUDE_FROM_CONTENT=(
    ".github/scripts/verify-no-secrets.sh"  # This file contains search patterns
    ".gitignore"  # Contains pattern examples
)

# Function to check if file should be excluded from content scan
should_exclude_from_content() {
    local file="$1"
    for pattern in "${EXCLUDE_FROM_CONTENT[@]}"; do
        if [[ "$file" == "$pattern" ]]; then
            return 0  # true, should exclude
        fi
    done
    return 1  # false, should not exclude
}

# 1. Check for API keys and tokens
echo "[1/7] Checking for API keys and tokens..."
FOUND=false
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi
    if [[ "$file" == *.md ]]; then continue; fi  # Skip markdown files

    if grep -Ei 'api[_-]?key[[:space:]]*=|api[_-]?token[[:space:]]*=|access[_-]?token[[:space:]]*=|auth[_-]?token[[:space:]]*=' "$file" 2>/dev/null | \
       grep -v "ANTHROPIC_API_KEY" | grep -v "your-api-key" | grep -v "YOUR_API_KEY" | grep -q .; then
        echo "  Found in: $file"
        FOUND=true
    fi
done <<< "$GIT_FILES"

if [ "$FOUND" = true ]; then
    echo -e "${RED}❌ Potential API keys found${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
else
    echo -e "${GREEN}✅ No API keys detected${NC}"
fi

# 2. Check for password patterns
echo ""
echo "[2/7] Checking for passwords..."
FOUND=false
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi
    if [[ "$file" == *.md ]]; then continue; fi

    if grep -Ei 'password[[:space:]]*=|passwd[[:space:]]*=|pwd[[:space:]]*=' "$file" 2>/dev/null | \
       grep -v "password_here" | grep -v "your_password" | grep -v "PASSWORD" | grep -q .; then
        echo "  Found in: $file"
        FOUND=true
    fi
done <<< "$GIT_FILES"

if [ "$FOUND" = true ]; then
    echo -e "${RED}❌ Potential passwords found${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
else
    echo -e "${GREEN}✅ No passwords detected${NC}"
fi

# 3. Check for private keys
echo ""
echo "[3/7] Checking for private keys..."
FOUND=false
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi

    if grep -Ei 'BEGIN.*PRIVATE KEY|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY' "$file" 2>/dev/null | grep -q .; then
        echo "  Found in: $file"
        FOUND=true
    fi
done <<< "$GIT_FILES"

if [ "$FOUND" = true ]; then
    echo -e "${RED}❌ Private keys found${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
else
    echo -e "${GREEN}✅ No private keys detected${NC}"
fi

# 4. Check for AWS credentials
echo ""
echo "[4/7] Checking for AWS credentials..."
FOUND=false
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi
    if [[ "$file" == *.md ]]; then continue; fi

    if grep -Ei 'AKIA[0-9A-Z]{16}|aws[_-]?secret[_-]?access[_-]?key' "$file" 2>/dev/null | \
       grep -v "AKIAIOSFODNN7EXAMPLE" | grep -q .; then
        echo "  Found in: $file"
        FOUND=true
    fi
done <<< "$GIT_FILES"

if [ "$FOUND" = true ]; then
    echo -e "${RED}❌ Potential AWS credentials found${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
else
    echo -e "${GREEN}✅ No AWS credentials detected${NC}"
fi

# 5. Check for GCP credentials
echo ""
echo "[5/7] Checking for GCP credentials..."
FOUND=false
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi
    if [[ "$file" == *.md ]]; then continue; fi

    if grep -Ei '"type"[[:space:]]*:[[:space:]]*"service_account"|"private_key_id"' "$file" 2>/dev/null | grep -q .; then
        echo "  Found in: $file"
        FOUND=true
    fi
done <<< "$GIT_FILES"

if [ "$FOUND" = true ]; then
    echo -e "${RED}❌ Potential GCP service account keys found${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
else
    echo -e "${GREEN}✅ No GCP credentials detected${NC}"
fi

# 6. Check for secrets in git history
echo ""
echo "[6/7] Checking git history for secrets..."
# Look for actual credential patterns in git history (not just the words)
if git log --all --pretty=format: -p | grep -Ei 'api[_-]?key[[:space:]]*=[[:space:]]*["\047][a-zA-Z0-9_-]{20,}|password[[:space:]]*=[[:space:]]*["\047][^"\047]{8,}' | \
    head -n 5 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}⚠️  Potential secrets in git history${NC}"
    echo "    (Note: Review git history manually for actual credentials)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ No obvious secrets in git history${NC}"
fi

# 7. Check for personal email addresses in tracked files (excluding public GitHub ones)
echo ""
echo "[7/7] Checking for personal email addresses in tracked files..."
EMAILS=""
while IFS= read -r file; do
    if should_exclude_from_content "$file"; then continue; fi
    if [[ "$file" == *.md ]] || [[ "$file" == "LICENSE" ]]; then continue; fi

    FILE_EMAILS=$(grep -Eo '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null | \
        grep -v "@users.noreply.github.com" | \
        grep -v "@anthropic.com" | \
        grep -v "noreply@" || true)

    if [ -n "$FILE_EMAILS" ]; then
        EMAILS+="$file: $FILE_EMAILS"$'\n'
    fi
done <<< "$GIT_FILES"

if [ -n "$EMAILS" ]; then
    echo -e "${YELLOW}⚠️  Email addresses found in tracked files:${NC}"
    echo "$EMAILS"
    echo "    (Verify these are intentional)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ No personal email addresses detected in tracked files${NC}"
fi

# Summary
echo ""
echo "========================================"
echo "Scan Results:"
echo "  Critical Issues: $CRITICAL_ISSUES"
echo "  Warnings: $WARNINGS"
echo ""

if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo -e "${RED}❌ FAIL: Critical security issues found${NC}"
    echo ""
    echo "DO NOT make this repository public until these are resolved!"
    echo ""
    echo "Steps to fix:"
    echo "  1. Remove the sensitive data from files"
    echo "  2. If in git history, use git-filter-repo or BFG Repo-Cleaner"
    echo "  3. Rotate any exposed credentials immediately"
    echo "  4. Run this script again to verify"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  PASS with warnings${NC}"
    echo ""
    echo "No critical issues found, but review warnings above."
    echo "Warnings are often false positives (documentation, examples)."
    exit 0
else
    echo -e "${GREEN}✅ PASS: No critical security issues found${NC}"
    echo ""
    echo "Repository appears safe to make public."
    echo ""
    echo "Final manual checks:"
    echo "  • Review .gitignore completeness"
    echo "  • Verify no .env files are tracked"
    echo "  • Check that logs/ and .claude/sessions/ are excluded"
    exit 0
fi
