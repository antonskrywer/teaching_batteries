# Mozart-Effekt (Replikation von Rauscher, Shaw & Ky, 1993)
#
# Between-Subjects-Design mit drei Bedingungen: Musik, Sprache, Stille.
# Ablauf: Consent -> (ID) -> DEG -> Audio-Instruktion -> Audio (~10 Min.)
# -> Instruktion kognitive Aufgabe -> MIQ (adaptiv, 12 Items) -> Ende.
#
# Bedingung: per URL-Parameter ?condition=music|speech|silence, sonst
# zufällig. Der Weiter-Button der Audio-Seite erscheint erst nach Ende des
# Tracks bzw. nach Ablauf der Stille-Dauer.
#
# Texte in mozart_effect_dict.csv, Audiodateien in www/audio/.
# MIQ ist nicht öffentlich und nur auf dem Dots-Server installiert; lokal
# erscheint an seiner Stelle eine Platzhalterseite.
#
# Start: shiny::runApp("mozart_effect")

library(psychTestR)

# ---- Einstellungen ----
# Debug (Stille nur 5 s, Weiter-Button sofort sichtbar): Umgebungsvariable
# MOZART_DEBUG=TRUE setzen
debug          <- isTRUE(as.logical(Sys.getenv("MOZART_DEBUG", "FALSE")))
show_id_page   <- FALSE   # Seite mit anonymem Code (vorerst ausgeblendet)
miq_num_items  <- 12
conditions     <- c("music", "speech", "silence")
audio_files    <- c(music = "audio/music.mp3", speech = "audio/speech.mp3")
silence_secs   <- if (debug) 5 else 600

# Admin-Passwort: steht nicht im Code (öffentliches Repository), sondern kommt
# aus der Umgebungsvariable TEACHING_ADMIN_PASSWORD (.Renviron). Ohne Variable
# gilt ein zufälliges Passwort, das Admin-Panel ist dann nicht erreichbar.
admin_password <- Sys.getenv("TEACHING_ADMIN_PASSWORD")
if (admin_password == "") admin_password <- paste(sample(c(letters, 0:9), 24, TRUE), collapse = "")

# ---- Dictionary ----
me_dict <- i18n_dict$new(read.csv2("mozart_effect_dict.csv", fileEncoding = "UTF-8",
                                   quote = "", stringsAsFactors = FALSE))

# ---- Seiten ----
consent_page <- function() {
  checkbox_page(
    label = "consent",
    prompt = shiny::div(
      shiny::h4(i18n("CONSENT_HEAD")),
      shiny::p(i18n("CONSENT_P1")),
      shiny::p(i18n("CONSENT_P2")),
      shiny::p(i18n("CONSENT_P3")),
      shiny::p(i18n("CONSENT_P4"))
    ),
    choices = "consent",
    labels = list(i18n("CONSENT_CHECK")),
    force_answer = "all",
    failed_validation_message = i18n("CONSENT_FAILED"),
    trigger_button_text = i18n("NEXT")
  )
}

id_page <- function() {
  text_input_page(
    label = "p_code",
    prompt = shiny::div(shiny::p(i18n("ID_PROMPT")), shiny::p(i18n("ID_INSTRUCTION"))),
    placeholder = i18n("ID_PLACEHOLDER"),
    button_text = i18n("NEXT"),
    validate = function(answer, ...) {
      if (grepl("^[[:alpha:]]{3}[0-9]{2}$", trimws(answer))) TRUE else i18n("ID_INVALID")
    }
  )
}

# Bedingung aus URL-Parameter übernehmen, sonst zufällig ziehen
assign_condition <- function() {
  code_block(function(state, ...) {
    cond <- get_url_params(state)$condition
    source <- "url"
    if (is.null(cond) || !(cond %in% conditions)) {
      cond <- sample(conditions, 1)
      source <- "random"
    }
    set_global("condition", cond, state)
    save_result(state, "condition", cond)
    save_result(state, "condition_source", source)
  })
}

