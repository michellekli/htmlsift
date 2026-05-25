box::use(
  bslib[...],
  shiny[...],
)

#' Path list module UI
#'
#' @param id Module namespace identifier.
#' @return A card containing a DT data table for path selection.
#' @export
ui <- function(id) {
  ns <- NS(id)

  card(
    card_header("Select a path"),
    card_body(
      tooltip(
        DT::dataTableOutput(ns("dt")),
        "Click a row to preview content at that path."
      )
    )
  )
}

#' Path list module server
#'
#' Renders a data table of parsed paths and handles row selection.
#'
#' @param id Module namespace identifier.
#' @param paths A reactive data frame path details.
#' @param selected_path A reactiveVal to store the selected path string.
#' @export
server <- function(id, paths, selected_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # -----------------------
    # --- REACTIVE STATE ----
    # -----------------------
    # Init state
    # Create proxy to datatable for manipulation
    proxy <- DT::dataTableProxy(ns("dt"))

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle updates to stored paths
    observeEvent(paths(), isolate({
      req(paths())

      tryCatch({
        validate(
          need(
            all(c("frequency", "path", "first_text") %in% colnames(paths())),
            "Path data is missing expected columns:
              (frequency, path, first_text)."
          )
        )
        df <- paths()[, c("frequency", "path", "first_text")]

        # Render the data table with single-row selection
        output$dt <- DT::renderDataTable({
          DT::datatable(
            df,
            colnames = c("Count", "Path", "First Text"),
            selection = list(mode = "single", target = "row"),
            options = list(
              fillContainer = TRUE,
              paging = FALSE,
              searching = TRUE,
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
              columns = c(1, 2),
              `max-width` = "25px",
              `white-space` = "nowrap",
              `overflow` = "hidden",
              `text-overflow` = "ellipsis"
            ) |>
            DT::formatStyle(
              columns = c(3),
              `max-width` = "150px",
              `white-space` = "nowrap",
              `overflow` = "hidden",
              `text-overflow` = "ellipsis"
            )
        })
      }, error = function(e) {
        showNotification(
          paste("Unable to show paths for selection:", e$message),
          type = "error"
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

    # Handle selected_path being cleared
    observeEvent(selected_path(), isolate({
      path <- selected_path()

      if (is.null(path)) {
        # Clear selection from datatable display
        DT::selectRows(
          proxy,
          NULL
        )
      }
    }), ignoreNULL = FALSE)
  })
}
