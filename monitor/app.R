# ============================================================
# Teaching Batteries · Data Monitor
# Shiny App  |  Anton Schreiber, Universität Hamburg (2026)
# ============================================================
# Überblick über die Daten der Lehrbatterien: Metadaten, univariate und
# bivariate Verteilungen. Die Batterien und ihre Variablen stehen in
# R/registry.R; Hilfsfunktionen in R/ lädt Shiny automatisch.
#
# Voraussetzungen: install.packages(c("shiny", "bslib", "ggplot2"))
# Starten:         shiny::runApp("monitor")
#
# Umgebungsvariablen:
#   TEACHING_ADMIN_PASSWORD  Passwort (ohne Variable bleibt der Monitor gesperrt)
#   MONITOR_DATA_ROOT        Ordner, in dem die Batterien liegen
#                            (Standard: ".." = Ordner über dem Monitor)
# Ohne Ergebnisse zeigt der Monitor Demodaten.
# ============================================================

library(shiny)
library(bslib)

data_root      <- Sys.getenv("MONITOR_DATA_ROOT", unset = "..")
admin_password <- Sys.getenv("TEACHING_ADMIN_PASSWORD")

# ── UI ──────────────────────────────────────────────────────
ui <- page_navbar(
  title = span(
    class = "monitor-title",
    img(src = "dgm-logo.png", alt = "DGM"),
    "Teaching Batteries · Data Monitor"
  ),
  window_title = "Teaching Batteries · Data Monitor",
  theme = bs_theme(version = 5, primary = dgm_orange, "body-color" = dgm_dark,
                   "link-color" = dgm_orange),
  fillable = FALSE,
  header = tags$head(tags$style(HTML(paste0("
    .navbar { background: ", dgm_dark, " !important; border-bottom: 4px solid ", dgm_orange, "; }
    .monitor-title { display: flex; align-items: center; gap: 16px; font-weight: 700; color: #fff; }
    .monitor-title img { height: 34px; }
    .navbar .nav-link { color: #ddd !important; }
    .navbar .nav-link.active, .navbar .nav-link:hover { color: ", dgm_orange, " !important; }
    .navbar .navbar-toggler { border-color: #888; }
    .navbar .navbar-toggler-icon { filter: invert(1); }
    .demo-note { border-left: 5px solid ", dgm_orange, "; background: #FFF4EC;
                 padding: .6rem .8rem; font-size: .9rem; }
    .stats-line { font-size: 1.05rem; margin: .8rem 0; }
    .bslib-value-box .value-box-value { color: ", dgm_orange, "; }
  ")))),
  sidebar = sidebar(
    width = 290,
    selectInput("battery", "Battery", choices = battery_choices),
    dateRangeInput("dates", "Sessions between", start = Sys.Date() - 30, end = Sys.Date()),
    checkboxInput("incomplete", "Include incomplete sessions", value = FALSE),
    actionButton("reload", "Reload data", icon = icon("rotate"), class = "btn-outline-secondary"),
    uiOutput("download_ui"),
    uiOutput("demo_note")
  ),

  nav_panel(
    "Metadata",
    uiOutput("metadata")
  ),
  nav_panel(
    "Univariate",
    h3("Univariate distributions"),
    selectInput("uni_var", "Variable", choices = NULL, width = "100%"),
    plotOutput("uni_plot", height = "420px"),
    tableOutput("uni_table")
  ),
  nav_panel(
    "Bivariate",
    h3("Bivariate distributions"),
    layout_columns(
      selectInput("bi_x", "Variable 1", choices = NULL, width = "100%"),
      selectInput("bi_y", "Variable 2", choices = NULL, width = "100%")
    ),
    uiOutput("bi_output")
  )
)

# ── Server ──────────────────────────────────────────────────
server <- function(input, output, session) {

  # ---- Login ----
  authed <- reactiveVal(FALSE)
  login_modal <- function(message = NULL) {
    modalDialog(
      title = "Data Monitor",
      if (admin_password == "") {
        p("The monitor is locked: the environment variable TEACHING_ADMIN_PASSWORD is not set.")
      } else {
        tagList(
          passwordInput("password", "Password", width = "100%"),
          if (!is.null(message)) div(class = "text-danger", message)
        )
      },
      footer = if (admin_password != "") actionButton("login", "Log in", class = "btn-primary"),
      easyClose = FALSE
    )
  }
  showModal(login_modal())
  observeEvent(input$login, {
    if (identical(input$password, admin_password)) {
      authed(TRUE)
      removeModal()
    } else {
      showModal(login_modal("Wrong password."))
    }
  })

  # ---- Daten ----
  loaded <- reactive({
    req(authed())
    input$reload
    load_battery(input$battery, data_root)
  })

  # Nach dem Laden: Datumsbereich und Variablenlisten anpassen
  observeEvent(loaded(), {
    d <- loaded()$data
    if (nrow(d) > 0) {
      days <- as.Date(d$time)
      updateDateRangeInput(session, "dates", start = min(days), end = max(days))
    }
    vars <- variable_table(input$battery)
    choices <- setNames(vars$id, vars$label)
    first_cat <- vars$id[vars$type == "categorical"][1]
    first_num <- vars$id[vars$type == "numeric"][1]
    updateSelectInput(session, "uni_var", choices = choices,
                      selected = if (isTRUE(input$uni_var %in% vars$id)) input$uni_var else first_num)
    updateSelectInput(session, "bi_x", choices = choices,
                      selected = if (isTRUE(input$bi_x %in% vars$id)) input$bi_x else first_cat)
    updateSelectInput(session, "bi_y", choices = choices,
                      selected = if (isTRUE(input$bi_y %in% vars$id)) input$bi_y else first_num)
  })

  # Sitzungen im Datumsbereich (für die Metadaten, mit unvollständigen)
  in_range <- reactive({
    d <- loaded()$data
    req(input$dates)
    days <- as.Date(d$time)
    d[days >= input$dates[1] & days <= input$dates[2], , drop = FALSE]
  })

  # Sitzungen für Plots und Download
  filtered <- reactive({
    d <- in_range()
    if (!isTRUE(input$incomplete)) d <- d[d$complete, , drop = FALSE]
    d
  })

  vars <- reactive(variable_table(input$battery))
  var_label <- function(id) vars()$label[vars()$id == id]
  var_type  <- function(id) vars()$type[vars()$id == id]

  output$demo_note <- renderUI({
    req(authed())
    if (loaded()$demo) {
      div(class = "demo-note",
          strong("Demo data. "),
          "No results found in ", code(loaded()$dir), ".")
    }
  })

  # ---- Download ----
  output$download_ui <- renderUI({
    req(authed())
    downloadButton("download", "Download data (CSV)", class = "btn-primary")
  })
  output$download <- downloadHandler(
    filename = function() paste0(input$battery, "_", format(Sys.Date(), "%Y%m%d"),
                                 if (loaded()$demo) "_demo", ".csv"),
    content = function(file) {
      req(authed())
      utils::write.csv(export_table(filtered(), input$battery), file,
                       row.names = FALSE, fileEncoding = "UTF-8", na = "")
    }
  )

  # ---- Metadata ----
  output$metadata <- renderUI({
    req(authed())
    def <- batteries[[input$battery]]
    d <- in_range()
    n_complete <- sum(d$complete)
    period <- if (nrow(d) > 0) {
      paste(format(min(d$time), "%Y-%m-%d"), "–", format(max(d$time), "%Y-%m-%d"))
    } else "–"
    tagList(
      h3(def$label),
      layout_columns(
        value_box("Sessions", nrow(d)),
        value_box("Complete", n_complete),
        value_box("Incomplete", nrow(d) - n_complete),
        value_box("Period", period),
        col_widths = c(3, 3, 3, 3)
      ),
      card(
        card_header("Study"),
        p(def$study, " ", a(def$doi, href = def$doi, target = "_blank")),
        p(def$design)
      ),
      layout_columns(
        card(card_header("Measured constructs"), tableOutput("instrument_table")),
        card(card_header("Variables in the monitor"),
             p(class = "text-muted small",
               "Valid values in the selected period",
               if (isTRUE(input$incomplete)) " (all sessions)." else " (complete sessions only)."),
             tableOutput("variable_overview")),
        col_widths = c(6, 6)
      )
    )
  })

  output$instrument_table <- renderTable(batteries[[input$battery]]$instruments,
                                         striped = TRUE, width = "100%")

  output$variable_overview <- renderTable({
    d <- filtered()
    v <- vars()
    data.frame(Variable = v$label,
               Type = ifelse(v$type == "numeric", "metric", "categorical"),
               `Valid N` = vapply(v$id, function(id) sum(!is.na(d[[id]])), integer(1)),
               check.names = FALSE)
  }, striped = TRUE, width = "100%")

  # ---- Univariate ----
  output$uni_plot <- renderPlot({
    req(authed(), input$uni_var %in% vars()$id)
    d <- filtered()
    validate(need(sum(!is.na(d[[input$uni_var]])) > 0, "No data for this variable in the selected period."))
    uni_plot(d, input$uni_var, var_label(input$uni_var), var_type(input$uni_var))
  }, res = 96)

  output$uni_table <- renderTable({
    req(authed(), input$uni_var %in% vars()$id)
    uni_stats(filtered(), input$uni_var, var_type(input$uni_var))
  }, striped = TRUE)

  # ---- Bivariate ----
  # Bei Error-Bar-Plots steht die kategoriale Variable immer auf der x-Achse
  bi_setup <- reactive({
    req(authed(), input$bi_x %in% vars()$id, input$bi_y %in% vars()$id)
    x <- input$bi_x; y <- input$bi_y
    kind <- bi_kind(var_type(x), var_type(y))
    if (kind == "errorbar" && var_type(x) == "numeric") { tmp <- x; x <- y; y <- tmp }
    list(x = x, y = y, kind = kind, d = bi_data(filtered(), x, y))
  })

  output$bi_output <- renderUI({
    s <- bi_setup()
    if (s$x == s$y) return(p(class = "text-muted", "Please choose two different variables."))
    if (nrow(s$d) == 0) return(p(class = "text-muted", "No sessions with values on both variables."))
    tagList(
      if (s$kind == "crosstab") tableOutput("bi_crosstab") else plotOutput("bi_plot", height = "460px"),
      div(class = "stats-line", bi_test(s$d, s$x, s$y, s$kind)),
      if (s$kind == "errorbar") tableOutput("bi_groups")
    )
  })

  output$bi_plot <- renderPlot({
    s <- bi_setup()
    if (s$kind == "scatter") {
      scatter_plot(s$d, s$x, s$y, var_label(s$x), var_label(s$y))
    } else {
      errorbar_plot(s$d, s$x, s$y, var_label(s$x), var_label(s$y))
    }
  }, res = 96)

  output$bi_groups <- renderTable({
    s <- bi_setup()
    req(s$kind == "errorbar")
    group_table(s$d, s$x, s$y)
  }, striped = TRUE)

  output$bi_crosstab <- renderTable({
    s <- bi_setup()
    req(s$kind == "crosstab")
    crosstab_table(s$d, s$x, s$y, paste(var_label(s$x), "×", var_label(s$y)))
  }, striped = TRUE, bordered = TRUE)
}

shinyApp(ui, server)
