# Shared application configuration

box::use(
  reticulate[import_from_path],
)

python_dir <- here::here("src", "python")

#' Import a Python module by name from the project's python directory
#'
#' @param name Module name (without `.py` extension)
#' @return The imported Python module
#' @export
import_python <- function(name) {
  import_from_path(name, python_dir)
}
