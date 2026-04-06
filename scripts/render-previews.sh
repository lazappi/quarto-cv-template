#!/usr/bin/env bash

# Export one or more rendered CV PDFs to preview PNGs.
# Usage:
#   ./scripts/render-previews.sh [version ...]
# Examples:
#   ./scripts/render-previews.sh
#   ./scripts/render-previews.sh full short

set -euo pipefail

WORKSPACE_DIR="$(git rev-parse --show-toplevel)"
PREVIEW_DIR="$WORKSPACE_DIR/docs/previews"

if ! command -v pdftoppm >/dev/null 2>&1; then
    echo "Error: pdftoppm is required (install poppler)."
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

    if [[ ! -f "$pdf_file" ]]; then
        echo "Error: rendered PDF not found: $pdf_file"
        exit 1
    fi

    rm -f "$PREVIEW_DIR/$version-page-"*.png

    echo "Exporting preview PNGs for: $version"
    pdftoppm -png "$pdf_file" "$PREVIEW_DIR/$version-page" >/dev/null

done

echo "✓ Preview images updated in: $PREVIEW_DIR"
