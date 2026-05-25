box::use(
  bslib[...],
  shiny[...],
)

box::use(
  ../components/htmlInput,
  ../components/pathList,
  pathPreviewModal = ../components/pathPreview/modal
)

parser <- reticulate::import_from_path("parser", here::here("src", "python"))

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
  observeEvent(sanitized_html(), isolate({
    # todo error handling
    # Update state to store parsed tree object
    parsed_tree_root(parser$parse_html_to_tree(sanitized_html()))

    # Update state to store parsed paths
    parsed_tree_root() |>
      parser$get_path_stats() |>
      do.call(rbind, args = _) |> # turn list of lists into a matrix
      data.frame() |>
      parsed_paths()
  }))

  # Handle change in selected_path
  observeEvent(selected_path(), isolate({
    path <- selected_path()
    req(!is.null(path), nchar(path) > 0)

    # Show modal
    showModal(pathPreviewModal$ui("path_preview_modal"))
  }))

  # Handle change in extraction_path
  observeEvent(extraction_path(), isolate({
    # Display extraction path for demonstration
    output$selected_output <- renderPrint({
      if (is.null(extraction_path())) {
        "No path selected for extraction"
      } else {
        cat("Extraction path:\n")
        cat(extraction_path())
      }
    })
  }))

}
