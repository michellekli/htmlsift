# Main application route: orchestrates reactive state across modules

box::use(
  bslib[...],
  shiny[...],
)

box::use(
  logger[log_info, log_warn, log_error],
)

box::use(
  ../config[import_python],
  ../components/htmlInput,
  ../components/pathList,
  ../components/extractionModal,
  pathPreviewZone = ../components/pathPreview/zone
)

parser <- import_python("parser")

#' Main application UI
#'
#' @return A `page_sidebar()` layout with HTML input sidebar and path list.
#' @export
ui <- function() {
  page_sidebar(
    title = "htmlsift",
    sidebar = sidebar(
      width = 300,
      htmlInput$ui("html_config")
    ),
    layout_columns(
      pathList$ui("path_list"),
      pathPreviewZone$ui("path_preview_zone"),
      col_widths = c(5, 7)
    )
  )
}


#' Main application server
#'
#' Coordinates reactive state across modules for HTML parsing
#' and path extraction.
#'
#' @param input Standard Shiny input object.
#' @param output Standard Shiny output object.
#' @param session Standard Shiny session object.
#' @export
server <- function(input, output, session) {
  # ----------------------
  # --- REACTIVE STATE ---
  # ----------------------
  # Init state
  sanitized_html <- reactiveVal(NULL)
  parsed_tree_root <- reactiveVal(NULL)
  parsed_paths <- reactiveVal(NULL)
  selected_path <- reactiveVal(NULL)
  extraction_path <- reactiveVal(NULL)

  # Clean up reactive values when the session ends
  clear_html_derivatives <- function() {
    parsed_tree_root(NULL)
    parsed_paths(NULL)
    selected_path(NULL)
    extraction_path(NULL)
  }
  session$onSessionEnded(function() {
    sanitized_html(NULL)
    clear_html_derivatives()

    gc()
  })

  # Pass state for communication
  htmlInput$server("html_config", sanitized_html)
  pathList$server("path_list",
                  paths = parsed_paths,
                  selected_path = selected_path)
  pathPreviewZone$server("path_preview_zone",
                         selected_path,
                         parsed_tree_root,
                         extraction_path)
  extractionModal$server("extraction_modal",
                         extraction_path,
                         parsed_tree_root)

  # ----------------------
  # --- EVENT HANDLING ---
  # ----------------------
  # Handle change in stored HTML
  observeEvent(sanitized_html(), {
    # Clear state for saved HTML values
    clear_html_derivatives()

    log_info("Parsing sanitized HTML...")
    tryCatch({
      withProgress(
        message = "Parsing HTML...",
        value = 0.5,
        {
          tree <- parser$parse_html_to_tree(sanitized_html())

          # Update state to store parsed tree object
          parsed_tree_root(tree)

          # Update state to store parsed paths
          tree |>
            parser$get_path_stats() |>
            do.call(rbind, args = _) |>
            data.frame() |>
            parsed_paths()

          log_info("HTML parsed successfully")
        }
      )
    }, error = function(e) {
      log_error("Unable to parse HTML: {e$message}")
      showNotification(
        paste("Unable to parse HTML:", e$message),
        type = "error",
        duration = NULL
      )
    })
  })

  # Handle change in extraction_path
  observeEvent(extraction_path(), {
    path <- extraction_path()
    req(!is.null(path), nchar(path) > 0)

    log_info("Path to extract: {path}")
    showModal(extractionModal$ui("extraction_modal"))
  })
}
