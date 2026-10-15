#!/usr/bin/env Rscript
# Utility functions for fetching GitHub repository statistics

for (pkg in c("jsonlite", "curl")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      "Package '", pkg, "' is required to fetch GitHub stats. ",
      "Install it with: install.packages('", pkg, "')",
      call. = FALSE
    )
  }
}

#' Fetch GitHub repository statistics (stars and forks)
#'
#' If the `GITHUB_TOKEN` environment variable is set it is used to authenticate
#' requests, which raises the API rate limit (60 requests per hour otherwise).
#'
#' @param repo Repository in "owner/repo" format
#'
#' @return A list with `stars` and `forks` counts, or NULL on failure
fetch_github_stats <- function(repo) {
  tryCatch(
    {
      url <- paste0("https://api.github.com/repos/", repo)
      token <- Sys.getenv("GITHUB_TOKEN")
      handle <- curl::new_handle()
      if (nzchar(token)) {
        curl::handle_setheaders(handle, Authorization = paste("token", token))
      }
      response <- curl::curl_fetch_memory(url, handle = handle)
      data <- jsonlite::fromJSON(rawToChar(response$content))
      if (response$status_code != 200) {
        stop("HTTP ", response$status_code, ": ", data$message, call. = FALSE)
      }
      list(
        org = data$owner$login,
        repo = data$name,
        stars = data$stargazers_count,
        forks = data$forks_count
      )
    },
    error = function(e) {
      warning(
        "Failed to fetch GitHub stats for '", repo, "': ",
        conditionMessage(e),
        call. = FALSE
      )
      list(org = "organisation", repo = "repository", stars = "X", forks = "Y")
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
#' @param field Name of the field to append stats to
#' @param format Format string for how to display the stats. Use `{field}` to
#'   insert the original field value, and `{stars}` and `{forks}` for the stats
#'   values.
#'
#' @return Entries with GitHub stats appended to titles where applicable
add_github_stats <- function(entries, field = "title", format = "{field} ({stars} stars, {forks} forks)") {
  purrr::map(entries, function(entry) {
    if (!is.null(entry$github)) {
      stats <- fetch_github_stats(entry$github)
      if (!is.null(stats)) {
        entry[[field]] <- glue::glue(
          format,
          field = entry[[field]] %||% "",
          org = stats$org,
          repo = stats$repo,
          stars = stats$stars,
          forks = stats$forks
        )
      }
    }
    entry
  })
}
