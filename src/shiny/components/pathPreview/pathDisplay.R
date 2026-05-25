# Displays the selected path string in a styled div

box::use(
  bslib[...],
  shiny[...],
)

#' Path display module UI
#'
#' @param id Module namespace identifier.
#' @return A styled div showing the selected path text.
#' @export
ui <- function(id) {
  ns <- NS(id)

  div(
    style = "margin-bottom: 15px; padding: 10px; border-radius: 4px;",
    "Selected Path: ",
    textOutput(ns("path_text"), inline = TRUE)
  )
}

#' Path display module server
#'
#' Updates the displayed path text when selected_path changes.
#'
#' @param id Module namespace identifier.
#' @param selected_path A reactiveVal containing the path string to display.
#' @export
server <- function(id, selected_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in selected_path
    output$path_text <- renderText({
      req(selected_path())

      validate(need(selected_path(), "No path selected."))
      selected_path()
    }) |> bindEvent(selected_path())
  })
}
