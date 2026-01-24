# Implementation Plan

Generated: 2026-01-24
Specs analyzed: 1 (export-loopy-system.md)

## Phase 1: Core Script Structure

- [ ] Create export-loopy.sh with argument parsing and validation
      Done when:
        - File exists at /home/tlucas/code/loopy-claude/export-loopy.sh
        - Shebang (#!/usr/bin/env bash) and set -euo pipefail present
        - Parses preset argument (full required, others future)
        - Parses --source PATH flag (optional)
        - Parses --dry-run flag (optional)
        - Shows usage/help on invalid arguments
        - Exit code 1 on invalid arguments
      Verify:
        - grep -q "#!/usr/bin/env bash" export-loopy.sh
        - grep -q "set -euo pipefail" export-loopy.sh
        - ./export-loopy.sh invalid 2>&1 | grep -q "Usage"
        - ./export-loopy.sh full --dry-run --source . 2>&1 | head -1
      (cite: specs/export-loopy-system.md Section 4 - CLI Interface, Section 7 - Implementation Hints)

- [ ] Implement source validation function
      Done when:
        - validate_source() function checks loopy-claude directory structure
        - Verifies loop.sh exists
        - Verifies prompts/ directory exists
        - Returns exit code 2 on validation failure
        - --source flag sets source path (defaults to pwd)
      Verify:
        - grep -q "validate_source" export-loopy.sh
        - ./export-loopy.sh full --source /nonexistent 2>&1 | grep -iq "source\|valid\|not found"
      (cite: specs/export-loopy-system.md Section 2 - Flow: Validate source, Section 4 - Exit Codes)

- [ ] Implement dependency check for claude CLI
      Done when:
        - check_dependencies() function verifies claude CLI is installed
        - Uses `command -v claude` or similar check
        - Warns user if missing (does not block, just warns)
        - Exit code 3 only if --strict mode (future, for now just warn)
      Verify:
        - grep -q "check_dependencies\|command -v claude" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 2 - Dependencies, Section 4 - Exit Codes)

## Phase 2: Interactive Destination & Preset Definition

- [ ] Implement interactive destination prompt
      Done when:
        - prompt_destination() function asks user for destination path
        - Accepts absolute or relative paths
        - Creates directory if it doesn't exist (with confirmation)
        - Validates writable permissions
        - Shows confirmation before proceeding
        - Exit code 4 on destination errors
      Verify:
        - grep -q "prompt_destination\|Enter destination" export-loopy.sh
        - grep -q "mkdir\|Proceed" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 4 - Interactive Prompts: Destination prompt)

- [ ] Define PRESET_FULL array and file list
      Done when:
        - PRESET_FULL bash array defined with all component files
        - Includes: loop.sh, analyze-session.sh, prompts/plan.md, prompts/build.md, prompts/reverse.md, .claude/skills/feature-designer/, .gitignore
        - Function to get preset files by name
      Verify:
        - grep -q "PRESET_FULL" export-loopy.sh
        - grep -q "loop.sh" export-loopy.sh && grep -q "prompts/" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.1 - Preset Definitions)

## Phase 3: Conflict Resolution & File Operations

- [ ] Implement conflict detection and resolution
      Done when:
        - resolve_conflicts() scans destination for existing files matching preset
        - Prompts user per conflict: (o)verwrite / (s)kip / (r)ename / (a)bort
        - Rename creates backup with timestamp: file.backup.YYYYMMDD-HHMMSS
        - Stores user choices for batch processing
        - Abort exits with code 1
      Verify:
        - grep -q "resolve_conflicts\|Overwrite\|Skip\|Rename\|Abort" export-loopy.sh
        - grep -q "backup.*[0-9]" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.3 - Conflict Resolution Strategy)

