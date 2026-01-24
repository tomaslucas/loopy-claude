# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (export-loopy-system.md)
Action: fresh (plan.md was empty)

---

## Phase 1: Export Script Implementation

### Task 1: Foundation & Infrastructure

- [ ] Create export-loopy.sh with argument parsing, source validation, dependency checks, and destination prompt
      Done when:
        - File export-loopy.sh exists in root with shebang and set -euo pipefail
        - Usage message displays for --help or invalid args
        - Parses preset (full required), --source PATH, --dry-run flags
        - validate_source() verifies loopy-claude structure (loop.sh, prompts/ exist)
        - check_dependencies() warns if claude CLI not found (non-fatal)
        - prompt_destination() interactively asks for path with confirmation
        - PRESET_FULL array defines all files to export
      Verify:
        - chmod +x export-loopy.sh && ./export-loopy.sh --help
        - ./export-loopy.sh invalid-preset 2>&1 | grep -q "Usage"
        - ./export-loopy.sh full --dry-run (should prompt for destination)
      (cite: specs/export-loopy-system.md sections 3.1, 4)
      [Grouped: Sequential dependencies - args must parse before validation, validation before destination prompt. ~150 lines, same file]

### Task 2: Core Operations

- [ ] Implement conflict resolution, file copying, gitignore merging, and permission handling
      Done when:
        - resolve_conflicts() detects existing files at destination
        - Per-conflict prompt offers: (o)verwrite, (s)kip, (r)ename, (a)bort
        - Rename creates .backup.YYYYMMDD-HHMMSS suffix
        - copy_files() copies preset files respecting conflict resolutions
        - Directories created as needed (mkdir -p)
        - merge_gitignore() appends entries if .gitignore exists, copies if not
        - set_permissions() makes all .sh files executable (chmod +x)
        - All operations respect --dry-run (print what would happen, no actual changes)
      Verify:
        - mkdir /tmp/test-conflict && touch /tmp/test-conflict/loop.sh
        - ./export-loopy.sh full (enter /tmp/test-conflict, test conflict prompt)
        - Verify backup created when choosing (r)ename
        - rm -rf /tmp/test-conflict
      (cite: specs/export-loopy-system.md sections 3.3, 3.4)
      [Grouped: All file operation logic, depends on Task 1 functions. ~150 lines, same file]

### Task 3: Output & Finalization

- [ ] Implement template generation, summary report, and main orchestration flow
      Done when:
        - generate_templates() creates specs/README.md with empty PIN structure
        - generate_templates() creates plan.md with header comment only
        - generate_templates() creates README-LOOPY.md with quick start guide
        - Templates use heredocs with variable substitution ({date}, {source})
        - print_summary() lists all exported files and shows next steps
        - Main script flow orchestrates: validate → deps → destination → conflicts → copy → templates → gitignore → permissions → summary
        - Exit codes: 0=success, 1=abort/invalid, 2=source fail, 3=deps fail, 4=dest fail
        - End-to-end test passes: fresh export creates working loopy-claude copy
      Verify:
        - mkdir /tmp/test-export
        - ./export-loopy.sh full (enter /tmp/test-export, no conflicts)
        - [ -x /tmp/test-export/loop.sh ] && echo "✅ loop.sh executable"
        - [ -f /tmp/test-export/prompts/plan.md ] && echo "✅ prompts copied"
        - [ -f /tmp/test-export/specs/README.md ] && echo "✅ specs template"
        - [ -f /tmp/test-export/README-LOOPY.md ] && echo "✅ quick start"
        - cat /tmp/test-export/README-LOOPY.md | grep -q "Quick Start"
        - rm -rf /tmp/test-export
      (cite: specs/export-loopy-system.md sections 3.2, 6)
      [Grouped: All output generation, depends on Tasks 1-2. ~65 lines + main flow, same file]

---

## Context Budget Summary

| Task | Estimated Lines | Files | Context Load |
|------|-----------------|-------|--------------|
| Task 1 | ~150 | 1 (export-loopy.sh) | ✅ Small |
| Task 2 | ~150 | 1 (export-loopy.sh) | ✅ Small |
| Task 3 | ~65 + main | 1 (export-loopy.sh) | ✅ Small |
| **Total** | ~365 | **1 file** | ✅ Under 500 threshold |

**Grouping rationale:** Single file implementation (~365 lines) warrants MAX 3 tasks per guidelines. Tasks split by logical subsystem with clear sequential dependencies (foundation → operations → output).

---

## Acceptance Criteria Mapping

All 14 acceptance criteria from spec Section 6 covered:

| # | Criteria | Task |
|---|----------|------|
| 1 | Export "full" preset to writable directory | 1, 2 |
| 2 | Validate source is loopy-claude directory | 1 |
| 3 | Verify claude CLI installed (warn if missing) | 1 |
| 4 | Interactive destination selection with confirmation | 1 |
| 5 | Conflict prompt with 4 options (o/s/r/a) | 2 |
| 6 | Renamed files include timestamp | 2 |
| 7 | Templates created empty with comments | 3 |
| 8 | .gitignore merged or copied | 2 |
| 9 | Executable permissions preserved | 2 |
| 10 | README-LOOPY.md generated | 3 |
| 11 | Summary report with next steps | 3 |
| 12 | --dry-run preview mode | 1, 2 |
| 13 | --source flag for custom location | 1 |
| 14 | Correct exit codes | 3 |
