#!/usr/bin/env bash
# shellcheck disable=SC2155
set -euo pipefail

# export-loopy.sh - Export loopy-claude components to other projects
# Usage:
#   ./export-loopy.sh <preset> [--source PATH] [--dry-run]
#   ./export-loopy.sh full                     # Export all components
#   ./export-loopy.sh full --dry-run           # Preview without copying
#   ./export-loopy.sh full --source ~/loopy    # Export from custom source

# Parse arguments
PRESET=""
SOURCE_PATH=""
DRY_RUN=false

show_usage() {
    cat <<'EOF'
Usage: ./export-loopy.sh <preset> [OPTIONS]

Arguments:
  preset            Preset to export (currently only 'full' is supported)

Options:
  --source PATH     Source loopy-claude directory (default: current directory)
  --dry-run         Preview export without copying files
  --help            Show this help message

Examples:
  ./export-loopy.sh full
  ./export-loopy.sh full --dry-run
  ./export-loopy.sh full --source ~/code/loopy-claude

Available presets:
  full              Complete loopy-claude system (loop.sh, prompts, skills, etc.)

Exit codes:
  0  Success (all files exported)
  1  User aborted or invalid arguments
  2  Source validation failed (not a loopy-claude directory)
  3  Dependency check failed (claude CLI not found)
  4  Destination error (not writable, creation failed)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_usage
            exit 0
            ;;
        --source)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --source requires a path argument"
                exit 1
            fi
            SOURCE_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --*)
            echo "Error: Unknown flag $1"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$PRESET" ]]; then
                PRESET="$1"
            else
                echo "Error: Unexpected argument $1"
                echo ""
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate preset is provided
if [[ -z "$PRESET" ]]; then
    echo "Error: Preset argument is required"
    echo ""
    show_usage
    exit 1
fi

# Validate preset is supported
if [[ "$PRESET" != "full" ]]; then
    echo "Error: Unknown preset '$PRESET'"
    echo "Currently only 'full' preset is supported"
    echo ""
    show_usage
    exit 1
fi

# Set default source path
SOURCE_PATH="${SOURCE_PATH:-$(pwd)}"

# Define preset files
PRESET_FULL=(
    "loop.sh"
    "analyze-session.sh"
    "export-loopy.sh"
    "loopy.config.json"
    ".claude/"
    ".gitignore"
)

# Validate source directory structure
validate_source() {
    local src="$1"

    if [[ ! -d "$src" ]]; then
        echo "Error: Source directory does not exist: $src"
        exit 2
    fi

    # Check for loopy-claude markers
    if [[ ! -f "$src/loop.sh" ]]; then
        echo "Error: Not a loopy-claude directory (loop.sh not found)"
        echo "Source: $src"
        exit 2
    fi

    if [[ ! -d "$src/.claude/commands" ]]; then
        echo "Error: Not a loopy-claude directory (.claude/commands/ not found)"
        echo "Source: $src"
        exit 2
    fi

    echo "✓ Source validated: $src"
}

# Check dependencies
check_dependencies() {
    # Read default agent from config if available
    local DEFAULT_AGENT="claude"
    local AGENT_COMMAND="claude"
    
    if [[ -f "$SOURCE_PATH/loopy.config.json" ]] && command -v jq &>/dev/null; then
        DEFAULT_AGENT=$(jq -r '.default // "claude"' "$SOURCE_PATH/loopy.config.json" 2>/dev/null || echo "claude")
        AGENT_COMMAND=$(jq -r ".agents.${DEFAULT_AGENT}.command // \"claude\"" "$SOURCE_PATH/loopy.config.json" 2>/dev/null || echo "claude")
    fi
    
    if ! command -v "$AGENT_COMMAND" &>/dev/null; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠ WARNING: Default agent CLI not found: $AGENT_COMMAND"
        echo ""
        echo "The exported loopy-claude system requires an AI CLI agent to run."
        echo "Default agent: $DEFAULT_AGENT (command: $AGENT_COMMAND)"
        echo ""
        echo "Install options:"
        echo "  - Claude CLI: https://github.com/anthropics/claude-cli"
        echo "  - Copilot CLI: https://docs.github.com/copilot/using-github-copilot-in-the-command-line"
        echo ""
        echo "You can change the default agent in loopy.config.json or use --agent flag."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        # Warning only, don't block export
    else
        echo "✓ Dependency check passed: $AGENT_COMMAND CLI found (agent: $DEFAULT_AGENT)"
    fi
}

