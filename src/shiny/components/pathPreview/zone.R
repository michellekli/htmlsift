# Path preview module: shows extracted content preview with confirm/cancel

box::use(
  bslib[...],
  shiny[...],
)

box::use(
  logger[log_info, log_error],
)

box::use(
  ../../config[import_python],
  ./pathDisplay,
  ./previewAccordion
)

parser <- import_python("parser")

#' Path preview modal UI
#'
#' @param id Module namespace identifier.
#' @return A card with path display, preview accordion, and confirm button.
#' @export
ui <- function(id) {
  ns <- NS(id)

  conditionalPanel(
    condition = "output.has_preview",
    ns = ns,
    card(
      card_header("The first three items at this path are shown below."),
      card_body(
        tooltip(
          actionButton(ns("confirm"), "Extract", class = "btn-primary"),
          "Confirm extraction of content at the selected path."
        )
      ),
      pathDisplay$ui(ns("path_display")),
      previewAccordion$ui(ns("preview_accordion"))
    )
  )
}

#' Path preview modal server
#'
#' Loads preview data for the selected path and manages confirm workflow.
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
    get_has_preview_d <- debounce(reactive({
      c(preview_data(), selected_path())
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

      log_info("Loading preview for path: {path}")
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
        log_info("Preview loaded for path: {path}")
      }, error = function(e) {
        log_error("Preview failed for path '{path}': {e$message}")
        showNotification(
          paste("Unable to get content for preview:", e$message),
          type = "error"
        )
        preview_data(NULL)
      })
    })

    # Handle updates to preview data and selection path
    # Output for conditionalPanel - indicates if preview is available
    output$has_preview <- reactive({
      isTruthy(preview_data()) && isTruthy(selected_path())
    }) |> bindEvent(get_has_preview_d())
    # Must set suspendWhenHidden = FALSE to detect changes to has_preview
    outputOptions(output, "has_preview", suspendWhenHidden = FALSE)

    # Handle Confirm button click
    observeEvent(input$confirm, {
      log_info("Extraction confirmed for path: {selected_path()}")
      # Update state with path for extraction
      extraction_path(selected_path())
    })

  })
}
