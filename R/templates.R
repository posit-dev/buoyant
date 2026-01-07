#' Create a _server.yml template application
#'
#' Copies a template _server.yml application to a specified directory.
#' This is useful for quickly starting a new project with the correct structure.
#'
#' @param path The directory where the template should be created. Will be created
#'   if it doesn't exist.
#' @param engine The engine to use. One of "plumber2", "fiery", or "generic".
#' @param overwrite If `TRUE`, will overwrite existing files. If `FALSE` (default),
#'   will error if files already exist.
#'
#' @return Invisibly returns the path to the created template.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a plumber2 template
#' create_template("my-api", engine = "plumber2")
#'
#' # Create a fiery template
#' create_template("my-fiery-app", engine = "fiery")
#' }
create_template <- function(path, engine = c("plumber2", "fiery", "generic"),
                           overwrite = FALSE) {
  engine <- match.arg(engine)

  # Get template directory
  template_dir <- system.file("templates", engine, package = "buoyant")

  if (!dir.exists(template_dir) || length(list.files(template_dir)) == 0) {
    stop("Template for engine '", engine, "' not found in package installation.")
  }

  # Create target directory if needed
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  # Check if _server.yml already exists
  server_yml_path <- file.path(path, "_server.yml")
  if (file.exists(server_yml_path) && !overwrite) {
    stop("_server.yml already exists at ", path, ". Use overwrite = TRUE to replace it.")
  }

  # Copy all files from template
  template_files <- list.files(template_dir, full.names = TRUE, recursive = TRUE)

  for (template_file in template_files) {
    rel_path <- sub(paste0(template_dir, "/"), "", template_file)
    target_file <- file.path(path, rel_path)

    if (file.exists(target_file) && !overwrite) {
      message("Skipping existing file: ", rel_path)
      next
    }

    file.copy(template_file, target_file, overwrite = overwrite)
    message("Created: ", rel_path)
  }

  message("\nTemplate created successfully at: ", normalizePath(path))
  message("Edit the _server.yml file to configure your application.")

  if (engine == "plumber2") {
    message("\nTo run locally:")
    message("  plumber2::api('", path, "')")
  } else if (engine == "fiery") {
    message("\nTo run locally, see fiery documentation.")
  }

  invisible(path)
}


#' List available templates
#'
#' Lists all available _server.yml templates that can be used with [create_template()].
#'
#' @return A character vector of available template names.
#'
#' @export
#' @examples
#' list_templates()
list_templates <- function() {
  templates_dir <- system.file("templates", package = "buoyant")

  if (!dir.exists(templates_dir)) {
    return(character(0))
  }

  templates <- list.dirs(templates_dir, full.names = FALSE, recursive = FALSE)
  templates <- templates[templates != ""]

  if (length(templates) == 0) {
    message("No templates found.")
    return(invisible(character(0)))
  }

  message("Available templates:")
  for (template in templates) {
    message("  - ", template)
  }

  invisible(templates)
}
