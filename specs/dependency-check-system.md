# Dependency Check System

> Pre-flight validation of required tools before loop execution

## Status: Draft

---

## 1. Overview

### Purpose

loop.sh has implicit dependencies (jq, git, awk) that cause cryptic failures when missing. This system adds explicit dependency checking at startup with clear error messages and graceful degradation where possible.

### Goals

- Fail fast with clear messages when critical dependencies missing
- Warn (but continue) for optional dependencies
- Single check at loop start (not per-iteration)
- Cross-platform compatibility (Linux, macOS, WSL)
- Suggest installation commands per platform

### Non-Goals

- Version checking (just existence)
- Auto-installation of dependencies
- Runtime dependency management
- Package manager abstraction

---

## 2. Architecture

### Flow

```
./loop.sh [mode] [args]
    ↓
check_dependencies()
    ↓
For each REQUIRED dependency:
  - command -v {tool} → found? continue : error + exit
    ↓
For each OPTIONAL dependency:
  - command -v {tool} → found? continue : warn + note degradation
    ↓
Continue to normal execution
```

### Dependency Classification

| Tool | Type | Used For | Degradation if Missing |
|------|------|----------|----------------------|
| git | REQUIRED | Version control, push, branch | Cannot run |
| awk | REQUIRED | Frontmatter filtering | Cannot run |
| jq | OPTIONAL | Config parsing, JSON rate-limit | Fall back to grep/defaults |
| tee | REQUIRED | Logging | Cannot run |
| grep | REQUIRED | Pattern matching | Cannot run |

### Components

```
loop.sh
├── NEW: check_dependencies() function
├── NEW: detect_platform() function  
├── NEW: suggest_install() function
└── Call check_dependencies() early in script
```

---

## 3. Implementation Details

### 3.1 Dependency Check Function

```bash
check_dependencies() {
    local missing_required=()
    local missing_optional=()
    
    # Required dependencies
    for cmd in git awk tee grep; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_required+=("$cmd")
        fi
    done
    
    # Optional dependencies
    for cmd in jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_optional+=("$cmd")
        fi
    done
    
    # Report missing required
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies:"
        for cmd in "${missing_required[@]}"; do
            echo "  - $cmd"
            suggest_install "$cmd"
        done
        exit 3
    fi
    
    # Warn about missing optional
    if [ ${#missing_optional[@]} -gt 0 ]; then
        echo "Warning: Missing optional dependencies:"
        for cmd in "${missing_optional[@]}"; do
            echo "  - $cmd (will use fallback)"
            suggest_install "$cmd"
        done
        echo ""
    fi
}
```

### 3.2 Platform Detection

```bash
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/debian_version ]; then
                echo "debian"
            elif [ -f /etc/redhat-release ]; then
                echo "redhat"
            elif [ -f /etc/arch-release ]; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}
```

### 3.3 Installation Suggestions

```bash
suggest_install() {
    local cmd="$1"
    local platform=$(detect_platform)
    
    case "$cmd" in
        jq)
            case "$platform" in
                debian) echo "    Install: sudo apt install jq" ;;
                redhat) echo "    Install: sudo dnf install jq" ;;
                arch)   echo "    Install: sudo pacman -S jq" ;;
                macos)  echo "    Install: brew install jq" ;;
                *)      echo "    Install: https://stedolan.github.io/jq/download/" ;;
            esac
            ;;
        git)
            case "$platform" in
                debian) echo "    Install: sudo apt install git" ;;
                redhat) echo "    Install: sudo dnf install git" ;;
                arch)   echo "    Install: sudo pacman -S git" ;;
                macos)  echo "    Install: xcode-select --install" ;;
                *)      echo "    Install: https://git-scm.com/downloads" ;;
            esac
            ;;
        awk)
            case "$platform" in
                debian) echo "    Install: sudo apt install gawk" ;;
                redhat) echo "    Install: sudo dnf install gawk" ;;
                macos)  echo "    Note: awk is pre-installed on macOS" ;;
                *)      echo "    Install: Check your package manager for gawk" ;;
            esac
            ;;
        *)
            echo "    Install: Check your package manager"
            ;;
    esac
}
```

