box::use(
  bslib[...],
  shiny[...],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  card(
    card_header("Paths"),
    card_body(
      DT::dataTableOutput(ns("dt"))
    )
  )
}

#' @export
server <- function(id, paths, selected_path) {
  moduleServer(id, function(input, output, session) {
    # -----------------------
    # --- REACTIVE STATE ----
    # -----------------------

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle updates to stored paths
    observeEvent(paths(), isolate({
      req(paths())

      df <- paths()

      # Render the data table with single-row selection
      output$dt <- DT::renderDataTable({
        DT::datatable(
          df,
          colnames = c("Path", "Frequency"),
          selection = list(mode = "single", target = "row"),
          options = list(
            scrollY = "400px",
            paging = FALSE,
            searching = FALSE,
            ordering = FALSE,
            info = FALSE,
            columnDefs = list(
              list(className = "dt-left", targets = 0),
              list(className = "dt-right", targets = 1)
            )
          ),
          rownames = FALSE
        )
      })
    }))

    # Handle row selection
    observeEvent(input$dt_rows_selected, isolate({
      req(input$dt_rows_selected)
      req(paths())

      selected_row <- input$dt_rows_selected
      path_string <- paths()[["path"]][[selected_row]]

      # Set state of selected_path
      selected_path(path_string)
    }))
  })
}
