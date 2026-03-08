#!/bin/bash

# Render CV from specified version
# Usage: ./scripts/render.sh [version]
#   version: full, short, or other version name (default: full)

set -e

VERSION="${1:-full}"
WORKSPACE_DIR="$(git rev-parse --show-toplevel)"

if [ ! -f "$WORKSPACE_DIR/versions/$VERSION.yml" ]; then
    echo "Error: Version file not found: versions/$VERSION.yml"
    exit 1
fi

echo "Rendering CV: $VERSION"

cd "$WORKSPACE_DIR"

OUTPUT_DIR="$WORKSPACE_DIR/output/$VERSION"
mkdir -p "$OUTPUT_DIR"

export CV_VERSION="$WORKSPACE_DIR/versions/$VERSION.yml"
export WORKSPACE_DIR="$WORKSPACE_DIR"

echo "  → Generating PDF..."
quarto render "$WORKSPACE_DIR/templates/cv.qmd" \
    --to typst \
    --output-dir $OUTPUT_DIR

# Clean up temporary files
rm -f "$WORKSPACE_DIR/templates/_temp_publications.yml"

echo "✓ Done. Output in: $OUTPUT_DIR"
