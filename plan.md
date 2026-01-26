# Implementation Plan

Generated: 2026-01-26
Specs analyzed: 1 (cli-agnostic-system.md)

## Phase 1: Core Infrastructure

- [ ] Create loopy.config.json and update loop.sh for multi-agent support
      Done when:
        - loopy.config.json exists with claude and copilot agent definitions
        - loop.sh parses --agent flag
        - loop.sh resolves agent (flag > env > config default > hardcoded)
        - loop.sh builds command dynamically from config
        - loop.sh banner shows "Agent: {name}"
        - Default behavior unchanged (claude)
      Verify:
        - test -f loopy.config.json
        - grep -q '"default": "claude"' loopy.config.json
        - grep -q "copilot" loopy.config.json
        - grep -q "\-\-agent" loop.sh
        - grep -q "LOOPY_AGENT" loop.sh
        - grep -q 'log "Agent:' loop.sh
      (cite: specs/cli-agnostic-system.md sections 3.1-3.4, 4, 6)
      [Grouped: foundational infrastructure, same subsystem, ~340 lines context]

## Phase 2: Session Analysis

- [ ] Update analyze-session.sh for graceful degradation with non-JSON agents
      Done when:
        - Reads Agent from log header
        - Uses outputFormat from config to determine parsing strategy
        - Shows "Cost/Token analysis not available" for non-stream-json agents
        - Basic metrics (iterations, stop condition, duration) work for all agents
        - No errors when analyzing copilot logs
      Verify:
        - grep -q 'Agent.*grep\|awk' analyze-session.sh
        - grep -q "outputFormat\|stream-json" analyze-session.sh
        - grep -q "not available\|graceful" analyze-session.sh
      (cite: specs/cli-agnostic-system.md section 3.7)
      [Single file, ~200 lines context]

## Phase 3: Export System

- [ ] Update export-loopy.sh to support loopy.config.json
      Done when:
        - loopy.config.json added to PRESET_FULL array
        - Dependency check reads default agent from config
        - README-LOOPY.md template mentions multi-agent support
        - generate_templates creates loopy.config.json if missing
      Verify:
        - grep -q "loopy.config.json" export-loopy.sh
        - grep -qE 'PRESET_FULL.*loopy.config.json|loopy.config.json.*PRESET_FULL' export-loopy.sh || grep -A20 "PRESET_FULL=(" export-loopy.sh | grep -q "loopy.config.json"
        - grep -q "DEFAULT_AGENT\|default.*agent" export-loopy.sh
        - grep -q "\-\-agent" export-loopy.sh
      (cite: specs/cli-agnostic-system.md sections 2, 6, 7.3)
      [Single file, ~700 lines context]

## Phase 4: Documentation

- [ ] Update README.md to document multi-agent support
      Done when:
        - No "Claude Code only" references
        - --agent flag documented in usage section
        - loopy.config.json explained in Configuration section
        - LOOPY_AGENT environment variable documented
        - FAQ updated for multi-agent support
        - File structure includes loopy.config.json
      Verify:
        - ! grep -q "Claude Code only" README.md
        - grep -q "\-\-agent" README.md
        - grep -q "loopy.config.json" README.md
        - grep -q "LOOPY_AGENT" README.md
        - grep -q "copilot\|Copilot" README.md
      (cite: specs/cli-agnostic-system.md sections 4, 7.3, 8)
      [Single file, ~500 lines context]

---

## Context Budget Summary

| Phase | Files | Est. Lines | Status |
|-------|-------|------------|--------|
| Phase 1 | loopy.config.json (new), loop.sh | ~340 | ✅ Within budget |
| Phase 2 | analyze-session.sh | ~200 | ✅ Within budget |
| Phase 3 | export-loopy.sh | ~700 | ✅ Within budget |
| Phase 4 | README.md | ~500 | ✅ Within budget |
