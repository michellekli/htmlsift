# Preview modal module: shows extracted content preview with confirm/cancel

box::use(
  bslib[...],
  shiny[...],
)

box::use(
  ../../config[import_python],
  ./pathDisplay,
  ./previewAccordion
)

parser <- tryCatch(
  import_python("parser"),
  error = function(e) {
    stop("Unable to import Python parser module: ", e$message)
  }
)

#' Path preview modal UI
#'
#' @param id Module namespace identifier.
#' @return A modal dialog with path display, preview accordion,
#' and confirm/cancel buttons.
#' @export
ui <- function(id) {
  ns <- NS(id)

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
        tooltip(
          actionButton(ns("cancel"), "Cancel"),
          "Cancel and return to path selection."
        ),
        tooltip(
          actionButton(ns("confirm"), "Extract", class = "btn-primary"),
          "Confirm extraction of content at the selected path."
        )
      )
    ),
    pathDisplay$ui(ns("path_display")),
    previewAccordion$ui(ns("preview_accordion"))
  )
}

#' Path preview modal server
#'
#' Loads preview data for the selected path and manages confirm/cancel workflow.
#'
#' @param id Module namespace identifier.
#' @param selected_path A reactiveVal with the currently selected path.
#' @param parsed_tree_root A reactiveVal with the parsed HTML tree.
#' @param extraction_path A reactiveVal to store the confirmed extraction path.
#' @export
server <- function(id, selected_path, parsed_tree_root, extraction_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # Init state
    preview_data <- reactiveVal(NULL)

    # Debounce
    get_preview_data_d <- debounce(reactive({
      c(selected_path(), parsed_tree_root())
    }), 200)

    # Clean up reactive values when the session ends
    session$onSessionEnded(function() {
      preview_data(NULL)

      gc()
    })

    # Pass state for communication
    pathDisplay$server("path_display", selected_path)
    previewAccordion$server("preview_accordion", preview_data)

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in selected_path or parsed_tree_root
    # Need both because of potential race condition
    observeEvent(get_preview_data_d(), {
      req(selected_path(), parsed_tree_root())
      path <- selected_path()
      root <- parsed_tree_root()

      tryCatch({
        withProgress(
          message = "Loading preview...",
          value = 0.5,
          {
            # Update state with preview data for selected_path
            preview_data(parser$get_content_for_path(root,
                                                     path,
                                                     limit = as.integer(3)))
          }
        )
      }, error = function(e) {
        showNotification(
          paste("Unable to get content for preview:", e$message),
          type = "error"
        )
        preview_data(NULL)
      })
    })

    # Handle Confirm button click
    observeEvent(input$confirm, {
      # Update state with path for extraction
      extraction_path(selected_path())

      # Close modal
      removeModal()
    })

    # Handle Cancel button click
    observeEvent(input$cancel, {
      # Clear state for selected path
      selected_path(NULL)

      # Close modal
      removeModal()
    })
  })
}
