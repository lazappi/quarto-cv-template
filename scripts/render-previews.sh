#!/usr/bin/env bash

# Render one or more CV versions and export each PDF page to PNG.
# Usage:
#   ./scripts/render-previews.sh [--skip-render] [version ...]
# Examples:
#   ./scripts/render-previews.sh
#   ./scripts/render-previews.sh full short
#   ./scripts/render-previews.sh --skip-render full

set -euo pipefail

SKIP_RENDER=false
if [[ "${1:-}" == "--skip-render" ]]; then
    SKIP_RENDER=true
    shift
fi

WORKSPACE_DIR="$(git rev-parse --show-toplevel)"
PREVIEW_DIR="$WORKSPACE_DIR/docs/previews"

if ! command -v pdftoppm >/dev/null 2>&1; then
    echo "Error: pdftoppm is required (install poppler)."
    exit 1
fi

if [[ "$SKIP_RENDER" == false ]] && ! command -v quarto >/dev/null 2>&1; then
    echo "Error: quarto is required for rendering."
    exit 1
fi

if [[ "$#" -gt 0 ]]; then
    versions=("$@")
else
    mapfile -t versions < <(cd "$WORKSPACE_DIR" && for version in versions/*.yml; do basename "$version" .yml; done)
fi

if [[ "${#versions[@]}" -eq 0 ]]; then
    echo "Error: no versions found in versions/*.yml"
    exit 1
fi

mkdir -p "$PREVIEW_DIR"

for version in "${versions[@]}"; do
    version_file="$WORKSPACE_DIR/versions/$version.yml"
    pdf_file="$WORKSPACE_DIR/output/$version.pdf"

    if [[ ! -f "$version_file" ]]; then
        echo "Error: version file not found: $version_file"
        exit 1
    fi

    if [[ "$SKIP_RENDER" == false ]]; then
        echo "Rendering version: $version"
        "$WORKSPACE_DIR/scripts/render.sh" "$version"
    fi

    if [[ ! -f "$pdf_file" ]]; then
        echo "Error: PDF not found after render: $pdf_file"
        exit 1
    fi

    rm -f "$PREVIEW_DIR/$version-page-"*.png

    echo "Exporting preview PNGs for: $version"
    pdftoppm -png "$pdf_file" "$PREVIEW_DIR/$version-page" >/dev/null

done

echo "✓ Preview images updated in: $PREVIEW_DIR"
