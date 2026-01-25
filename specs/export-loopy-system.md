# Export Loopy System

> Bash script to export loopy-claude components to new or existing projects with preset configurations and conflict management

## Status: Draft

---

## 1. Overview

### Purpose

Enable developers to reuse loopy-claude components (loop.sh, prompts, skills, templates) in other projects by providing a simple export script with preset configurations, interactive destination selection, and safe conflict handling.

### Goals

- Export components via preset configurations (starting with "full")
- Interactive destination directory selection
- Safe conflict resolution (ask before overwriting)
- Dependency verification (claude CLI presence check)
- Generate quick-start documentation (README-LOOPY.md)
- Dry-run mode for preview without copying
- Support flexible source location (--source flag)
- Merge .gitignore entries with existing files
- Maintain file permissions (executable scripts stay executable)
- Summary log of exported components

### Non-Goals

- Initializing git repositories (user decides)
- Installing dependencies (only verify claude CLI exists)
- Executing loop.sh automatically after export
- Modifying Claude Code configuration (.claude/config.json)
- Multi-project batch export
- Template customization during export
- Automatic git commits in destination
- Cross-platform path transformation (Windows support)

---

## 2. Architecture

### Components

```
export-loopy.sh (main script)
├── Argument parsing
│   ├── Preset selection (full, minimal, design, devtools)
│   ├── --source flag (optional origin path)
│   └── --dry-run flag (preview mode)
├── Source validation
│   └── Verify loopy-claude directory structure
├── Dependency checks
│   └── Verify claude CLI installed
├── Destination prompt (interactive)
│   └── Ask user where to export
├── Preset definitions
│   └── File lists per preset
├── Conflict resolution
│   ├── Detect existing files
│   ├── Ask per conflict: overwrite/skip/rename/abort
│   └── Create backups (.backup.TIMESTAMP)
├── File operations
│   ├── Copy files maintaining structure
│   ├── Create template files (empty with comments)
│   ├── Merge .gitignore entries
│   └── Set executable permissions
├── Template generation
│   ├── specs/README.md (empty PIN structure)
│   ├── plan.md (empty with comment)
│   └── README-LOOPY.md (quick start guide)
└── Summary report
    ├── List exported files
    ├── Show destination path
    └── Next steps instructions
```

### Flow

```
User: ./export-loopy.sh full
    ↓
Parse args (preset=full, check --dry-run, check --source)
    ↓
Validate source (loopy-claude exists at --source or pwd)
    ↓
Check dependencies (claude CLI installed?)
    ↓
Prompt destination directory (interactive)
    ↓
Load preset file list (full → all components)
    ↓
Scan for conflicts (files exist in destination?)
    ↓
    If conflicts → Ask per file (overwrite/skip/rename/abort)
    ↓
Copy files (respecting conflict resolutions)
    ↓
Create templates (specs/README.md, plan.md with comments)
    ↓
Merge .gitignore (append loopy entries if .gitignore exists)
    ↓
Set permissions (chmod +x for .sh files)
    ↓
Generate README-LOOPY.md (quick start guide)
    ↓
Print summary (exported files + next steps)
```

### Dependencies

