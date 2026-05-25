box::use(
  bslib[...],
  shiny[...],
  reticulate[import_from_path],
)

sanitizer <- tryCatch(
  import_from_path("sanitizer", here::here("src", "python")),
  error = function(e) {
    stop("Unable to import Python sanitizer module: ", e$message)
  }
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  card(
    card_header("Config"),
    card_body(
      textAreaInput(
        inputId = ns("html_input"),
        label = "Paste your HTML below:",
        placeholder = "HTML here...",
        rows = 12,
        width = "100%"
      ),
      actionButton(
        inputId = ns("process_html"),
        label = "Process HTML",
        icon = icon("play"),
        class = "btn-primary w-100 mt-2"
      ),
      # Display validation/status messages
      uiOutput(ns("status_message"))
    )
  )
}

#' @export
server <- function(id, sanitized_html) {
  moduleServer(id, function(input, output, session) {
    # -----------------------
    # --- REACTIVE STATE ----
    # -----------------------
    # Init state
    process_html_status <- reactiveVal(NULL)

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------
    # Handle Process HTML button click
    observeEvent(input$process_html, isolate({
      # Clear state
      sanitized_html(NULL)

      raw_html <- input$html_input

      # Sanitize and validate the HTML input
      result <- tryCatch({
        # Sanitize
        cleaned <- sanitizer$sanitize_html(raw_html)

        # Validation: Check if input is not empty or just whitespace
        validate(
          need(cleaned != "", "Please enter HTML content."),
          need(nchar(trimws(cleaned)) > 0,
               "HTML content cannot be empty or whitespace only.")
        )

        # Set state of input HTML
        sanitized_html(cleaned)

        # Success message
        list(
          status = "success",
          message = "HTML received!"
        )
      }, error = function(e) {
        list(
          status = "error",
          message = e$message
        )
      })

      # Set state of status
      process_html_status(result)
    }))

    # Handle processing status change
    observeEvent(process_html_status(), isolate({
      result <- process_html_status()

      # Set state of status message
      output$status_message <- renderUI({
        if (is.null(result)) {
          # Clear message initially
          NULL
        } else if (result$status == "success") {
          div(
            class = "alert alert-success mt-3",
            icon("check-circle"),
            tags$strong(" Success: "), result$message
          )
        } else {
          div(
            class = "alert alert-danger mt-3",
            icon("exclamation-triangle"),
            tags$strong(" Unable to process: "), result$message
          )
        }
      })
    }))
  })
}
