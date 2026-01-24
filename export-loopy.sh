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
    "prompts/plan.md"
    "prompts/build.md"
    "prompts/reverse.md"
    ".claude/skills/feature-designer/"
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

    if [[ ! -d "$src/prompts" ]]; then
        echo "Error: Not a loopy-claude directory (prompts/ not found)"
        echo "Source: $src"
        exit 2
    fi

    echo "✓ Source validated: $src"
}

# Check dependencies
check_dependencies() {
    if ! command -v claude &>/dev/null; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠ WARNING: claude CLI not found"
        echo ""
        echo "The exported loopy-claude system requires claude CLI to run."
        echo "Install it from: https://github.com/anthropics/claude-cli"
        echo ""
        echo "Continuing export anyway..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        # Warning only, non-fatal
        return 0
    else
        echo "✓ Dependency check passed: claude CLI found"
    fi
}

# Prompt for destination directory
prompt_destination() {
    local dest=""

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Destination Directory Selection"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    while true; do
        read -rp "Enter destination directory (absolute or relative path): " dest

        # Expand tilde and make absolute
        dest="${dest/#\~/$HOME}"

        if [[ -z "$dest" ]]; then
            echo "Error: Destination cannot be empty"
            continue
        fi

        # Check if directory exists
        if [[ -d "$dest" ]]; then
            echo ""
            echo "Destination: $dest"
            echo "  Directory exists: yes"

            # Check if writable
            if [[ -w "$dest" ]]; then
                echo "  Writable: yes"
            else
                echo "  Writable: no"
                echo "Error: Destination is not writable"
                continue
            fi
        else
            echo ""
            echo "Destination: $dest"
            echo "  Directory exists: no (will be created)"

            # Check if parent directory exists and is writable
            local parent=$(dirname "$dest")
            if [[ ! -d "$parent" ]]; then
                echo "Error: Parent directory does not exist: $parent"
                continue
            fi
            if [[ ! -w "$parent" ]]; then
                echo "Error: Parent directory is not writable: $parent"
                continue
            fi

            echo "  Parent writable: yes"
        fi

        echo ""
        read -rp "Proceed with this destination? [y/n]: " confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Create destination if it doesn't exist
            if [[ ! -d "$dest" ]]; then
                if [[ "$DRY_RUN" == true ]]; then
                    echo "[DRY RUN] Would create directory: $dest"
                else
                    mkdir -p "$dest" || {
                        echo "Error: Failed to create destination directory"
                        exit 4
                    }
                    echo "✓ Created destination directory"
                fi
            fi

            # Return absolute path
            if [[ "$dest" = /* ]]; then
                echo "$dest"
            else
                echo "$(cd "$dest" 2>/dev/null && pwd)" || echo "$dest"
            fi
            return 0
        fi

        echo ""
        echo "Let's try again..."
        echo ""
    done
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

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Export Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Ready to export $PRESET preset"
    echo "  From: $SOURCE_PATH"
    echo "  To:   $destination"
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "[DRY RUN] No files will be copied"
    fi
    echo ""
    echo "Files to export:"
    for file in "${PRESET_FULL[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Generated templates:"
    echo "  - specs/README.md (empty PIN structure)"
    echo "  - plan.md (empty with comment)"
    echo "  - logs/ (directory)"
    echo "  - README-LOOPY.md (quick start guide)"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Dry run complete. No files were modified."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi

    echo "TODO: File copying will be implemented in Task 2"
    echo ""
}

# Run main
main
