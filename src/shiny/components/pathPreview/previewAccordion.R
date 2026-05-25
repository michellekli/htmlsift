# Displays an accordion with preview items (links + text)

box::use(
  bslib[...],
  shiny[...],
  bsicons,
)

box::use(
  ./linksTable
)

#' Preview accordion module UI
#'
#' @param id Module namespace identifier.
#' @return A uiOutput placeholder for the dynamically rendered accordion.
#' @export
ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("accordion_container"))
}

#' Preview accordion module server
#'
#' Builds accordion panels from preview data, each with text and links table.
#'
#' @param id Module namespace identifier.
#' @param preview_data A reactive list of preview items.
#' @export
server <- function(id, preview_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # Init state
    # Store module IDs and links for server modules
    links_modules <- reactiveVal(list())
    # Store number of initialized server modules
    n_servers <- reactiveVal(0)
    # Calculate number of servers that need initializing
    n_servers_to_init <- reactive({
      length(links_modules()) - n_servers()
    })

    # Clean up reactive values when the session ends
    session$onSessionEnded(function() {
      links_modules(NULL)
      n_servers(NULL)

      gc()
    })

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in preview_data
    # Create accordion for each item in preview_data
    output$accordion_container <- renderUI({
      data <- preview_data()
      req(length(data) > 0)

      module_detail <- lapply(seq_along(data), function(i) {
        list(
          id = paste0("links_", i), # unique module ID
          links = data[[i]]$links   # links for module
        )
      })
      # Update state with details for each module
      links_modules(module_detail)

      # Create accordion panels for each preview item
      panels <- lapply(seq_along(data), function(i) {
        item <- data[[i]]
        module_id <- links_modules()[[i]]$id

        # Create links table UI for item
        links_ui <- linksTable$ui(ns(module_id))

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
    }) |> bindEvent(preview_data())

    # Initialize servers for the links UI.
    # No way to manually clean up server modules, so make sure
    # to only initialize as many as are needed to support
    # all the links UI.
    # Must be outside renderUI for proper clean up
    # when the entire UI for this module is removed.
    observeEvent(n_servers_to_init(), {
      n <- n_servers_to_init()
      req(n > 0)

      lapply(c(1:n), function(i) {
        linksTable$server(
          links_modules()[[i]]$id,
          reactive(links_modules()[[i]]$links) # can change, need reactive
        )
      })

      # Update state to reflect newly initialized servers
      n_servers(n_servers() + n)
    })
  })
}
