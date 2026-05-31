#!/bin/bash

# Render CV from specified version
# Usage: ./scripts/render.sh [version]
#   version: full, short, or other version name (default: full)

set -e

VERSION="${1:-full}"
WORKSPACE_DIR="$(git rev-parse --show-toplevel)"

echo "Workspace directory: $WORKSPACE_DIR"
if [ ! -f "$WORKSPACE_DIR/versions/$VERSION.yml" ]; then
    echo "Error: Version file not found: versions/$VERSION.yml"
    exit 1
fi

echo "Rendering CV: $VERSION"

cd "$WORKSPACE_DIR"

OUTPUT_FILE="$WORKSPACE_DIR/output/$VERSION.pdf"
echo "Output file: $OUTPUT_FILE"

export CV_VERSION="$WORKSPACE_DIR/versions/$VERSION.yml"
export WORKSPACE_DIR="$WORKSPACE_DIR"

echo "  → Generating Typst source..."
quarto render "$WORKSPACE_DIR/templates/cv.qmd" \
    --to typst \
    --output-dir "$WORKSPACE_DIR/output" \
    --debug

# Post-process: remove Quarto's article wrapper to prevent blank first page
TYPST_FILE="$WORKSPACE_DIR/templates/cv.typ"
if [ -f "$TYPST_FILE" ]; then
    echo "  → Removing Quarto wrapper..."
    # Remove the duplicate #set page(...) block and the #show: doc => article(...) block
    # inserted by Quarto which causes an empty first page
    sed '/^#set page(/,/^$/d; /^#show: doc => article(/,/^$/d' "$TYPST_FILE" > "$TYPST_FILE.tmp"
    mv "$TYPST_FILE.tmp" "$TYPST_FILE"
fi

# Compile the cleaned Typst file to PDF
echo "  → Compiling cleaned Typst to PDF..."
quarto typst compile "$TYPST_FILE" "$OUTPUT_FILE"

# Generate Markdown version directly using R
echo "  → Rendering Markdown version..."
Rscript --vanilla "$WORKSPACE_DIR/scripts/render-markdown.R"

# Clean up temporary files
rm -f "$WORKSPACE_DIR/templates/_temp_publications.yml"
rm -f "$TYPST_FILE"
rm -f "$WORKSPACE_DIR/output/cv.pdf"  # Remove Quarto's default output (not post-processed)
rm -f "$WORKSPACE_DIR/output/cv.md"   # Remove Quarto's default output

echo "✓ Done."
