# Displays a DT datatable of links or a "No links found" message
box::use(
  bslib[...],
  shiny[...],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("links_container"))
}

#' @export
server <- function(id, links) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in links
    observeEvent(links, isolate({
      # Create container for links
      output$links_container <- renderUI({
        if (length(links) > 0) {
          DT::DTOutput(ns("links_dt"))
        } else {
          div(
            style = "padding: 10px; color: #6c757d; font-style: italic;",
            "No links found"
          )
        }
      })

      # Create links display
      output$links_dt <- DT::renderDT({
        req(length(links) > 0)

        tryCatch({
          validate(
            need(is.list(links) || is.vector(links),
                 "Links data must be a list or vector.")
          )
          links_df <- data.frame(
            href = unlist(links)
          )

          DT::datatable(
            links_df,
            options = list(
              pageLength = 3,
              scrollY = "100px",
              scrollCollapse = TRUE,
              paging = FALSE,
              searching = FALSE,
              info = FALSE
            ),
            rownames = FALSE,
            selection = "none"
          )
        }, error = function(e) {
          DT::datatable(
            data.frame(href = paste("Unable to load links:", e$message)),
            options = list(
              scrollY = "100px",
              scrollCollapse = TRUE,
              paging = FALSE,
              searching = FALSE,
              info = FALSE
            ),
            rownames = FALSE,
            selection = "none"
          )
        })
      })
    }))
  })
}
