box::use(
  bslib[...],
  shiny[...],
)

box::use(
  ./pathDisplay,
  ./previewAccordion
)

parser <- reticulate::import_from_path("parser", here::here("src", "python"))

#' @export
ui <- function(id) {
  ns <- NS(id)

  tagList(
    modalDialog(
      title = "Extract all content?",
      size = "l",
      # easyClose must not be allowed because no easy way to listen for it
      # and trigger the corresponding Cancel logic
      easyClose = FALSE,
      footer = NULL, # no footer, action buttons are at the top
      tagList(
        p("The first three items at this path are shown below."),
        div(
          class = "d-flex justify-content-end gap-2 mb-3",
          actionButton(ns("cancel"), "Cancel"),
          actionButton(ns("confirm"), "Extract", class = "btn-primary")
        )
      ),
      pathDisplay$ui(ns("path_display")),
      previewAccordion$ui(ns("preview_accordion"))
    )
  )
}

#' @export
server <- function(id, selected_path, parsed_tree_root, extraction_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # Init state
    preview_data <- reactiveVal(NULL)

    # Pass state for communication
    pathDisplay$server("path_display", selected_path)
    previewAccordion$server("preview_accordion", preview_data)

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in selected_path
    observeEvent(selected_path(), isolate({
      req(selected_path(), parsed_tree_root())
      path <- selected_path()
      root <- parsed_tree_root()

      # Update state with preview data for selected_path
      preview_data(parser$get_content_for_path(root,
                                               path,
                                               limit = as.integer(3)))
    }))

    # Handle Confirm button click
    observeEvent(input$confirm, isolate({
      # Update state with path for extraction
      extraction_path(selected_path())

      # Close modal
      removeModal()
    }))

    # Handle Cancel button click
    observeEvent(input$cancel, isolate({
      # Clear state for selected path
      selected_path(NULL)

      # Close modal
      removeModal()
    }))
  })
}
