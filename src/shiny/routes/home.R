box::use(
  bslib[...],
  shiny[...],
)

box::use(../components/htmlInput)

#' @export
ui <- function() {
  page_sidebar(
    title = "htmlsift",
    sidebar = sidebar(
      width = 400,
      htmlInput$ui("html_config")
    ),
    card(
      card_header("Output Preview"),
      card_body(
        h4("Sanitized HTML will appear here after processing"),
        verbatimTextOutput("html_output")
      )
    )
  )
}


#' @export
server <- function(input, output, session) {
  # -----------------------
  # --- REACTIVE STATE ----
  # -----------------------
  # Init state
  sanitized_html <- reactiveVal(NULL)

  # Pass state for communication
  htmlInput$server("html_config", sanitized_html)

  # ----------------------
  # --- EVENT HANDLING ---
  # ----------------------
  # Handle change in stored HTML
  observeEvent(sanitized_html(), isolate({
    output$html_output <- renderPrint({
      html <- sanitized_html()
      if (is.null(html)) {
        "No HTML processed yet. Provide HTML and click 'Process HTML'."
      } else {
        cat(html)
      }
    })
  }))
}