| Component | Purpose | Location |
|-----------|---------|----------|
| bash | Shell interpreter | System (#!/usr/bin/env bash) |
| claude CLI | Dependency check | System (verified, not installed) |
| Standard Unix tools | cp, mkdir, chmod, cat, grep | System |
| loopy-claude files | Source for export | --source path or pwd |

---

## 3. Implementation Details

### 3.1 Preset Definitions

**Version 1 Presets:**

```bash
# full: Complete loopy-claude system
# Rule: Everything in .claude/ is automatically included
# (commands, agents, skills, future hooks, etc.)
PRESET_FULL=(
  "loop.sh"
  "analyze-session.sh"
  "export-loopy.sh"
  ".claude/"
  ".gitignore"
)
# + Generated templates:
# - specs/README.md (empty PIN)
# - plan.md (empty with comment)
# - logs/ (directory)
# - README-LOOPY.md (quick start)
```

**Rationale for directory-level inclusion:**
- **Simple**: 5 entries instead of listing individual files
- **Maintainable**: No manual updates when adding commands, agents, or skills
- **Future-proof**: Automatically includes hooks and other future additions to .claude/
- **Zero maintenance**: `.claude/` captures everything loopy-claude needs

**Future Presets (not in v1):**

```bash
# minimal: Basic loop system
PRESET_MINIMAL=(loop.sh prompts/ plan.md logs/ .gitignore)

# design: Spec creation only
PRESET_DESIGN=(specs/ .claude/skills/feature-designer/)

# devtools: Scripts without prompts
PRESET_DEVTOOLS=(loop.sh analyze-session.sh)
```

### 3.2 Template Generation

**specs/README.md (empty PIN):**

```markdown
# Project Specifications

Lookup table for specifications.

## How to Use

1. **AI agents:** Study `specs/README.md` before any spec work
2. **Search here** to find relevant existing specs by keyword
3. **When creating new spec:** Add entry here with semantic keywords

---

## Specs

| Spec | Code | Purpose |
|------|------|---------|
| | | |

---

**Last Updated:** {YYYY-MM-DD}
**Project:** {Auto-detect from git or ask user}
```

**plan.md (empty with comment):**

```markdown
# Generated by loop.sh

# This file will be populated when you run:
#   ./loop.sh plan 5

# For first-time usage, see README-LOOPY.md
```

**README-LOOPY.md (quick start guide):**

```markdown
# Loopy-Claude Quick Start

Components exported: {list}
Export date: {timestamp}

## Prerequisites

- Claude CLI installed (`claude --version`)
- Git repository (optional but recommended)

## First Steps

1. Review exported files:
   - `loop.sh` - Main orchestrator
   - `prompts/*.md` - Prompt templates
   - `.claude/skills/feature-designer/` - Interactive spec creator

2. Create your first spec (optional):
   ```bash
   claude
   > /feature-designer
   > [describe your feature]
   > crystallize
   ```

3. Generate implementation plan:
   ```bash
   ./loop.sh plan 5
   ```

4. Review plan.md and execute:
   ```bash
   cat plan.md
   ./loop.sh build 10
   ```

## Modes

- `plan` - Generate tasks from specs
- `build` - Execute tasks with verification
- `reverse` - Analyze legacy code into specs

## Learn More

See loop.sh comments and prompts/*.md for detailed documentation.

---

Exported from loopy-claude: {source_path}
```

### 3.3 Conflict Resolution Strategy

**Detection:**
```bash
for file in "${PRESET_FILES[@]}"; do
  if [ -e "$DEST/$file" ]; then
    # Conflict detected
    ask_user_action "$file"
  fi
done
```

**User Prompt:**
```
File exists: loop.sh
  (o) Overwrite
  (s) Skip this file
  (r) Rename existing to loop.sh.backup.20260124-153045
  (a) Abort export
Choice [o/s/r/a]:
```

**Actions:**
- Overwrite: `cp -f "$SRC/$file" "$DEST/$file"`
- Skip: `continue` to next file
- Rename: `mv "$DEST/$file" "$DEST/$file.backup.$TIMESTAMP" && cp "$SRC/$file" "$DEST/$file"`
- Abort: `exit 1`

### 3.4 .gitignore Merging

```bash
if [ -f "$DEST/.gitignore" ]; then
  # Append loopy entries with separator
  echo "" >> "$DEST/.gitignore"
  echo "# Loopy-Claude entries (added $(date +%Y-%m-%d))" >> "$DEST/.gitignore"
  grep -v "^#" "$SRC/.gitignore" >> "$DEST/.gitignore"
else
  # Copy entire .gitignore
  cp "$SRC/.gitignore" "$DEST/.gitignore"
fi
```

---

## 4. API / Interface

### Command-Line Interface

```bash
# Syntax
./export-loopy.sh <preset> [--source PATH] [--dry-run]

# Examples
./export-loopy.sh full
  → Export everything, prompt for destination, ask on conflicts

./export-loopy.sh full --dry-run
  → Show what would be copied without actually copying

./export-loopy.sh full --source /path/to/loopy-claude
  → Export from specific loopy-claude location

./export-loopy.sh full --source ~/loopy-claude --dry-run
  → Preview export from custom source
```

### Interactive Prompts

**Destination prompt:**
```
Enter destination directory (absolute or relative path): /home/user/my-project
Destination: /home/user/my-project
  Directory exists: yes
  Writable: yes
Proceed? [y/n]:
```

**Conflict prompt:**
```
Conflicts detected:

1. loop.sh already exists
   (o) Overwrite  (s) Skip  (r) Rename existing  (a) Abort
   Choice:

2. prompts/plan.md already exists
   (o) Overwrite  (s) Skip  (r) Rename existing  (a) Abort
   Choice:
```

### Exit Codes

- `0` - Success (all files exported)
- `1` - User aborted or invalid arguments
- `2` - Source validation failed (not a loopy-claude directory)
- `3` - Dependency check failed (claude CLI not found)
- `4` - Destination error (not writable, creation failed)

---

## 5. Testing Strategy

### Manual Testing

**Test 1: Fresh export to empty directory**
```bash
mkdir /tmp/test-fresh
./export-loopy.sh full
# Enter: /tmp/test-fresh
# Verify: All files copied, templates created, permissions correct
```

**Test 2: Export with conflicts**
```bash
mkdir /tmp/test-conflict
touch /tmp/test-conflict/loop.sh
./export-loopy.sh full
# Enter: /tmp/test-conflict
# Test: Choose different conflict resolutions (o/s/r/a)
# Verify: Backups created, originals preserved/overwritten as chosen
```

**Test 3: Dry-run mode**
```bash
./export-loopy.sh full --dry-run
# Verify: No files created, only output showing what would happen
```

**Test 4: Custom source path**
```bash
cd /tmp
./export-loopy.sh full --source ~/code/loopy-claude
# Verify: Exports from specified path, not pwd
```

**Test 5: .gitignore merging**
```bash
mkdir /tmp/test-gitignore
echo "*.pyc" > /tmp/test-gitignore/.gitignore
./export-loopy.sh full
# Enter: /tmp/test-gitignore
# Verify: .gitignore contains both *.pyc and loopy entries
```

### Automated Testing (Future)

Create `test-export.sh`:
```bash
#!/usr/bin/env bash
# Automated test suite for export-loopy.sh

test_fresh_export() {
  DEST=$(mktemp -d)
  ./export-loopy.sh full --source . --dest "$DEST" --non-interactive
  [ -f "$DEST/loop.sh" ] && [ -x "$DEST/loop.sh" ]
  rm -rf "$DEST"
}

# Run all tests
test_fresh_export && echo "✅ Fresh export test passed"
```

---

## 6. Acceptance Criteria

- [ ] User can export "full" preset to any writable directory
- [ ] Script validates source is a loopy-claude directory before proceeding
- [ ] Script verifies claude CLI is installed and warns if missing
- [ ] Destination directory is selected interactively with confirmation
- [ ] Conflicts prompt user with 4 options: overwrite/skip/rename/abort
- [ ] Renamed files include timestamp: `file.backup.20260124-153045`
- [ ] Templates are created empty with helpful comments
- [ ] .gitignore entries are merged if file exists, copied if not
- [ ] Executable permissions are preserved for .sh files
- [ ] README-LOOPY.md is generated with accurate quick-start instructions
- [ ] Summary report lists all exported files and next steps
- [ ] --dry-run shows preview without copying any files
- [ ] --source flag allows specifying loopy-claude location
- [ ] Exit codes correctly indicate success/failure/abort states

---

## 7. Implementation Guidance

> Context for plan generator to create specific, verifiable tasks

### Impact Analysis

**Change Type:** [X] New Feature | [ ] Enhancement | [ ] Refactor

**Affected Areas:**

Search commands used:
- `ls -la` → Root directory files (loop.sh, analyze-session.sh exist)
- `ls -la prompts/` → 3 prompt files (plan.md, build.md, reverse.md)
- `ls -la .claude/skills/` → feature-designer skill exists
- No existing export or installation scripts found

Files/components affected:
- **New file:** `export-loopy.sh` (root directory, ~300-400 lines)
- **Referenced files:** All loopy-claude components (READ-ONLY access)
- **No modifications** to existing files

Integration points:
- Reads from: loop.sh, analyze-session.sh, prompts/, .claude/skills/, .gitignore
- Writes to: User-specified destination directory
- No runtime integration with loop.sh or other components

### Implementation Hints

**Core Implementation:**
- Create export-loopy.sh in root directory
- Use bash functions for modularity (validate_source, prompt_destination, resolve_conflicts, copy_files)
- Implement preset as bash array: `PRESET_FULL=("file1" "file2" ...)`
- Use `set -euo pipefail` for safety
- Interactive prompts use `read -p` with validation loops
- File existence checks: `[ -e "$file" ]`
- Permission setting: `chmod +x "$DEST/"*.sh`

**Template Generation:**
- Create template strings as heredocs (`cat <<'EOF' > file`)
- Substitute variables: {YYYY-MM-DD}, {timestamp}, {source_path}
- Auto-detect project name from git or prompt user

**Conflict Handling:**
- Loop through preset files before copying
- Collect all conflicts first, then prompt (batch mode)
- Store user choices in associative array for processing

**Documentation:**
- Add usage examples to export-loopy.sh header comments
- Update main README.md to mention export-loopy.sh in "Contributing" or "Usage" section
- README-LOOPY.md should be self-contained (no external links needed)

**Testing:**
- Manual testing against fresh directory, existing directory, dry-run
- Test .gitignore merge with existing file
- Test --source flag with absolute and relative paths
- Verify permissions after export (loop.sh should be +x)

### Verification Strategy

How to verify the feature works:

**Command-based verification:**
```bash
# Test 1: Dry-run (no files created)
./export-loopy.sh full --dry-run
# Expected: Output listing files, no actual copies

# Test 2: Fresh export
mkdir /tmp/test-export
./export-loopy.sh full
# Prompt: Enter /tmp/test-export
# Expected: All files copied successfully

# Verify exported structure
ls -la /tmp/test-export/
[ -x /tmp/test-export/loop.sh ] && echo "✅ loop.sh executable"
[ -f /tmp/test-export/prompts/plan.md ] && echo "✅ prompts copied"
[ -f /tmp/test-export/specs/README.md ] && echo "✅ specs template created"
[ -f /tmp/test-export/README-LOOPY.md ] && echo "✅ Quick start created"

# Test 3: Exported system works
cd /tmp/test-export
./loop.sh plan 1
# Expected: Executes without errors (may have empty specs warning)
```

**Manual checks:**
- specs/README.md is empty except for structure comments
- plan.md contains only header comment
- README-LOOPY.md has accurate next steps
- .gitignore includes loopy-claude entries
- All .sh files are executable

**Acceptance criteria:**
- All 14 criteria from Section 6 pass
- Export to existing project with files prompts for conflicts
- Dry-run mode produces output but no filesystem changes
- Custom source path works for repositories in different locations

---

**Note:** Plan generator reads this and creates specific tasks in plan.md. This spec describes WHAT; plan describes HOW.

---

## 8. Notes

### Design Decisions

**Why presets instead of individual file selection?**
- Simplicity: Most users want common bundles, not granular selection
- Fewer decisions: Cognitive load reduction
- Extensible: Easy to add more presets (minimal, design, devtools) in future

**Why interactive destination instead of argument?**
- Safety: Forces user to consciously choose location
- Flexibility: Can provide relative or absolute paths
- Confirmation: Shows directory status before proceeding

**Why ask per conflict instead of --force flag?**
- Safety-first: Prevents accidental data loss
- Granular control: User can overwrite some, skip others
- Backup option: Rename preserves original with timestamp

**Why bash instead of Python/Node?**
- Consistency: All loopy-claude scripts are bash
- Zero dependencies: Runs anywhere bash exists
- Simple operations: File copying doesn't need complex libraries

**Why not modify files during export?**
- Predictability: What you see is what you get
- Debuggable: Easy to verify export by diffing files
- Maintainable: No template variable substitution complexity

### Trade-offs Accepted

**Limitation:** Only "full" preset in v1
- **Pro:** Simpler implementation, faster to ship
- **Con:** Users who want minimal setup must manually delete files
- **Mitigation:** Add presets in future based on user feedback

**Limitation:** No Windows support (bash only)
- **Pro:** Simpler code, no path translation
- **Con:** Windows users must use WSL/Git Bash
- **Mitigation:** Document WSL requirement for Windows users

**Limitation:** Interactive prompts (no --yes flag)
- **Pro:** Forces awareness of where files go
- **Con:** Cannot fully automate in scripts
- **Mitigation:** Dry-run mode allows inspection first

### Future Enhancements

- Add minimal, design, devtools presets
- `--dest` flag for non-interactive mode
- `--yes` flag to auto-accept all conflicts (with clear warning)
- Validate exported installation (run loop.sh --validate)
- Support exporting to git submodule
- Template variable substitution (project name, author)

---

**Version:** 1.0
**Last Updated:** 2026-01-24
