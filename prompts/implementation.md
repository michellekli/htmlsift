# Prompts for implementing features from roadmap.md
Adjust text within curly braces '{}' as needed. Steps for the user are preceded with '>'. Provide one step at a time to the AI.

## Steps

> Move from build to plan mode

What is needed to complete step {3.3} in docs/roadmap.md ? Read only docs/roadmap.md and docs/design.md

---

What R shiny components could be used? List components that could be useful from the list here: https://shiny.posit.co/r/components/

---

Turn this into a prompt for a Shiny Assistant.

- The prompt must include all required context.
- References to files will not be available to the Shiny Assistant.
- Use modular NS() where applicable.
- Use state to communicate between shiny modules. Do not return any values from a server module.
- Separate server functions into a Reactive State section and an Event Handling section.
- The Reactive State section initializes reactive values and passes state to server functions for communication. Prefer explicit reactiveVal() or reactiveValues() instead of reactive().
- The Event Handling section contains logic that runs when state changes. Prefer observeEvent to explicitly list triggers in eventExpr. If an output needs to be rendered, use bindEvent instead of observeEvent.

---

> Provide the prompt to Shiny Assistant at https://gallery.shinyapps.io/assistant/ and incorporate its response into the app.
