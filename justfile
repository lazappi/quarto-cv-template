# Show help
default: help

# Render a specific CV version by name
[group("render")]
[arg("VERSION", help="Version to render, see 'just list'")]
render VERSION:
    @echo "Rendering {{VERSION}} CV..."
    ./scripts/render.sh {{VERSION}}

# Render all available CV versions
[group("render")]
render-all:
    @echo "Rendering all CV versions..."
    @for version in versions/*.yml; do \
        name=$(basename "$version" .yml); \
        echo "→ Rendering $name..."; \
        ./scripts/render.sh "$name"; \
    done
    @echo "✓ All versions rendered"

# Clean a specific version's output
[group("clean")]
[arg("VERSION", help="Version to clean, see 'just list'")]
[confirm("Are you sure you want to clean output for {{VERSION}}?")]
clean VERSION:
    @echo "Cleaning output for {{VERSION}}..."
    rm -rf output/{{VERSION}}
    @echo "✓ Cleaned"

# Clean all generated output files
[group("clean")]
[confirm("Are you sure you want to clean all output?")]
clean-all:
    @echo "Cleaning output directory..."
    rm -rf output/*
    @echo "✓ Cleaned"

# View a specific version's PDF
[group("view")]
[arg("VERSION", help="Version to view, see 'just list'")]
view VERSION: (render VERSION)
    @echo "Opening {{VERSION}} CV..."
    open output/{{VERSION}}/cv.pdf

# Show information about the CV system
[group("info")]
info:
    @echo "Quarto CV Build System"
    @echo "====================="
    @echo ""
    @echo "Data directory:    data/"
    @echo "Templates:         templates/"
    @echo "Versions:          versions/"
    @echo "Output:            output/"
    @echo ""
    @just list
    @echo ""

# List all available CV versions
[group("info")]
list:
    @echo "Available versions:"
    @for version in versions/*.yml; do \
        name=$(basename "$version" .yml); \
        echo "  - $name"; \
    done

# Run all validation checks
[group("validate")]
validate: validate-yaml spell-check format-python lint-r
    @echo "✓ All validation checks passed"

# Validate YAML files
[group("validate")]
validate-yaml:
    @echo "Validating YAML files..."
    @yamllint -c .yamllint.yml data/ versions/
    @echo "✓ YAML validation passed"

# Check spelling across all files
[group("validate")]
spell-check:
    @echo "Checking spelling..."
    @codespell --ignore-words=.codespell-ignore --skip="*.pdf,output/*,*.typ,.git" \
        --check-filenames --check-hidden
    @echo "✓ Spell check passed"

# Format Python files with ruff
[group("validate")]
format-python:
    @echo "Formatting Python files..."
    @if command -v ruff >/dev/null 2>&1; then \
        ruff check --select I --fix scripts/; \
        ruff format scripts/; \
        echo "✓ Python files formatted"; \
    else \
        echo "Error: ruff not found"; \
        exit 1; \
    fi

# Lint and style R code (Quarto templates)
[group("validate")]
lint-r:
    @echo "Linting and styling R code..."
    @if command -v Rscript >/dev/null 2>&1; then \
        Rscript -e "lintr::lint('templates/cv.qmd', cache=FALSE)"; \
        Rscript -e "styler::style_file('templates/cv.qmd', strict=TRUE)"; \
        echo "✓ R code linted and formatted"; \
    else \
        echo "Error: R not found"; \
        exit 1; \
    fi

# Run pre-commit checks manually on all files
[group("validate")]
check:
    @echo "Running pre-commit checks on all files..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit run --all-files; \
    else \
        echo "Error: pre-commit not found"; \
        exit 1; \
    fi

# Install pre-commit hooks
[group("validate")]
install-hooks:
    @echo "Installing pre-commit hooks..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit install; \
        echo "✓ Pre-commit hooks installed"; \
    else \
        echo "Error: pre-commit not found"; \
        exit 1; \
    fi

# Show help for all recipes
[group("help")]
help:
    @just --list --unsorted --justfile {{justfile()}}
    @echo ""
    @echo "Use 'just usage RECIPE' for details on a specific command"

# List recipes
[group("help")]
recipes:
    @just --summary --unsorted --justfile {{justfile()}}

# Show recipe usage
[group("help")]
usage RECIPE:
    @just --usage {{RECIPE}} --justfile {{justfile()}}
