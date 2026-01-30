#!/usr/bin/env bash
# tests/e2e/copilot-hooks-verify.sh - VDD verification for Copilot hooks system
# Purpose: Test that copilot-adapter.sh correctly translates Copilot ↔ Claude formats
# Expected: FAILS until hooks/adapters/copilot-adapter.sh is properly implemented

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADAPTER="$PROJECT_ROOT/hooks/adapters/copilot-adapter.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Test helper
test_case() {
    local name="$1"
    echo -e "\n${YELLOW}TEST:${NC} $name"
}

assert_success() {
    local cmd="$1"
    local description="$2"
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

assert_fail() {
    local cmd="$1"
    local description="$2"
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} $description (expected to fail but passed)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    else
        echo -e "${GREEN}✓${NC} $description"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    fi
}

assert_output_contains() {
    local cmd="$1"
    local pattern="$2"
    local description="$3"
    
    local output
    output=$(eval "$cmd" 2>&1 || true)
    
    if echo "$output" | grep -q "$pattern"; then
        echo -e "${GREEN}✓${NC} $description"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "  Expected pattern: $pattern"
        echo "  Got: $output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Summary
summary() {
    echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Test Results: ${GREEN}$PASS_COUNT passed${NC}, ${RED}$FAIL_COUNT failed${NC}"
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Copilot Hooks System - VDD Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: Adapter exists and is executable
test_case "Adapter Prerequisites"
assert_success "[ -f '$ADAPTER' ]" "Adapter file exists"
assert_success "[ -x '$ADAPTER' ]" "Adapter is executable"

# Test 2: Dangerous command blocked (rm -rf)
test_case "Security: Dangerous rm -rf blocked"
DANGEROUS_INPUT='{"timestamp":1704614600000,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"rm -rf /important\"}"}'
assert_output_contains "echo '$DANGEROUS_INPUT' | '$ADAPTER' preToolUse" '"permissionDecision"\s*:\s*"deny"' "Returns deny JSON"
assert_output_contains "echo '$DANGEROUS_INPUT' | '$ADAPTER' preToolUse" 'BLOCKED' "Contains BLOCKED message"
assert_success "echo '$DANGEROUS_INPUT' | '$ADAPTER' preToolUse >/dev/null 2>&1; [ \$? -eq 0 ]" "Exits with code 0 (Copilot requirement)"

# Test 3: Safe command allowed
test_case "Security: Safe command allowed"
SAFE_INPUT='{"timestamp":1704614600000,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"ls -la\"}"}'
OUTPUT=$(echo "$SAFE_INPUT" | "$ADAPTER" preToolUse 2>&1 || true)
if [[ -z "$OUTPUT" ]] || ! echo "$OUTPUT" | grep -q '"permissionDecision"\s*:\s*"deny"'; then
    echo -e "${GREEN}✓${NC} Safe command produces no deny output"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "${RED}✗${NC} Safe command incorrectly blocked"
    echo "  Output: $OUTPUT"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
assert_success "echo '$SAFE_INPUT' | '$ADAPTER' preToolUse >/dev/null 2>&1; [ \$? -eq 0 ]" "Exits with code 0"

# Test 4: Force push blocked
test_case "Security: git push --force blocked"
FORCE_PUSH_INPUT='{"timestamp":1704614600000,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"git push --force origin main\"}"}'
assert_output_contains "echo '$FORCE_PUSH_INPUT' | '$ADAPTER' preToolUse" '"permissionDecision"\s*:\s*"deny"' "Returns deny JSON"
assert_output_contains "echo '$FORCE_PUSH_INPUT' | '$ADAPTER' preToolUse" 'BLOCKED' "Contains BLOCKED message"

# Test 5: .env file access blocked
test_case "Security: .env file access blocked"
ENV_FILE_INPUT='{"timestamp":1704614600000,"cwd":"/tmp","toolName":"read","toolArgs":"{\"path\":\".env\"}"}'
assert_output_contains "echo '$ENV_FILE_INPUT' | '$ADAPTER' preToolUse" '"permissionDecision"\s*:\s*"deny"' "Returns deny JSON for .env"
assert_output_contains "echo '$ENV_FILE_INPUT' | '$ADAPTER' preToolUse" 'BLOCKED' "Contains BLOCKED message"

# Test 6: postToolUse logging
test_case "Telemetry: postToolUse logging"
POST_INPUT='{"timestamp":1704614700000,"cwd":"/tmp","toolName":"bash","toolArgs":"{}","toolResult":{"resultType":"success","textResultForLlm":"Test output"}}'
LOG_FILE="$PROJECT_ROOT/logs/session-events.jsonl"

# Clear or note previous log size
if [[ -f "$LOG_FILE" ]]; then
    BEFORE_LINES=$(wc -l < "$LOG_FILE" || echo "0")
else
    BEFORE_LINES=0
fi

# Execute postToolUse
echo "$POST_INPUT" | "$ADAPTER" postToolUse >/dev/null 2>&1 || true

# Check log was written
if [[ -f "$LOG_FILE" ]]; then
    AFTER_LINES=$(wc -l < "$LOG_FILE" || echo "0")
    if [[ $AFTER_LINES -gt $BEFORE_LINES ]]; then
        echo -e "${GREEN}✓${NC} Log entry was written"
        PASS_COUNT=$((PASS_COUNT + 1))
        
        # Check log contains copilot agent
        if tail -1 "$LOG_FILE" | grep -q '"agent"\s*:\s*"copilot"'; then
            echo -e "${GREEN}✓${NC} Log contains agent=copilot"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo -e "${RED}✗${NC} Log missing agent=copilot"
            echo "  Last line: $(tail -1 "$LOG_FILE")"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        echo -e "${RED}✗${NC} No new log entry written"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo -e "${RED}✗${NC} Log file not created"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 7: Invalid hook type error
test_case "Error Handling: Invalid hook type"
assert_fail "'$ADAPTER' invalidHookType < /dev/null" "Invalid hook type exits non-zero"
assert_output_contains "'$ADAPTER' invalidHookType 2>&1 < /dev/null || true" "Unknown hook type" "Shows error message"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

summary