# JS für die Audio-Seite: spielt den Track automatisch (Fallback: Start-Button,
# falls der Browser Autoplay blockiert), zeigt die Restzeit und blendet den
# Weiter-Button nach Ende ein. Die tatsächliche Dauer geht als Antwort ein.
audio_page_js <- function(silence_secs, show_next_now) {
  sprintf("
(function() {
  var silence = %d, showNow = %s;
  var audio = document.getElementById('stimulus');
  var timeLeft = document.getElementById('time_left');
  var t0 = null;
  function fmt(s) {
    s = Math.max(0, Math.ceil(s));
    return Math.floor(s / 60) + ':' + ('0' + (s %% 60)).slice(-2);
  }
  function showNext() { document.getElementById('next_wrap').style.visibility = 'visible'; }
  function done() {
    Shiny.setInputValue('listen_seconds', t0 ? (Date.now() - t0) / 1000 : 0);
    timeLeft.textContent = fmt(0);
    showNext();
  }
  if (showNow) showNext();
  if (audio) {
    var playBtn = document.getElementById('play_btn');
    audio.addEventListener('playing', function() { if (!t0) t0 = Date.now(); playBtn.style.display = 'none'; });
    audio.addEventListener('timeupdate', function() { timeLeft.textContent = fmt(audio.duration - audio.currentTime); });
    audio.addEventListener('ended', done);
    playBtn.addEventListener('click', function() { audio.play(); });
    var p = audio.play();
    if (p) p.catch(function() { playBtn.style.display = 'inline-block'; });
  } else {
    t0 = Date.now();
    var timer = setInterval(function() {
      var rest = silence - (Date.now() - t0) / 1000;
      timeLeft.textContent = fmt(rest);
      if (rest <= 0) { clearInterval(timer); done(); }
    }, 250);
  }
})();", silence_secs, tolower(show_next_now))
}

audio_page <- function() {
  reactive_page(function(state, ...) {
    cond <- get_global("condition", state)
    stimulus <- if (cond == "silence") {
      NULL
    } else {
      shiny::tags$audio(id = "stimulus", src = audio_files[[cond]], preload = "auto")
    }
    page(
      label = "listen_seconds",
      ui = shiny::div(
        shiny::h4(i18n(paste0("COND_", toupper(cond)))),
        shiny::p(i18n(if (cond == "silence") "SILENCE_WAITING" else "AUDIO_PLAYING")),
        stimulus,
        shiny::tags$button(id = "play_btn", class = "btn btn-default", style = "display: none;",
                           i18n("AUDIO_PLAY")),
        shiny::p(i18n("TIME_LEFT"), shiny::tags$strong(id = "time_left", "")),
        shiny::div(id = "next_wrap", style = "visibility: hidden;",
                   trigger_button("next", i18n("NEXT"))),
        shiny::tags$script(shiny::HTML(audio_page_js(silence_secs, debug)))
      ),
      get_answer = function(input, ...) if (is.null(input$listen_seconds)) NA else input$listen_seconds,
      save_answer = TRUE
    )
  })
}

miq_task <- function() {
  if (requireNamespace("MIQ", quietly = TRUE)) {
    MIQ::MIQ(num_items = miq_num_items,
             take_training = TRUE,
             with_welcome = FALSE,
             with_finish = FALSE,
             feedback = NULL)
  } else {
    new_timeline(one_button_page(i18n("MIQ_MISSING"), button_text = i18n("NEXT")),
                 dict = me_dict)
  }
}

# ---- Timeline ----
timeline <- join(
  new_timeline(
    join(
      begin_module("setup"),
      consent_page(),
      if (show_id_page) id_page(),
      assign_condition(),
      end_module()
    ),
    dict = me_dict
  ),
  psyquest::DEG(subscales = c("Age", "Gender", "Country Formative Years",
                              "First Language", "Second Language"),
                language = "en"),
  new_timeline(
    join(
      begin_module("audio"),
      one_button_page(i18n("AUDIO_INSTRUCTION"), button_text = i18n("NEXT")),
      audio_page(),
      elt_save_results_to_disk(complete = FALSE),
      end_module(),
      one_button_page(i18n("TASK_INSTRUCTION"), button_text = i18n("NEXT"))
    ),
    dict = me_dict
  ),
  miq_task(),
  elt_save_results_to_disk(complete = TRUE),
  new_timeline(final_page(i18n("FINAL")), dict = me_dict)
)

make_test(
  timeline,
  opt = test_options(
    title = "Effects of Audio on Mental Abilities",
    admin_password = admin_password,
    researcher_email = "anton.schreiber@uni-hamburg.de",
    languages = "en",
    logo = "https://s3.eu-west-1.amazonaws.com/media.dots.org/img/up-uhh-logo-u-2010-u-png.png",
    logo_width = "107px",
    logo_height = "auto"
  )
)
