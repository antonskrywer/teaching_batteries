# ============================================================
# Registry der Batterien
# ============================================================
# Eine neue Batterie ist ein neuer Eintrag in `batteries`. Jede Variable
# nennt Modul und Feld in der psychTestR-Ergebnisdatei, das Skalenniveau
# ("numeric" oder "categorical") und optional eine Umrechnung.
#
#   link         Link zur Studie
#   results_dir  Ergebnisordner relativ zu TEACHING_DATA_ROOT
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
    link        = "https://doi.org/10.1038/365611a0",
    design      = "Between-subjects 3 x 2 design: three listening conditions (music, speech, silence; about 9 minutes each), followed by either an adaptive matrix reasoning test (MIQ, 12 items) or the Paper Folding Test (PFT, 20 items, 6 minutes). Both factors are assigned in balanced order.",
    results_dir = "mozart_effect/output/results",
    instruments = data.frame(
      Construct   = c("Listening condition", "Cognitive test", "Matrix reasoning (MIQ)",
                      "Spatial visualisation (PFT)", "Demographics (DEG)"),
      Instrument  = c("Experimental factor", "Experimental factor", "MIQ, adaptive, 12 items",
                      "Paper Folding Test (Vz-2-BRACE), 20 items, 6 min", "psyquest DEG"),
      Measures    = c("music / speech / silence", "MIQ / PFT", "IRT ability estimate",
                      "number correct (0–20)",
                      "age, gender, country, first and second language"),
      check.names = FALSE
    ),
    variables = list(
      new_variable("condition", "Listening condition", "setup", "condition", "categorical",
                   function(x) factor(x, levels = c("music", "speech", "silence"))),
      new_variable("test", "Cognitive test", "setup", "test", "categorical",
                   function(x) factor(x, levels = c("miq", "pft"))),
      new_variable("miq_ability", "MIQ ability", "MIQ", "ability", "numeric"),
      new_variable("pft_score", "PFT score (0–20)", "PFT", "score", "numeric"),
      new_variable("gender", "Gender", "DEG", "Gender", "categorical", deg_gender),
      new_variable("age", "Age (years)", "DEG", "Age", "numeric", deg_age_years)
    ),
    simulate = function(n = 60, seed = 1) {
      set.seed(seed)
      condition <- rep_len(c("music", "speech", "silence"), n)
      test      <- rep_len(rep(c("miq", "pft"), each = 3), n)
      complete  <- runif(n) > 0.12
      effect    <- c(music = 0.25, speech = 0, silence = -0.05)[condition]
      data.frame(
        session     = sprintf("demo_%03d", seq_len(n)),
        time        = as.POSIXct("2026-10-20 10:00") + sort(sample(0:(21 * 86400), n)),
        complete    = complete,
        condition   = factor(condition, levels = c("music", "speech", "silence")),
        test        = factor(test, levels = c("miq", "pft")),
        miq_ability = ifelse(complete & test == "miq", round(rnorm(n, effect, 0.9), 2), NA),
        pft_score   = ifelse(complete & test == "pft",
                             pmin(20, pmax(0, round(rnorm(n, 11 + 2 * effect, 3.5)))), NA),
        gender      = deg_gender(sample(1:4, n, replace = TRUE, prob = c(0.55, 0.38, 0.04, 0.03))),
        age         = pmax(18, round(rnorm(n, 24, 3.5))),
        stringsAsFactors = FALSE
      )
    }
  ),

  ruth_muellensiefen_2020 = list(
    label       = "Personality and musical preferences",
    study       = "Ruth, N., & Müllensiefen, D. (2020). Associations between musical preferences and personality in female secondary school students. Psychomusicology: Music, Mind, and Brain, 30(4), 202–211.",
    link        = "https://psycnet.apa.org/record/2020-68799-001",
    design      = "Correlational design: musical preferences (MUSIC model), Big Five personality traits (TIPI) and musical sophistication (Gold-MSI) in one session.",
    results_dir = "ruth_muellensiefen_2020/output/results",
    instruments = data.frame(
      Construct   = c("Musical preferences (MUS)", "Personality (TPI)",
                      "Musical sophistication (GMS)", "Demographics (DEG)"),
      Instrument  = c("MUSIC inventory, 25 items", "Ten-Item Personality Inventory",
                      "Gold-MSI, 41 items", "psyquest DEG"),
      Measures    = c("Mellow, Unpretentious, Sophisticated, Intense, Contemporary (1–9)",
                      "Big Five (1–7)",
                      "General and five subscales (1–7)",
                      "age, gender, country"),
      check.names = FALSE
    ),
    variables = list(
      new_variable("mus_mellow",        "Preference: Mellow",           "MUS", "Mellow",        "numeric"),
      new_variable("mus_unpretentious", "Preference: Unpretentious",    "MUS", "Unpretentious", "numeric"),
      new_variable("mus_sophisticated", "Preference: Sophisticated",    "MUS", "Sophisticated", "numeric"),
      new_variable("mus_intense",       "Preference: Intense",          "MUS", "Intense",       "numeric"),
      new_variable("mus_contemporary",  "Preference: Contemporary",     "MUS", "Contemporary",  "numeric"),
      new_variable("tpi_extraversion",  "Extraversion",                 "TPI", "Extraversion",  "numeric"),
      new_variable("tpi_agreeableness", "Agreeableness",                "TPI", "Agreeableness", "numeric"),
      new_variable("tpi_conscientiousness", "Conscientiousness",        "TPI", "Conscientiousness", "numeric"),
      new_variable("tpi_stability",     "Emotional stability",          "TPI", "Emotional Stability", "numeric"),
      new_variable("tpi_openness",      "Openness to experiences",      "TPI", "Openness to Experiences", "numeric"),
      new_variable("gms_general",       "Gold-MSI: General",            "GMS", "General",       "numeric"),
      new_variable("gms_active",        "Gold-MSI: Active engagement",  "GMS", "Active Engagement", "numeric"),
      new_variable("gms_perceptual",    "Gold-MSI: Perceptual abilities", "GMS", "Perceptual Abilities", "numeric"),
      new_variable("gms_training",      "Gold-MSI: Musical training",   "GMS", "Musical Training", "numeric"),
      new_variable("gms_singing",       "Gold-MSI: Singing abilities",  "GMS", "Singing Abilities", "numeric"),
      new_variable("gms_emotions",      "Gold-MSI: Emotions",           "GMS", "Emotions",      "numeric"),
      new_variable("gender", "Gender", "DEG", "Gender", "categorical", deg_gender),
      new_variable("age", "Age (years)", "DEG", "Age", "numeric", deg_age_years)
    ),
    simulate = function(n = 80, seed = 2) {
      set.seed(seed)
      scale_score <- function(m, s, lo, hi, step) pmin(hi, pmax(lo, round(rnorm(n, m, s) / step) * step))
      extra <- scale_score(4.6, 1.2, 1, 7, 0.5)
      agree <- scale_score(5.0, 1.0, 1, 7, 0.5)
      data.frame(
        session  = sprintf("demo_%03d", seq_len(n)),
        time     = as.POSIXct("2026-10-20 10:00") + sort(sample(0:(21 * 86400), n)),
        complete = runif(n) > 0.08,
        mus_mellow        = pmin(9, pmax(1, round(4 + 0.4 * agree + rnorm(n, 0, 1.4), 2))),
        mus_unpretentious = scale_score(5.2, 1.6, 1, 9, 0.25),
        mus_sophisticated = scale_score(5.0, 1.7, 1, 9, 1 / 3),
        mus_intense       = pmin(9, pmax(1, round(3.5 + 0.35 * extra + rnorm(n, 0, 1.6), 2))),
        mus_contemporary  = scale_score(5.8, 1.4, 1, 9, 0.2),
        tpi_extraversion      = extra,
        tpi_agreeableness     = agree,
        tpi_conscientiousness = scale_score(5.1, 1.1, 1, 7, 0.5),
        tpi_stability         = scale_score(4.3, 1.3, 1, 7, 0.5),
        tpi_openness          = scale_score(5.3, 1.0, 1, 7, 0.5),
        gms_general    = scale_score(4.2, 1.0, 1, 7, 1 / 18),
        gms_active     = scale_score(4.4, 1.0, 1, 7, 1 / 9),
        gms_perceptual = scale_score(5.0, 0.9, 1, 7, 1 / 9),
        gms_training   = scale_score(3.6, 1.5, 1, 7, 1 / 7),
        gms_singing    = scale_score(4.1, 1.1, 1, 7, 1 / 7),
        gms_emotions   = scale_score(5.4, 0.8, 1, 7, 1 / 6),
        gender = deg_gender(sample(1:4, n, replace = TRUE, prob = c(0.6, 0.35, 0.03, 0.02))),
        age    = pmax(17, round(rnorm(n, 23, 3))),
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
