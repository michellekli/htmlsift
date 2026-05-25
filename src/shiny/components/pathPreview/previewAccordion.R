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

      tryCatch({
        output$accordion_container <- renderUI({
          module_ids <- lapply(seq_along(data), function(i) {
            paste0("links_", i)
          })
          links_modules(module_ids)

          panels <- lapply(seq_along(data), function(i) {
            item <- data[[i]]
            module_id <- module_ids[[i]]

            links_ui <- linksTable$ui(ns(module_id))
            linksTable$server(module_id, item$links %||% list())

            text_ui <- div(style = "
                           max-height: 200px;
                           overflow-y: auto;
                           border: 1px solid #ddd;
                           padding: 8px;
                           margin-top: 10px;",
                           item$text)

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

          do.call(accordion, c(list(
            id = ns("accordion_widget"), open = TRUE
          ), panels))
        })
      }, error = function(e) {
        output$accordion_container <- renderUI({
          div(class = "alert alert-danger",
              "Unable to load preview data.")
        })
      })
    }))

  })
}
