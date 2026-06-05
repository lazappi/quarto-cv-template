#!/usr/bin/env Rscript
# Render CV to Markdown format
# Usage: Rscript scripts/render-markdown.R

suppressPackageStartupMessages({
  library(yaml)
  library(glue)
  library(purrr)
  library(jsonlite)
})

workspace_dir <- Sys.getenv("WORKSPACE_DIR", ".")
source(file.path(workspace_dir, "scripts/github-stats.R"))
version_file <- Sys.getenv("CV_VERSION")
version_name <- sub("\\.yml$", "", basename(version_file))
output_file <- file.path(workspace_dir, "output", paste0(version_name, ".md"))

# Load all required data
meta <- read_yaml(file.path(workspace_dir, "data/meta.yml"))
version_config <- read_yaml(version_file)
sidebar <- read_yaml(file.path(workspace_dir, "data/sidebar.yml"))

# Initialize markdown lines
md_lines <- c()

# Title and position
md_lines <- c(md_lines, paste0("# ", meta$firstname, " ", meta$lastname), "")
positions_str <- paste(meta$positions, collapse = " • ")
md_lines <- c(md_lines, paste0("*", positions_str, "*"), "")

# Contact section
md_lines <- c(md_lines, "## Contact", "")
if (!is.null(meta$email)) {
  md_lines <- c(md_lines, paste0("- **Email**: ", meta$email))
}
if (!is.null(meta$phone)) {
  md_lines <- c(md_lines, paste0("- **Phone**: ", meta$phone))
}
if (!is.null(meta$address)) {
  md_lines <- c(md_lines, paste0("- **Address**: ", meta$address))
}
md_lines <- c(md_lines, "")

# Social section
md_lines <- c(md_lines, "## Social", "")
if (!is.null(meta$website)) {
  md_lines <- c(md_lines, paste0("- **Website**: ", meta$website))
}
if (!is.null(meta$twitter)) {
  md_lines <- c(md_lines, paste0("- **Twitter**: @", meta$twitter))
}
if (!is.null(meta$mastodon)) {
  md_lines <- c(md_lines, paste0("- **Mastodon**: ", meta$mastodon))
}
if (!is.null(meta$linkedin)) {
  md_lines <- c(md_lines, paste0("- **LinkedIn**: ", meta$linkedin))
}
if (!is.null(meta$custom_links)) {
  for (link in meta$custom_links) {
    md_lines <- c(md_lines, paste0("- **", link$label, "**: ", link$url))
  }
}
md_lines <- c(md_lines, "")

# Sidebar sections
for (section in sidebar) {
  if (
    !is.null(section$type) &&
      section$type %in% c("contact", "social", "new-page", "align-bottom")
  ) {
    next
  }

  if (!is.null(section$title)) {
    md_lines <- c(md_lines, paste0("## ", section$title), "")
  }

  if (section$type == "text") {
    md_lines <- c(md_lines, section$content, "")
  }

  if (section$type == "list") {
    for (item in section$items) {
      md_lines <- c(md_lines, paste0("- ", item))
    }
    md_lines <- c(md_lines, "")
  }

  if (section$type == "levels") {
    for (item in section$items) {
      if (!is.null(item$subtitle)) {
        md_lines <- c(
          md_lines,
          paste0("- **", item$name, "** (", item$subtitle, ")")
        )
      } else {
        md_lines <- c(md_lines, paste0("- **", item$name, "**"))
      }
    }
    md_lines <- c(md_lines, "")
  }

  if (section$type == "pills") {
    pills_str <- paste(section$items, collapse = ", ")
    md_lines <- c(md_lines, paste0("*", pills_str, "*"), "")
  }
}

# Process sections
load_section_items <- function(filename, entries) {
  data_path <- file.path(workspace_dir, "data", "sections", filename)
  data <- read_yaml(data_path)

  if (length(entries) == 1 && entries == "all") {
    return(data)
  }

  result <- list()
  for (entry in data) {
    if (!is.null(entry$id) && entry$id %in% entries) {
      result[[length(result) + 1]] <- entry
    }
  }
  result
}

# Process version sections
for (section_config in version_config$sections) {
  if (!is.null(section_config$type) && section_config$type == "new-page") {
    next
  }

  if (is.null(section_config$data)) {
    next
  }

  data_path <- file.path(workspace_dir, "data", "sections", section_config$data)
  if (!file.exists(data_path)) {
    next
  }

  md_lines <- c(md_lines, paste0("## ", section_config$name), "")

  # Handle publications
  if (!is.null(section_config$type) && section_config$type == "publications") {
    publications <- read_yaml(data_path)
    pub_ids <- section_config$entries

    for (pub_key in names(publications)) {
      pub <- publications[[pub_key]]
      if (length(pub_ids) > 1 || pub_ids != "all") {
        if (is.null(pub$id) || !(pub$id %in% pub_ids)) {
          next
        }
      }

      citation <- paste(pub$author, collapse = ", ")
      if (!is.null(pub$title)) {
        title_part <- paste0("**", pub$title, "**")
        if (!is.null(pub$year)) {
          title_part <- paste0(title_part, " (", pub$year, ")")
        }
        citation <- paste(citation, title_part, sep = ". ")
      }
      if (!is.null(pub$journal)) {
        citation <- paste0(citation, ". *", pub$journal, "*")
      }

      md_lines <- c(md_lines, paste0("- ", citation))
    }
  } else {
    # Regular sections
    section_data <- load_section_items(
      section_config$data,
      section_config$entries
    )

    if (isTRUE(section_config$github_stats)) {
      section_data <- add_github_stats(
        section_data,
        title_field = section_config$title_field %||% "title"
      )
    }

    for (entry in section_data) {
      title <- entry[[section_config$title_field %||% "title"]] %||% ""
      institution <- entry[[section_config$institution_field %||% "institution"]] %||% ""
      location <- entry[[section_config$location_field %||% "location"]] %||% ""

      date <- entry[[section_config$date_field %||% "date"]]
      if (is.null(date)) {
        from_date <- entry[[section_config$from_field %||% "from"]]
        to_date <- entry[[section_config$to_field %||% "to"]]
        if (!is.null(from_date) && !is.null(to_date)) {
          date <- paste(from_date, to_date, sep = " <U+2013> ")
        } else if (!is.null(from_date)) {
          date <- from_date
        }
      }

      entry_header <- ""
      if (title != "") entry_header <- paste0("**", title, "**")
      if (institution != "" || location != "") {
        parts <- c()
        if (institution != "") parts <- c(parts, institution)
        if (location != "") parts <- c(parts, location)
        inst_str <- paste(parts, collapse = ", ")
        if (entry_header != "") {
          entry_header <- paste0(entry_header, " <U+2014> *", inst_str, "*")
        } else {
          entry_header <- paste0("*", inst_str, "*")
        }
      }
      if (!is.null(date) && date != "") {
        entry_header <- paste0(entry_header, " (", date, ")")
      }

      if (entry_header != "") {
        md_lines <- c(md_lines, entry_header)
      }

      desc <- entry[[section_config$desc_field %||% "description"]]
      if (!is.null(desc)) {
        md_lines <- c(md_lines, trimws(desc))
      }

      md_lines <- c(md_lines, "")
    }
  }

  md_lines <- c(md_lines, "")
}

# Write markdown file
writeLines(md_lines, output_file)
cat(paste0("✓ Markdown written to ", output_file, "\n"))