- [ ] Implement file copy operations
      Done when:
        - copy_files() copies preset files respecting conflict resolutions
        - Maintains directory structure (creates parent dirs as needed)
        - Handles both files and directories (feature-designer/)
        - Sets executable permissions for .sh files (chmod +x)
        - Skips files marked as skip in conflict resolution
      Verify:
        - grep -q "copy_files\|cp " export-loopy.sh
        - grep -q "chmod +x\|chmod.*x" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 2 - File operations, Section 3.3)

- [ ] Implement .gitignore merging logic
      Done when:
        - If destination has .gitignore, append loopy entries with separator comment
        - If no .gitignore exists, copy entire file
        - Separator: "# Loopy-Claude entries (added YYYY-MM-DD)"
        - Does not duplicate entries already present
      Verify:
        - grep -q "gitignore\|Loopy-Claude entries" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.4 - .gitignore Merging)

## Phase 4: Template Generation

- [ ] Implement specs/README.md template generation
      Done when:
        - Creates specs/ directory if not exists
        - Generates specs/README.md with empty PIN structure
        - Includes date placeholder filled with current date
        - Detects project name from git or destination directory name
      Verify:
        - grep -q "specs/README.md\|Lookup table" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.2 - Template Generation: specs/README.md)

- [ ] Implement plan.md template generation
      Done when:
        - Creates plan.md with comment header only
        - Comments explain this is generated by loop.sh
        - Points to README-LOOPY.md for first-time usage
      Verify:
        - grep -q "plan.md\|Generated by loop.sh" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.2 - Template Generation: plan.md)

- [ ] Implement README-LOOPY.md quick-start generation
      Done when:
        - Creates README-LOOPY.md with quick-start instructions
        - Lists exported components
        - Includes export timestamp and source path
        - Documents prerequisites, first steps, modes
        - Self-contained guide (no external links required)
      Verify:
        - grep -q "README-LOOPY.md\|Quick Start" export-loopy.sh
        - grep -q "Prerequisites\|First Steps" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 3.2 - Template Generation: README-LOOPY.md)

## Phase 5: Dry-Run Mode & Summary

- [ ] Implement dry-run mode
      Done when:
        - --dry-run flag skips all file operations
        - Shows what files WOULD be copied
        - Shows what templates WOULD be created
        - Shows what conflicts WOULD need resolution
        - No filesystem changes occur
      Verify:
        - ./export-loopy.sh full --dry-run --source . 2>&1 | grep -iq "would\|dry"
      (cite: specs/export-loopy-system.md Section 4 - Examples, Section 7 - Verification: Test 3)

- [ ] Implement summary report
      Done when:
        - print_summary() lists all exported files
        - Shows destination path
        - Displays next steps instructions
        - Shows count of files copied, skipped, renamed
      Verify:
        - grep -q "print_summary\|Summary\|exported" export-loopy.sh
      (cite: specs/export-loopy-system.md Section 2 - Summary report)

## Phase 6: Documentation & Testing

- [ ] Add header documentation to export-loopy.sh
      Done when:
        - Script header includes usage examples
        - Documents all presets (full for now, future presets noted)
        - Documents all flags: --source, --dry-run
        - Documents exit codes: 0, 1, 2, 3, 4
      Verify:
        - head -30 export-loopy.sh | grep -q "Usage"
        - head -50 export-loopy.sh | grep -q "Exit code"
      (cite: specs/export-loopy-system.md Section 7 - Documentation)

- [ ] Manual testing and verification
      Done when:
        - Test 1 passes: Fresh export to empty directory
        - Test 2 passes: Export with conflicts (test all resolution options)
        - Test 3 passes: Dry-run mode (no files created)
        - Test 4 passes: Custom source path
        - Test 5 passes: .gitignore merging
        - All 14 acceptance criteria from spec verified
      Verify:
        - mkdir -p /tmp/test-export-fresh && ./export-loopy.sh full --source . 2>&1 || true
        - [ -x /tmp/test-export-fresh/loop.sh ] && echo "executable preserved"
      (cite: specs/export-loopy-system.md Section 5 - Testing Strategy, Section 6 - Acceptance Criteria)