# Prompt for destination directory
prompt_destination() {
    local dest=""

    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "Destination Directory Selection" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2

    while true; do
        read -rp "Enter destination directory (absolute or relative path): " dest

        # Expand tilde and make absolute
        dest="${dest/#\~/$HOME}"

        if [[ -z "$dest" ]]; then
            echo "Error: Destination cannot be empty" >&2
            continue
        fi

        # Check if directory exists
        if [[ -d "$dest" ]]; then
            echo "" >&2
            echo "Destination: $dest" >&2
            echo "  Directory exists: yes" >&2

            # Check if writable
            if [[ -w "$dest" ]]; then
                echo "  Writable: yes" >&2
            else
                echo "  Writable: no" >&2
                echo "Error: Destination is not writable" >&2
                continue
            fi
        else
            echo "" >&2
            echo "Destination: $dest" >&2
            echo "  Directory exists: no (will be created)" >&2

            # Check if parent directory exists and is writable
            local parent=$(dirname "$dest")
            if [[ ! -d "$parent" ]]; then
                echo "Error: Parent directory does not exist: $parent" >&2
                continue
            fi
            if [[ ! -w "$parent" ]]; then
                echo "Error: Parent directory is not writable: $parent" >&2
                continue
            fi

            echo "  Parent writable: yes" >&2
        fi

        echo "" >&2
        read -rp "Proceed with this destination? [y/n]: " confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Create destination if it doesn't exist
            if [[ ! -d "$dest" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would create directory: $dest" >&2
                else
                    mkdir -p "$dest" || {
                        echo "Error: Failed to create destination directory" >&2
                        exit 4
                    }
                    echo "✓ Created destination directory" >&2
                fi
            fi

            # Return absolute path to stdout (only this gets captured)
            if [[ "$dest" = /* ]]; then
                echo "$dest"
            else
                # Make path absolute (works even if dir doesn't exist yet in dry-run)
                if [[ -d "$dest" ]]; then
                    echo "$(cd "$dest" && pwd)"
                else
                    echo "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")"
                fi
            fi
            return 0
        fi

        echo "" >&2
        echo "Let's try again..." >&2
        echo "" >&2
    done
}

# Resolve conflicts for files that already exist in destination
# Returns: Associative array where key=file, value=action (overwrite|skip|rename)
resolve_conflicts() {
    local src="$1"
    local dest="$2"
    shift 2
    local files=("$@")

    local conflicts=()
    declare -g -A conflict_resolutions

    # Detect conflicts (exclude .gitignore - handled separately)
    for file in "${files[@]}"; do
        if [[ "$file" != ".gitignore" ]] && [[ -e "$dest/$file" ]]; then
            conflicts+=("$file")
        fi
    done

    # No conflicts
    if [[ ${#conflicts[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Conflicts Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The following files already exist in the destination:"
    echo ""

    # Prompt for each conflict
    for file in "${conflicts[@]}"; do
        echo "File exists: $file"
        echo "  (o) Overwrite"
        echo "  (s) Skip this file"
        echo "  (r) Rename existing to $file.backup.$(date +%Y%m%d-%H%M%S)"
        echo "  (a) Abort export"
        echo ""

        while true; do
            read -rp "Choice [o/s/r/a]: " choice
            case "$choice" in
                o|O)
                    conflict_resolutions["$file"]="overwrite"
                    break
                    ;;
                s|S)
                    conflict_resolutions["$file"]="skip"
                    break
                    ;;
                r|R)
                    conflict_resolutions["$file"]="rename"
                    break
                    ;;
                a|A)
                    echo ""
                    echo "Export aborted by user"
                    exit 1
                    ;;
                *)
                    echo "Invalid choice. Please enter o, s, r, or a."
                    ;;
            esac
        done
        echo ""
    done
}

# Copy files from source to destination respecting conflict resolutions
copy_files() {
    local src="$1"
    local dest="$2"
    shift 2
    local files=("$@")

    local timestamp=$(date +%Y%m%d-%H%M%S)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Copying Files"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for file in "${files[@]}"; do
        local src_path="$src/$file"
        local dest_path="$dest/$file"

        # Skip .gitignore (handled separately by merge_gitignore)
        if [[ "$file" == ".gitignore" ]]; then
            continue
        fi

        # Skip if doesn't exist in source
        if [[ ! -e "$src_path" ]]; then
            echo "⚠ Skipping $file (not found in source)"
            continue
        fi

        # Check for conflict resolution
        local resolution="${conflict_resolutions[$file]:-}"

        if [[ "$resolution" == "skip" ]]; then
            echo "⊘ Skipping $file (user chose to skip)"
            continue
        fi

        # Create parent directory if needed
        local dest_dir=$(dirname "$dest_path")
        if [[ ! -d "$dest_dir" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would create directory: $dest_dir"
            else
                mkdir -p "$dest_dir"
            fi
        fi

        # Handle rename
        if [[ "$resolution" == "rename" ]]; then
            local backup_path="$dest_path.backup.$timestamp"
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would rename: $file → $file.backup.$timestamp"
            else
                mv "$dest_path" "$backup_path"
                echo "↻ Renamed existing: $file → $file.backup.$timestamp"
            fi
        fi

        # Copy file or directory
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would copy: $file"
        else
            if [[ -d "$src_path" ]]; then
                cp -r "$src_path" "$dest_path"
                echo "✓ Copied directory: $file"
            else
                cp "$src_path" "$dest_path"
                echo "✓ Copied file: $file"
            fi
        fi
    done
}

# Merge .gitignore entries with existing file or copy if doesn't exist
merge_gitignore() {
    local src="$1"
    local dest="$2"

    local src_gitignore="$src/.gitignore"
    local dest_gitignore="$dest/.gitignore"

    # Skip if .gitignore not in source
    if [[ ! -f "$src_gitignore" ]]; then
        return 0
    fi

    echo ""

    if [[ -f "$dest_gitignore" ]]; then
        # Merge with existing
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would append loopy-claude entries to .gitignore"
        else
            echo "" >> "$dest_gitignore"
            echo "# Loopy-Claude entries (added $(date +%Y-%m-%d))" >> "$dest_gitignore"
            grep -v "^#" "$src_gitignore" | grep -v "^$" >> "$dest_gitignore"
            echo "✓ Merged .gitignore entries"
        fi
    else
        # Copy entire file
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would copy .gitignore"
        else
            cp "$src_gitignore" "$dest_gitignore"
            echo "✓ Copied .gitignore"
        fi
    fi
}

# Set executable permissions on shell scripts
set_permissions() {
    local dest="$1"

    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would set executable permissions on .sh files"
    else
        # Find all .sh files and make them executable
        find "$dest" -type f -name "*.sh" -exec chmod +x {} \;
        echo "✓ Set executable permissions on .sh files"
    fi
}

# Get project name from git or prompt user
get_project_name() {
    local dest="$1"
    local project_name=""

    # Try to get project name from git config in destination
    if [[ -d "$dest/.git" ]]; then
        project_name=$(cd "$dest" && git config --get remote.origin.url 2>/dev/null | sed -E 's#.*/([^/]+)(\.git)?$#\1#')
    fi

    # If not found, try to get from directory name
    if [[ -z "$project_name" ]]; then
        project_name=$(basename "$dest")
    fi

    # If still empty or seems generic, prompt user
    if [[ -z "$project_name" ]] || [[ "$project_name" =~ ^(tmp|test|project)$ ]]; then
        read -rp "Enter project name for specs/README.md [default: $project_name]: " user_input
        if [[ -n "$user_input" ]]; then
            project_name="$user_input"
        fi
    fi

    echo "$project_name"
}

# Generate template files for new installation
generate_templates() {
    local dest="$1"
    local src="$2"
    local current_date=$(date +%Y-%m-%d)
    local project_name=$(get_project_name "$dest")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Generating Templates"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create logs/ directory
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create logs/ directory"
    else
        mkdir -p "$dest/logs"
        echo "✓ Created logs/ directory"
    fi

    # Create loopy.config.json if not already copied from source
    if [[ ! -f "$dest/loopy.config.json" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would create loopy.config.json"
        else
            cat > "$dest/loopy.config.json" <<'EOF'
{
  "default": "claude",
  "agents": {
    "claude": {
      "command": "claude",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": {
        "opus": "opus",
        "sonnet": "sonnet",
        "haiku": "haiku"
      },
      "extraArgs": "--dangerously-skip-permissions --output-format=stream-json --verbose",
      "outputFormat": "stream-json",
      "rateLimitPattern": "rate_limit_error|overloaded_error|quota.*exhausted"
    },
    "copilot": {
      "command": "copilot",
      "promptFlag": "-p",
      "modelFlag": "--model",
      "models": {
        "opus": "claude-opus-4.5",
        "sonnet": "claude-sonnet-4.5",
        "haiku": "claude-haiku-4.5"
      },
      "extraArgs": "--allow-all-tools -s",
      "outputFormat": "text",
      "rateLimitPattern": "rate.?limit|quota|too many requests"
    }
  }
}
EOF
            echo "✓ Created loopy.config.json"
        fi
    fi

    # Create specs/README.md
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create specs/README.md"
    else
        mkdir -p "$dest/specs"
        cat > "$dest/specs/README.md" <<EOF
# Project Specifications

Lookup table for specifications.

## How to Use

1. **AI agents:** Study \`specs/README.md\` before any spec work
2. **Search here** to find relevant existing specs by keyword
3. **When creating new spec:** Add entry here with semantic keywords

---

## Specs

| Spec | Code | Purpose |
|------|------|---------|
|      |      |         |

---

**Last Updated:** $current_date
**Project:** $project_name
EOF
        echo "✓ Created specs/README.md"
    fi

    # Create plan.md
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create plan.md"
    else
        cat > "$dest/plan.md" <<'EOF'
# Generated by loop.sh

# This file will be populated when you run:
#   ./loop.sh plan 5

# For first-time usage, see README-LOOPY.md
EOF
        echo "✓ Created plan.md"
    fi

    # Create README-LOOPY.md
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would create README-LOOPY.md"
    else
        cat > "$dest/README-LOOPY.md" <<EOF
# Loopy-Claude Quick Start

Components exported from: $src
Export date: $current_date

## Prerequisites

- Default agent CLI installed (check with \`claude --version\` or \`copilot --version\`)
- Configuration: \`loopy.config.json\` (generated automatically)
- Git repository (optional but recommended)

## Using Different Agents

\`\`\`bash
./loop.sh plan 5                      # Uses default agent (claude)
./loop.sh plan 5 --agent copilot      # Uses Copilot
LOOPY_AGENT=copilot ./loop.sh plan 5  # Via environment variable
\`\`\`

## First Steps

1. Review exported files:
   - \`loop.sh\` - Main orchestrator
   - \`loopy.config.json\` - Agent configurations
   - \`.claude/commands/\` - Command prompts (plan, build, validate, reverse, prime, bug)
   - \`.claude/agents/\` - Validation agents (spec-checker, spec-inferencer)
   - \`.claude/skills/\` - Interactive skills (feature-designer)

2. Create your first spec (optional):
   \`\`\`bash
   claude
   > /feature-designer
   > [describe your feature]
   > crystallize
   \`\`\`

3. Generate implementation plan:
   \`\`\`bash
   ./loop.sh plan 5
   \`\`\`

4. Review plan.md and execute:
   \`\`\`bash
   cat plan.md
   ./loop.sh build 10
   \`\`\`

## Modes

- \`plan\` - Generate tasks from specs (5 phases, extended thinking)
- \`build\` - Execute tasks with mandatory verification
- \`validate\` - Post-implementation validator (spec vs code)
- \`reverse\` - Analyze legacy code into specs
- \`work\` - **Automated build→validate cycles** (recommended workflow)
- \`prime\` - Repository orientation
- \`bug\` - Bug analysis and corrective task creation

## Learn More

See loop.sh comments and .claude/commands/ for detailed documentation.

---

Exported from loopy-claude: $src
EOF
        echo "✓ Created README-LOOPY.md"
    fi
}

# Print summary of exported files and next steps
print_summary() {
    local dest="$1"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Export Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Loopy-Claude components exported successfully!"
    echo ""
    echo "Destination: $dest"
    echo ""
    echo "Exported files:"
    for file in "${PRESET_FULL[@]}"; do
        if [[ "$file" == ".gitignore" ]]; then
            # .gitignore is merged, not directly copied
            if [[ -f "$dest/.gitignore" ]]; then
                echo "  ✓ .gitignore (merged)"
            fi
        elif [[ -e "$dest/$file" ]]; then
            echo "  ✓ $file"
        fi
    done
    echo ""
    echo "Generated templates:"
    if [[ -d "$dest/logs" ]]; then
        echo "  ✓ logs/"
    fi
    if [[ -f "$dest/specs/README.md" ]]; then
        echo "  ✓ specs/README.md"
    fi
    if [[ -f "$dest/plan.md" ]]; then
        echo "  ✓ plan.md"
    fi
    if [[ -f "$dest/README-LOOPY.md" ]]; then
        echo "  ✓ README-LOOPY.md"
    fi
    echo ""
    echo "Next steps:"
    echo "  1. cd $dest"
    echo "  2. Review exported files"
    echo "  3. See README-LOOPY.md for quick start guide"
    echo ""
}

# Main script execution
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Loopy-Claude Export Tool"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Preset: $PRESET"
    echo "Source: $SOURCE_PATH"
    if [[ "$DRY_RUN" == true ]]; then
        echo "Mode: DRY RUN (no files will be copied)"
    fi
    echo ""

    # Step 1: Validate source
    validate_source "$SOURCE_PATH"

    # Step 2: Check dependencies
    check_dependencies

    # Step 3: Get destination
    local destination=$(prompt_destination)

    # Step 4: Resolve conflicts
    declare -g -A conflict_resolutions
    resolve_conflicts "$SOURCE_PATH" "$destination" "${PRESET_FULL[@]}"

    # Step 5: Copy files
    copy_files "$SOURCE_PATH" "$destination" "${PRESET_FULL[@]}"

    # Step 6: Generate templates
    generate_templates "$destination" "$SOURCE_PATH"

    # Step 7: Merge .gitignore
    merge_gitignore "$SOURCE_PATH" "$destination"

    # Step 8: Set permissions
    set_permissions "$destination"

    # Step 9: Print summary
    print_summary "$destination"
}

# Run main
main
