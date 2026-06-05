#!/usr/bin/env Rscript
# Utility functions for fetching GitHub repository statistics

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop(
    "Package 'jsonlite' is required to fetch GitHub stats. ",
    "Install it with: install.packages('jsonlite')",
    call. = FALSE
  )
}

#' Fetch GitHub repository statistics (stars and forks)
#'
#' @param repo Repository in "owner/repo" format
#'
#' @return A list with `stars` and `forks` counts, or NULL on failure
fetch_github_stats <- function(repo) {
  tryCatch(
    {
      url <- paste0("https://api.github.com/repos/", repo)
      data <- jsonlite::fromJSON(url)
      list(stars = data$stargazers_count, forks = data$forks_count)
    },
    error = function(e) {
      warning(
        "Failed to fetch GitHub stats for '", repo, "': ",
        conditionMessage(e),
        call. = FALSE
      )
      NULL
    }
  )
}

#' Format GitHub stats as a plain-text string
#'
#' @param stats A list with `stars` and `forks` counts
#'
#' @return A formatted string like "42 stars, 10 forks"
format_github_stats <- function(stats) {
  paste0(stats$stars, " stars, ", stats$forks, " forks")
}

#' Add GitHub stats to an entry
#'
#' For each entry that contains a `github` field, fetches repository statistics
#' from the GitHub API and appends them to the title field.
#'
#' @param entries List of section entry data
#' @param title_field Name of the title field to append stats to
#'
#' @return Entries with GitHub stats appended to titles where applicable
add_github_stats <- function(entries, title_field = "title") {
  purrr::map(entries, function(entry) {
    if (!is.null(entry$github)) {
      stats <- fetch_github_stats(entry$github)
      if (!is.null(stats)) {
        title <- entry[[title_field]] %||% ""
        entry[[title_field]] <- paste0(
          title, " (", format_github_stats(stats), ")"
        )
      }
    }
    entry
  })
}
