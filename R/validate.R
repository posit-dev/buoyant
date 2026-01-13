#' Validate a _server.yml file
#'
#' Checks that a `_server.yml` file is properly formatted according to the
#' _server.yml standard. This includes verifying that the engine field exists
#' and that the specified engine package has a `launch_server()` function.
#'
#' @param path Path to the directory containing `_server.yml` or path to the
#'   `_server.yml` file itself.
#' @param check_engine Logical. If `TRUE`, checks that the engine package is
#'   installed and has a `launch_server()` function. Default is `FALSE` since
#'   the engine may not be installed locally but will be on the deployment target.
#' @param verbose Logical. If `TRUE`, prints validation progress messages.
#'
#' @return Invisibly returns `TRUE` if validation passes. Throws an error if
#'   validation fails.
#'
#' @details
#' The validation checks:
#' * The `_server.yml` file exists
#' * The file is valid YAML
#' * The required `engine` field is present and is a character string
#' * If `check_engine = TRUE`, verifies the engine package is installed and
#'   has a `launch_server()` function
#'
#' @export
#' @examples
#' \dontrun{
#' # Validate a directory containing _server.yml
#' validate_server_yml("path/to/api")
#'
#' # Validate and check that the engine is installed
#' validate_server_yml("path/to/api", check_engine = TRUE)
#' }
validate_server_yml <- function(path, check_engine = FALSE, verbose = TRUE) {
  # Normalize path to _server.yml file
  if (dir.exists(path)) {
    server_yml_path <- file.path(path, "_server.yml")
  } else if (basename(path) == "_server.yml") {
    server_yml_path <- path
  } else {
    stop(
      "Path must be a directory containing _server.yml or the _server.yml file itself"
    )
  }

  # Check file exists
  if (!file.exists(server_yml_path)) {
    stop("_server.yml file not found at: ", server_yml_path)
  }

  if (verbose) {
    message("Validating _server.yml at: ", server_yml_path)
  }

  # Read and parse YAML
  tryCatch(
    {
      config <- yaml::read_yaml(server_yml_path)
    },
    error = function(e) {
      stop("Failed to parse _server.yml as valid YAML: ", e$message)
    }
  )

  # Check required 'engine' field
  if (is.null(config$engine)) {
    stop("_server.yml must contain an 'engine' field")
  }

  if (!is.character(config$engine) || length(config$engine) != 1) {
    stop("'engine' field must be a single character string")
  }

  if (verbose) {
    message("Engine: ", config$engine)
  }

  # Optionally check that engine is installed and has launch_server()
  if (check_engine) {
    if (!requireNamespace(config$engine, quietly = TRUE)) {
      stop(
        "Engine package '",
        config$engine,
        "' is not installed. ",
        "Install it with: install.packages('",
        config$engine,
        "')"
      )
    }

    # Check for launch_server function
    has_launch_server <- tryCatch(
      {
        launch_fn <- get(
          "launch_server",
          envir = asNamespace(config$engine),
          mode = "function"
        )
        is.function(launch_fn)
      },
      error = function(e) {
        FALSE
      }
    )

    if (!has_launch_server) {
      stop(
        "Engine package '",
        config$engine,
        "' does not have a launch_server() function. ",
        "It may not be a valid _server.yml engine."
      )
    }

    if (verbose) {
      message(
        "Engine '",
        config$engine,
        "' is installed and has launch_server()"
      )
    }
  }

  if (verbose) {
    message("Validation successful!")
  }

  invisible(TRUE)
}


#' Read _server.yml configuration
#'
#' Reads and parses a `_server.yml` file, returning the configuration as a list.
#'
#' @param path Path to the directory containing `_server.yml` or path to the
#'   `_server.yml` file itself.
#'
#' @return A list containing the parsed YAML configuration.
#'
#' @export
#' @examples
#' \dontrun{
#' config <- read_server_yml("path/to/api")
#' print(config$engine)
#' }
read_server_yml <- function(path) {
  # Normalize path to _server.yml file
  if (dir.exists(path)) {
    server_yml_path <- file.path(path, "_server.yml")
  } else if (basename(path) == "_server.yml") {
    server_yml_path <- path
  } else {
    stop(
      "Path must be a directory containing _server.yml or the _server.yml file itself"
    )
  }

  if (!file.exists(server_yml_path)) {
    stop("_server.yml file not found at: ", server_yml_path)
  }

  yaml::read_yaml(server_yml_path)
}
