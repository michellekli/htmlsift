# Shared application configuration

box::use(
  reticulate[import_from_path],
)

box::use(
  logger[log_info, log_error],
)

python_dir <- here::here("src", "python")

#' Import a Python module by name from the project's python directory
#'
#' @param name Module name (without `.py` extension)
#' @return The imported Python module
#' @export
import_python <- function(name) {
  log_info("Importing Python module: {name}")
  tryCatch({
    import_from_path(name, python_dir)
  }, error = function(e) {
    log_error("Failed to import Python module '{name}': {e$message}")
    stop("Unable to import Python module '", name, "': ", e$message)
  })
}
