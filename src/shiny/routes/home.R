box::use(
  bslib[...],
  shiny[...],
)

box::use(
  ../components/htmlInput,
  ../components/pathList,
  pathPreviewModal = ../components/pathPreview/modal
)

parser <- tryCatch(
  reticulate::import_from_path("parser", here::here("src", "python")),
  error = function(e) {
    stop("Unable to import Python parser module: ", e$message)
  }
)

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
      card(
        card_header("Selected Path"),
        card_body(
          verbatimTextOutput("selected_output")
        )
      ),
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
  # -----------------------
  # --- REACTIVE STATE ----
  # -----------------------
  # Init state
  sanitized_html <- reactiveVal(NULL)
  parsed_tree_root <- reactiveVal(NULL)
  parsed_paths <- reactiveVal(NULL)
  selected_path <- reactiveVal(NULL)
  extraction_path <- reactiveVal(NULL)

  # Clean up reactive values when the session ends
  session$onSessionEnded(function() {
    sanitized_html(NULL)
    parsed_tree_root(NULL)
    parsed_paths(NULL)
    selected_path(NULL)
    extraction_path(NULL)

    gc()
  })

  # Pass state for communication
  htmlInput$server("html_config", sanitized_html)
  pathList$server("path_list",
                  paths = parsed_paths,
                  selected_path = selected_path)
  pathPreviewModal$server("path_preview_modal",
                          selected_path,
                          parsed_tree_root,
                          extraction_path)

  # ----------------------
  # --- EVENT HANDLING ---
  # ----------------------
  # Handle change in stored HTML
  observeEvent(sanitized_html(), {
    withProgress(
      message = "Parsing HTML...",
      value = 0.5,
      {
        tryCatch({
          tree <- parser$parse_html_to_tree(sanitized_html())

          # Update state to store parsed tree object
          parsed_tree_root(tree)

          # Update state to store parsed paths
          tree |>
            parser$get_path_stats() |>
            do.call(rbind, args = _) |>
            data.frame() |>
            parsed_paths()
        }, error = function(e) {
          showNotification(
            paste("Unable to parse HTML:", e$message),
            type = "error",
            duration = NULL
          )
        })
      }
    )
  })

  # Handle change in selected_path
  observeEvent(selected_path(), {
    path <- selected_path()
    req(!is.null(path), nchar(path) > 0)

    showModal(pathPreviewModal$ui("path_preview_modal"))
  })

  # Handle change in extraction_path
  observeEvent(extraction_path(), {
    # Display extraction path for demonstration
    output$selected_output <- renderPrint({
      validate(need(extraction_path(), "No path selected for extraction"))
      cat("Extraction path:\n")
      cat(extraction_path())
    })
  })
}
