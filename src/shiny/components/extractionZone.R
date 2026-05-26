# Displays extracted data in JSON or CSV format with download capability

box::use(
  bslib[...],
  shiny[...],
  jsonlite,
  utils,
)

box::use(
  ../config[import_python],
)

parser <- tryCatch(
  import_python("parser"),
  error = function(e) {
    stop("Unable to import Python parser module: ", e$message)
  }
)

#' Extraction Zone UI
#'
#' Creates the UI for the extraction zone card, which displays extracted data
#' in JSON or CSV format with download capability.
#'
#' @param id The module ID
#'
#' @return A Shiny card UI element with format selector, data preview, and
#'   download button
#' @export
ui <- function(id) {
  ns <- NS(id)

  card(
    card_header("Extraction Zone"),
    card_body(
      # Format selection
      tooltip(
        selectInput(
          ns("format"),
          label = "Output Format",
          choices = c("JSON", "CSV"),
          selected = "JSON"
        ),
        "Choose the format for preview and download."
      ),

      # Display area for formatted data
      div(
        style = "overflow: auto; max-height: 60vh",
        verbatimTextOutput(ns("data_preview"))
      ),

      conditionalPanel(
        condition = "output.has_data",
        ns = ns,
        tooltip(
          downloadButton(
            ns("download"),
            label = "Download Data",
            class = "btn-primary mt-2"
          ),
          "Download the extracted data in the selected format."
        )
      )
    )
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

      tryCatch({
        withProgress(
          message = "Extracting data...",
          value = 0.5,
          all_extracted_data(parser$get_content_for_path(root, path))
        )
      }, error = function(e) {
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

      format <- input$format
      data <- all_extracted_data()

      if (format == "JSON") {
        # Convert links column (list of character vectors) to
        # proper JSON structure
        # For JSON, we keep links as arrays
        tryCatch({
          withProgress(message = "Formatting JSON...",
                       value = 0.5,
                       formatted_data(jsonlite::toJSON(
                         data, pretty = TRUE, auto_unbox = FALSE
                       )))
        }, error = function(e) {
          showNotification(paste("Unable to format data as JSON:", e$message),
                           type = "error")
          formatted_data(NULL)
        })
      } else if (format == "CSV") {
        # Collapse link vectors into semicolon-separated strings
        tryCatch({
          withProgress(
            message = "Formatting CSV...",
            value = 0.5,
            {
              csv_data <- as.data.frame(do.call(rbind, data))
              csv_data$text <- unlist(csv_data$text)
              csv_data$links <- sapply(csv_data$links, function(x) {
                paste(unlist(x), collapse = "; ")
              })
              formatted_data(
                utils::capture.output(
                  utils::write.csv(csv_data, row.names = FALSE)
                ) |> paste(collapse = "\n")
              )
            }
          )
        }, error = function(e) {
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

        writeLines(data, file)
      },
      contentType = if (input$format == "JSON") {
        "application/json"
      } else {
        "text/csv"
      }
    )
  })
}
