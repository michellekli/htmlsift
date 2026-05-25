# Displays the selected path string in a styled div

box::use(
  bslib[...],
  shiny[...],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  div(
    style = "margin-bottom: 15px; padding: 10px; border-radius: 4px;",
    "Selected Path: ",
    textOutput(ns("path_text"), inline = TRUE)
  )
}

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
    observeEvent(selected_path(), {
      req(selected_path())

      isolate({
        output$path_text <- renderText({
          tryCatch(selected_path(), error = function(e) {
            # Return error string for display
            "[Unable to display path]"
          })
        })
      })
    })

  })
}
