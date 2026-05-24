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

      df <- paths()[, c("frequency", "path", "first_text")]

      # Render the data table with single-row selection
      output$dt <- DT::renderDataTable({
        DT::datatable(
          df,
          colnames = c("Frequency", "Path", "First Text"),
          selection = list(mode = "single", target = "row"),
          options = list(
            fillContainer = TRUE,
            paging = FALSE,
            searching = TRUE,
            ordering = FALSE,
            info = FALSE,
            columnDefs = list(
              list(className = "dt-right", targets = 0),
              list(className = "dt-left", targets = 1),
              list(className = "dt-left", targets = 2)
            )
          ),
          rownames = FALSE
        ) |>
          DT::formatStyle(
            columns = c(1, 2),  # 1-based for formatStyle
            `max-width` = "25px",
            `white-space` = "nowrap",
            `overflow` = "hidden",
            `text-overflow` = "ellipsis"
          ) |>
          DT::formatStyle(
            columns = c(3),  # 1-based for formatStyle
            `max-width` = "150px",
            `white-space` = "nowrap",
            `overflow` = "hidden",
            `text-overflow` = "ellipsis"
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
