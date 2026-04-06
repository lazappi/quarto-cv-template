# Quarto CV Template

A flexible CV template powered by Quarto and Typst using the [Neat CV](https://github.com/dialvarezs/neat-cv) template.

## Features

- Content is stored as YAML files (see `data/`)
- Structure is defined using YAML config files (see `versions/`)
  - A new version with selected sections and entries can be created without needing to modify the content files
- Simple commands for rendering etc.
- Automated checks for spelling etc.

## Quick Start

1. Edit your content:

- `data/config.yml`      (Document settings)
- `data/meta.yml`        (Personal metadata)
- `data/sidebar.yml`     (Sidebar entries)
- `data/sections/*.yml`  (Section content)

2. Render a CV version:

```bash
just render full
just render short
```

3. Find output PDFs in:

- `output/full.pdf`
- `output/short.pdf`

## Prerequisites

**Software:**

- [Quarto](https://quarto.org/)
- [R](https://cran.r-project.org/)
  - [**{yaml}**](https://yaml.r-lib.org/)
  - [**{glue}**](https://glue.tidyverse.org/)
  - [**{purrr}**](https://purrr.tidyverse.org/)
- [`just`](https://just.systems/)

**Fonts:**

- [Fira Sans](https://fonts.google.com/specimen/Fira+Sans)
- [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)
- [Noto Sans Mono](https://fonts.google.com/specimen/Noto+Sans+Mono)
- [FontAwesome](https://fontawesome.com)

Fonts can be set in `config.yml` but FontAwesome is always required for symbols.

**Development:**

- [`pre-commit`](https://pre-commit.com/)
- [`yamllint`](https://yamllint.readthedocs.io/en/stable/)
- [`codespell`](https://github.com/codespell-project/codespell)
- [`ruff`](https://docs.astral.sh/ruff)
- [**{lintr}**](https://lintr.r-lib.org/)
- [**{styler}**](https://styler.r-lib.org/)
- [Poppler](https://poppler.freedesktop.org/)

## Repository structure

```text
.
├── data/  
│   ├── config.yml            # Document-level settings
│   ├── meta.yml              # Personal metadata
│   ├── sidebar.yml           # Sidebar content
│   └── sections/             # Section content files
├── docs/
│   └── previews/             # PNG previews used in the README
├── output/                   # Rendered PDFs
├── scripts/
│   ├── render-previews.sh    # Generate PNG previews from rendered PDFs
│   └── render.sh             # Render a CV version with Quarto
├── templates/
│   └── cv.qmd                # Main Quarto CV template
├── versions/                 # Version definitions
├── justfile                  # Command recipes
├── README.md                 # This README
├── .codespell-ignore         # Words ignored by codespell
├── .pre-commit-config.yaml   # pre-commit config file
└── .yamllint.yml             # YAMLLint config file
```

## Commands

Run `just` to see the available commands:

```bash
Available recipes:
    default                   # Show help

    [render]
    render VERSION            # Render a specific CV version by name
    render-all                # Render all available CV versions
    render-previews *VERSIONS # Export preview PNGs from existing PDFs
    refresh-previews          # Render all versions and regenerate preview PNGs

    [clean]
    clean VERSION             # Clean a specific version's output
    clean-all                 # Clean all generated output files

    [view]
    view VERSION              # View a specific version's PDF

    [validate]
    validate                  # Run all validation checks
    validate-yaml             # Validate YAML files
    spell-check               # Check spelling across all files
    format-python             # Format Python files with ruff
    lint-r                    # Lint and style R code (Quarto templates)
    check                     # Run pre-commit checks manually on all files
    install-hooks             # Install pre-commit hooks

    [info]
    info                      # Show information about the CV system
    list                      # List all available CV versions

    [help]
    help                      # Show help for all recipes
    recipes                   # List recipes
    usage RECIPE              # Show recipe usage

Use 'just usage RECIPE' for details on a specific command
```

`just render-previews` only exports PNG previews from PDFs already present in `output/`.
Use `just refresh-previews` when you want to re-render CV PDFs first and then update previews.

The underlying `scripts/render-previews.sh` script now only exports previews; rendering is handled separately by `just render-all` or `just refresh-previews`.

## Output Examples

### Full Version

Including all example entries

<img src="docs/previews/full-page-1.png" alt="Full Page 1" width="49%"/> <img src="docs/previews/full-page-2.png" alt="Full Page 2" width="49%"/>

### Short Version

Including selected entries

<img src="docs/previews/short-page-1.png" alt="Short Page 1" width="49%"/> <img src="docs/previews/short-page-2.png" alt="Short Page 2" width="49%"/>

## Versions reference

To create a new CV version, create a new YAML file in `versions/`.
The structure of the file is:

```yaml
sections:
  - name: Section                  # Section name
    type: section                  # Section type
    data: education.yml            # File containing data for this section (in `data/sections/`)
    title_field: title             # Field in section items to use as the title
    institution_field: institution # Field in section items to use as the institution
    location_field: location       # Field in section items to use as the location
    date_field: date               # Field in section items to use as the date
    from_field: from               # Field in section items to use as the from date
    to_field: to                   # Field in section items to use as the to date
    desc_field: description        # Field in section items to use as the description
    url_fields: [field1, field2]   # Fields to format as URLs (default: None)
    entries: all                   # Which entries to include in the section
```

**Notes:**

- `type` can be `"publications"` for rendering publication references or `"new-page"` to start a new page.
  Anything else is ignored and a standard section is rendered.
- The `*_field` fields map fields in the data YAML to fields used by the Neat CV template
- `entries` can contain a list of entry IDs to include selected entries:

    ```yaml
        entries:
        - entry1
        - entry2
    ```

Publications sections can have the following additional fields:

```yaml
    highlight_authors: ["Last, First"]  # Names to highlight in author lists
    joint_authorship: NULL              # Symbol to indicate joint authorship, e.g. "\*"
```

## Development notes

This currently uses version 0.4.0 of the Neat CV template as more recent versions require a newer version of Typst than is included with Quarto.
This should be updated in the future.
