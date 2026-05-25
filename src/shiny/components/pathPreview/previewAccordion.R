# Displays an accordion with preview items (links + text)

box::use(
  bslib[...],
  shiny[...],
)

box::use(
  ./linksTable
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("accordion_container"))
}

#' @export
server <- function(id, preview_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # Init state
    # Store module IDs for dynamically created linksTable modules
    links_modules <- reactiveVal(list())

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in preview_data
    observeEvent(preview_data(), isolate({
      data <- preview_data()
      req(length(data) > 0)

      # Create accordion for each item in preview_data
      output$accordion_container <- renderUI({
        # Create unique module IDs for each item's links table
        module_ids <- lapply(seq_along(data), function(i) {
          paste0("links_", i)
        })
        links_modules(module_ids)

        # Create accordion panels for each preview item
        panels <- lapply(seq_along(data), function(i) {
          item <- data[[i]]
          module_id <- module_ids[[i]]

          # Create links table for item
          links_ui <- linksTable$ui(ns(module_id))
          linksTable$server(module_id, item$links)

          # Create text preview div
          text_ui <- div(style = "
                         max-height: 200px;
                         overflow-y: auto;
                         border: 1px solid #ddd;
                         padding: 8px;
                         margin-top: 10px;",
                         item$text)

          # Create accordion panel
          accordion_panel(title = paste("Item", i),
                          div(
                            em("Text Content:"),
                            text_ui,
                            hr(),
                            em("Links:"),
                            links_ui
                          ),
                          icon = bsicons::bs_icon("card-text"))
        })

        # Return accordion container with all accordion panels
        do.call(accordion, c(list(
          id = ns("accordion_widget"), open = TRUE
        ), panels))
      })

    }))

  })
}
