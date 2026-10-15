# ============================================================
# Registry der Batterien
# ============================================================
# Eine neue Batterie ist ein neuer Eintrag in `batteries`. Jede Variable
# nennt Modul und Feld in der psychTestR-Ergebnisdatei, das Skalenniveau
# ("numeric" oder "categorical") und optional eine Umrechnung.
#
#   results_dir  Ergebnisordner relativ zu MONITOR_DATA_ROOT
#   instruments  gemessene Konstrukte (für die Metadaten-Seite)
#   variables    angezeigte Variablen
#   simulate     Demodaten, solange es keine echten Ergebnisse gibt

# DEG speichert das Alter in Monaten und das Geschlecht als Code 1–4
deg_age_years <- function(x) floor(as.numeric(x) / 12)
deg_gender <- function(x) {
  factor(c("female", "male", "diverse", "rather not say")[as.integer(x)],
         levels = c("female", "male", "diverse", "rather not say"))
}

new_variable <- function(id, label, module, field, type, transform = NULL) {
  list(id = id, label = label, module = module, field = field, type = type,
       transform = transform)
}

batteries <- list(

  mozart_effect = list(
    label       = "Mozart effect",
    study       = "Rauscher, F. H., Shaw, G. L., & Ky, K. N. (1993). Music and spatial task performance. Nature, 365(6447), 611.",
    doi         = "https://doi.org/10.1038/365611a0",
    design      = "Between-subjects design with three listening conditions (music, speech, silence; about 9 minutes each), followed by an adaptive matrix reasoning test (MIQ, 12 items).",
    results_dir = "mozart_effect/output/results",
    instruments = data.frame(
      Construct   = c("Listening condition", "Matrix reasoning (MIQ)", "Demographics (DEG)"),
      Instrument  = c("Experimental factor", "MIQ, adaptive, 12 items", "psyquest DEG"),
      Measures    = c("music / speech / silence", "IRT ability estimate",
                      "age, gender, country, first and second language"),
      check.names = FALSE
    ),
    variables = list(
      new_variable("condition", "Listening condition", "setup", "condition", "categorical",
                   function(x) factor(x, levels = c("music", "speech", "silence"))),
      new_variable("miq_ability", "MIQ ability", "MIQ", "ability", "numeric"),
      new_variable("gender", "Gender", "DEG", "Gender", "categorical", deg_gender),
      new_variable("age", "Age (years)", "DEG", "Age", "numeric", deg_age_years)
    ),
    simulate = function(n = 60, seed = 1) {
      set.seed(seed)
      condition <- sample(c("music", "speech", "silence"), n, replace = TRUE)
      complete  <- runif(n) > 0.12
      data.frame(
        session     = sprintf("demo_%03d", seq_len(n)),
        time        = as.POSIXct("2026-10-20 10:00") + sort(sample(0:(21 * 86400), n)),
        complete    = complete,
        condition   = factor(condition, levels = c("music", "speech", "silence")),
        miq_ability = ifelse(complete,
                             round(rnorm(n, c(music = 0.25, speech = 0, silence = -0.05)[condition], 0.9), 2),
                             NA),
        gender      = deg_gender(sample(1:4, n, replace = TRUE, prob = c(0.55, 0.38, 0.04, 0.03))),
        age         = pmax(18, round(rnorm(n, 24, 3.5))),
        stringsAsFactors = FALSE
      )
    }
  )

)

battery_choices <- setNames(names(batteries), vapply(batteries, `[[`, "", "label"))

variable_table <- function(battery) {
  vars <- batteries[[battery]]$variables
  data.frame(id    = vapply(vars, `[[`, "", "id"),
             label = vapply(vars, `[[`, "", "label"),
             type  = vapply(vars, `[[`, "", "type"),
             stringsAsFactors = FALSE)
}