### 3.4 jq Fallback Mode

When jq is missing, degrade gracefully:

**Config parsing fallback:**
```bash
# Instead of: jq -r '.default' loopy.config.json
# Use: grep + sed (less robust but functional)
grep '"default"' loopy.config.json | sed 's/.*: *"\([^"]*\)".*/\1/'
```

**Rate limit detection fallback:**
```bash
# Instead of: jq -e 'select(.error.type == "rate_limit_error")'
# Use: grep pattern matching
grep -qE 'rate_limit_error|overloaded_error|quota.*exhausted'
```

Set a flag when jq is missing:
```bash
JQ_AVAILABLE=true
command -v jq &>/dev/null || JQ_AVAILABLE=false
```

Then use conditional logic in functions that need jq.

### 3.5 Integration Point

Add check early in loop.sh, after variable initialization but before any operations:

```bash
# (after parsing arguments, before mode validation)

# Check dependencies
check_dependencies

# Continue with normal flow...
```

---

## 4. API / Interface

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User abort / invalid arguments |
| 2 | Source validation failed (existing) |
| 3 | **NEW: Dependency check failed** |
| 4 | Destination error (existing) |

### Environment Variables

None new. Dependency check is automatic.

### Flags

None new. Dependency check always runs.

---

## 5. Testing Strategy

### Manual Tests

1. **All dependencies present:**
   - Run `./loop.sh --help`
   - Verify no warnings, normal output

2. **Missing jq (optional):**
   - Temporarily: `sudo mv /usr/bin/jq /usr/bin/jq.bak`
   - Run `./loop.sh build`
   - Verify warning shown but execution continues
   - Verify fallback behavior works
   - Restore: `sudo mv /usr/bin/jq.bak /usr/bin/jq`

3. **Missing git (required):**
   - In a container without git
   - Run `./loop.sh build`
   - Verify error message with install suggestion
   - Verify exit code 3

4. **Platform detection:**
   - Test on Linux, macOS (if available)
   - Verify correct install suggestions

---

## 6. Acceptance Criteria

- [ ] check_dependencies() function exists
- [ ] Required dependencies checked: git, awk, tee, grep
- [ ] Optional dependencies checked: jq
- [ ] Missing required → exit 3 with clear message
- [ ] Missing optional → warning + continue
- [ ] Platform-specific install suggestions shown
- [ ] jq fallback mode works for config parsing
- [ ] jq fallback mode works for rate limit detection
- [ ] Check runs once at startup (not per-iteration)

---

## 7. Implementation Guidance

### Impact Analysis

**Change Type:** [x] Enhancement

**Affected Areas:**

Files to modify:
- `loop.sh` (~80 lines: new functions + integration)
- `specs/README.md` (add entry)

### Verification Strategy

```bash
# Verify dependency check runs
./loop.sh --help 2>&1  # Should not error

# Verify jq fallback (simulate missing jq)
JQ_AVAILABLE=false ./loop.sh build 2>&1 | head -20

# Verify exit code on missing required
# (would need container/VM to safely test)
```

---

## 8. Notes

### Why Not Version Checking?

Version differences rarely cause issues for our use cases:
- jq 1.5 vs 1.6: Compatible for our filters
- git 2.x: All versions we'd encounter work
- awk: POSIX awk sufficient, gawk not required

Adding version checks adds complexity without proportional value.

### Why Warn Instead of Fail for jq?

jq is used for:
1. Config parsing (can fall back to grep/sed)
2. Rate limit JSON detection (can fall back to regex)

Both have viable fallbacks. Blocking users who don't have jq installed would be overly restrictive.

### Performance Impact

`command -v` is extremely fast (<1ms per check). Total overhead: <10ms at startup. Negligible.

---

**Related specs:**
- `loop-orchestrator-system.md` — Modified to add checks
- `cli-agnostic-system.md` — Config parsing affected by jq fallback
