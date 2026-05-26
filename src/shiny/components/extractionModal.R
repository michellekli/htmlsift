# Displays extracted data in JSON or CSV format with download capability

box::use(
  bslib[...],
  shiny[...],
  jsonlite,
  utils,
)

box::use(
  logger[log_info, log_error],
)

box::use(
  ../config[import_python],
)

parser <- import_python("parser")

#' Extraction Zone UI
#'
#' Creates the UI for the extraction zone, which displays extracted data
#' in JSON or CSV format with download capability.
#'
#' @param id The module ID
#'
#' @return A modal with format selector, data preview, and download button
#' @export
ui <- function(id) {
  ns <- NS(id)

  modalDialog(
    size = "l",
    # easyClose must not be allowed because no easy way to listen for it
    # and trigger the corresponding Cancel logic
    easyClose = FALSE,
    footer = NULL,
    card(card_header(
      tooltip(
        selectInput(
          ns("format"),
          label = "Output Format",
          choices = c("JSON", "CSV"),
          selected = "JSON"
        ),
        "Choose the format for preview and download.",
        placement = "top"
      ),
      tooltip(
        downloadButton(ns("download"),
                       label = "Download Data",
                       class = "btn-primary mt-2"),
        "Download the extracted data in the selected format.",
        placement = "top"
      ),
      tooltip(
        actionButton(ns("cancel"), "Go Back"),
        "Return to path selection.",
        placement = "top"
      )
    ), card_body(
      # Display area for formatted data
      div(style = "overflow: auto; max-height: 60vh",
          verbatimTextOutput(ns("data_preview"))),
    ))
  )
}


#' Extraction Zone server
#'
#' Handles extraction data retrieval, format conversion (JSON/CSV), preview
#' rendering, and file download.
#'
#' @param id The module ID
#' @param extraction_path A reactive expression yielding the current extraction
#'   path within the parsed tree
#' @param parsed_tree_root A reactive expression yielding the root node of the
#'   parsed HTML tree
#' @export
server <- function(id, extraction_path, parsed_tree_root) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------
    # Init state
    all_extracted_data <- reactiveVal(NULL)
    formatted_data <- reactiveVal(NULL)

    # Clean up reactive values when the session ends
    session$onSessionEnded(function() {
      all_extracted_data(NULL)
      formatted_data(NULL)

      gc()
    })

    # Debounce
    get_all_extracted_data_d <- debounce(reactive({
      c(extraction_path(), parsed_tree_root())
    }), 200)
    get_formatted_data_d <- debounce(reactive({
      c(input$format, all_extracted_data())
    }), 200)

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle updates to extraction path
    # Get all content from path
    observeEvent(get_all_extracted_data_d(), {
      # Check if data exists
      validate(need(extraction_path(), "No path selected."))
      validate(need(parsed_tree_root(), "No parsed tree available."))

      path <- extraction_path()
      root <- parsed_tree_root()

      log_info("Extracting content for path: {path}")
      tryCatch({
        withProgress(
          message = "Extracting data...",
          value = 0.5,
          all_extracted_data(parser$get_content_for_path(root, path))
        )
        log_info("Extraction completed for path: {path}")
      }, error = function(e) {
        log_error("Extraction failed for path '{path}': {e$message}")
        showNotification(
          paste("Unable to extract content:", e$message),
          type = "error"
        )
        all_extracted_data(NULL)
      })
    })

    # Handle updates to all extracted data
    # Get string representing content in selected output format
    observeEvent(get_formatted_data_d(), {
      validate(need(all_extracted_data(), "No extracted data available."))
      validate(need(input$format, "No format selected"))

      format <- input$format
      data <- all_extracted_data()

      if (format == "JSON") {
        # Convert links column (list of character vectors) to
        # proper JSON structure
        # For JSON, we keep links as arrays
        log_info("Formatting extracted data as JSON")
        tryCatch({
          withProgress(
            message = "Formatting JSON...",
            value = 0.5,
            formatted_data(jsonlite::toJSON(data,
                                            pretty = TRUE,
                                            auto_unbox = FALSE))
          )
          log_info("Formatting JSON complete")
        }, error = function(e) {
          log_error("JSON formatting failed: {e$message}")
          showNotification(
            paste("Unable to format data as JSON:", e$message),
            type = "error"
          )
          formatted_data(NULL)
        })
      } else if (format == "CSV") {
        # Collapse link vectors into single string
        log_info("Formatting extracted data as CSV")
        tryCatch({
          withProgress(
            message = "Formatting CSV...",
            value = 0.5,
            {
              csv_data <- as.data.frame(do.call(rbind, data))
              csv_data$text <- unlist(csv_data$text)
              csv_data$links <- sapply(csv_data$links, function(x) {
                paste(unlist(x), collapse = " | ")
              })
              formatted_data(
                utils::capture.output(
                  utils::write.csv(csv_data, row.names = FALSE)
                ) |> paste(collapse = "\n")
              )
            }
          )
          log_info("Formatting CSV complete")
        }, error = function(e) {
          log_error("CSV formatting failed: {e$message}")
          showNotification(
            paste("Unable to format data as CSV:", e$message),
            type = "error"
          )
          formatted_data(NULL)
        })
      }
    })

    # Handle updates to formatted data
    # Render the formatted data preview
    # Binds to both extracted_data changes and format selection changes
    output$data_preview <- renderText({
      formatted_data()
    }) |> bindEvent(formatted_data())

    # Handle updates to formatted data
    # Output for conditionalPanel - indicates if data is available
    output$has_data <- reactive({
      isTruthy(formatted_data())
    }) |> bindEvent(formatted_data())
    # Must set suspendWhenHidden = FALSE to detect changes to has_data
    outputOptions(output, "has_data", suspendWhenHidden = FALSE)

    # Download handler
    output$download <- downloadHandler(
      filename = function() {
        ext <- tolower(input$format)
        paste0("extracted_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".", ext)
      },
      content = function(file) {
        req(formatted_data())
        data <- formatted_data()

        log_info("Downloading data as {input$format}")
        writeLines(data, file)
      },
      contentType = if (input$format == "JSON") {
        "application/json"
      } else {
        "text/csv"
      }
    )

    # Handle Cancel button click
    observeEvent(input$cancel, {
      log_info("Extraction cancelled for path: {extraction_path()}")
      # Clear state for selected path
      extraction_path(NULL)

      # Close modal
      removeModal()
    })
  })
}
