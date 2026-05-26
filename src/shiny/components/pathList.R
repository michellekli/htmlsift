# Path list module: renders parsed paths in a selectable widget

box::use(
  bslib[...],
  shiny[...],
  DT,
)

box::use(
  logger[log_info],
)

#' Path list module UI
#'
#' @param id Module namespace identifier.
#' @return A card containing a DT data table for path selection.
#' @export
ui <- function(id) {
  ns <- NS(id)

  card(card_header("Select a path"), card_body(
    tooltip(
      DT::dataTableOutput(ns("dt")),
      "Click a row to preview content at that path."
    )
  ))
}

#' Path list module server
#'
#' Renders a data table of parsed paths and handles row selection.
#'
#' @param id Module namespace identifier.
#' @param paths A reactiveVal containing a data frame of path details.
#' @param selected_path A reactiveVal to store the selected path string.
#' @export
server <- function(id, paths, selected_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------
    # Init state
    # Create proxy to datatable for manipulation
    proxy <- DT::dataTableProxy(ns("dt"))

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle updates to stored paths
    output$dt <- DT::renderDataTable({
      req(paths())

      validate(
        need(
          all(
            c("frequency", "path", "first_text") %in% colnames(paths())
          ),
          "Path data is missing expected columns:
              (frequency, path, first_text)."
        )
      )
      df <- paths()[, c("frequency", "path", "first_text")]
      log_info("Rendering path table with {nrow(df)} rows")

      # Render the data table with single-row selection
      DT::datatable(
        df,
        colnames = c("Count", "Path", "First Text"),
        selection = list(mode = "single", target = "row"),
        options = list(
          fillContainer = TRUE,
          paging = TRUE,
          pageLength = 12,
          # Turn off searching because it doesn't search through all values
          searching = FALSE,
          ordering = FALSE,
          info = TRUE,
          columnDefs = list(
            list(className = "dt-right", targets = 0),
            list(className = "dt-left", targets = 1),
            list(className = "dt-left", targets = 2)
          )
        ),
        rownames = FALSE
      ) |>
        DT::formatStyle(
          columns = c("frequency", "path"),
          `max-width` = "25px",
          `white-space` = "nowrap",
          `overflow` = "hidden",
          `text-overflow` = "ellipsis"
        ) |>
        DT::formatStyle(
          columns = c("first_text"),
          `max-width` = "150px",
          `white-space` = "nowrap",
          `overflow` = "hidden",
          `text-overflow` = "ellipsis"
        )
    }) |>
      bindEvent(paths())

    # Handle row selection
    observeEvent(input$dt_rows_selected, {
      req(input$dt_rows_selected)
      req(paths())

      selected_row <- input$dt_rows_selected
      path_string <- paths()[["path"]][[selected_row]]

      log_info("Path selected: {path_string}")
      # Set state of selected_path
      selected_path(path_string)
    })

    # Handle selected_path being cleared
    observeEvent(selected_path(), {
      path <- selected_path()

      if (is.null(path)) {
        # Clear selection from datatable display
        DT::selectRows(proxy, NULL)
      }
    }, ignoreNULL = FALSE)
  })
}
