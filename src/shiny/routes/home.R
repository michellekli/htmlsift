box::use(
  bslib[...],
  shiny[...],
  reticulate[import_from_path],
)

box::use(
  ../components/htmlInput,
  ../components/pathList
)

parser <- import_from_path("parser", here::here("src", "python"))

#' @export
ui <- function() {
  page_sidebar(
    title = "htmlsift",
    sidebar = sidebar(
      width = 400,
      htmlInput$ui("html_config")
    ),
    layout_columns(
      pathList$ui("path_list"),
      card(
        card_header("Selected Path"),
        card_body(
          verbatimTextOutput("selected_output")
        )
      )
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
  parsed_paths <- reactiveVal(NULL)
  selected_path <- reactiveVal(NULL)

  # Pass state for communication
  htmlInput$server("html_config", sanitized_html)
  pathList$server("path_list",
                  paths = parsed_paths,
                  selected_path = selected_path)

  # ----------------------
  # --- EVENT HANDLING ---
  # ----------------------
  # Handle change in stored HTML
  observeEvent(sanitized_html(), isolate({
    sanitized_html() |>
      parser$parse_html_to_tree() |>
      parser$get_path_frequencies() |>
      do.call(rbind, args = _) |> # turn list of lists into a matrix
      data.frame() |>
      parsed_paths()
  }))

  # Handle change in selected path
  observeEvent(selected_path(), isolate({
    # Display selected path for demonstration
    output$selected_output <- renderPrint({
      if (is.null(selected_path())) {
        "No path selected"
      } else {
        cat("Selected path:\n")
        cat(selected_path())
      }
    })
  }))

}
