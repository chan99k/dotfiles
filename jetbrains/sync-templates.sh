#!/usr/bin/env bash
# Sync JetBrains Live Templates to the latest IntelliJ IDEA version.
#
# Usage:
#   ./sync-templates.sh          # Deploy: dotfiles → IntelliJ
#   ./sync-templates.sh pull     # Pull:   IntelliJ → dotfiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_SRC="$SCRIPT_DIR/templates"
JETBRAINS_BASE="$HOME/Library/Application Support/JetBrains"

# Find the latest IntelliJ IDEA directory
find_latest_idea() {
    local latest
    latest=$(ls -d "$JETBRAINS_BASE"/IntelliJIdea* 2>/dev/null \
        | grep -v backup \
        | sort -V \
        | tail -1)

    if [[ -z "$latest" ]]; then
        echo "Error: No IntelliJ IDEA installation found" >&2
        exit 1
    fi
    echo "$latest"
}

deploy() {
    local idea_dir
    idea_dir="$(find_latest_idea)"
    local target="$idea_dir/templates"

    mkdir -p "$target"

    echo "Deploying templates to: $target"
    for xml in "$TEMPLATE_SRC"/*.xml; do
        [[ -f "$xml" ]] || continue
        local name
        name=$(basename "$xml")
        cp "$xml" "$target/$name"
        echo "  ✓ $name"
    done

    echo "Done. Restart IntelliJ to apply changes."
}

pull() {
    local idea_dir
    idea_dir="$(find_latest_idea)"
    local source="$idea_dir/templates"

    if [[ ! -d "$source" ]]; then
        echo "Error: No templates directory at $source" >&2
        exit 1
    fi

    echo "Pulling templates from: $source"
    for xml in "$source"/*.xml; do
        [[ -f "$xml" ]] || continue
        local name
        name=$(basename "$xml")
        cp "$xml" "$TEMPLATE_SRC/$name"
        echo "  ✓ $name"
    done

    echo "Done. Templates saved to $TEMPLATE_SRC"
}

case "${1:-deploy}" in
    deploy) deploy ;;
    pull)   pull ;;
    *)
        echo "Usage: $0 [deploy|pull]" >&2
        exit 1
        ;;
esac
