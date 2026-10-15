# ============================================================
# Ergebnisse einlesen
# ============================================================
# psychTestR legt pro Sitzung genau eine Datei an (der Zwischenstand wird
# beim nächsten Speichern gelöscht). Eine Datei = eine Zeile.

first_value <- function(x) {
  if (is.null(x) || length(x) == 0) NA else x[[1]]
}

read_result_file <- function(file, variables) {
  res <- tryCatch(as.list(readRDS(file)), error = function(e) NULL)
  if (is.null(res)) return(NULL)
  session <- res[["session"]]
  time <- first_value(session$time_started)
  row <- data.frame(
    session  = tools::file_path_sans_ext(basename(file)),
    time     = if (is.na(time)) as.POSIXct(file.mtime(file)) else as.POSIXct(time),
    complete = isTRUE(first_value(session$complete)),
    stringsAsFactors = FALSE
  )
  for (v in variables) {
    row[[v$id]] <- as.character(first_value(res[[v$module]][[v$field]]))
  }
  row
}

# Rohwerte in die angezeigte Form bringen (Umrechnung, Skalenniveau)
convert_variables <- function(data, variables) {
  for (v in variables) {
    x <- data[[v$id]]
    if (!is.null(v$transform)) {
      x <- v$transform(x)
    } else if (v$type == "numeric") {
      x <- suppressWarnings(as.numeric(x))
    } else {
      x <- factor(x)
    }
    data[[v$id]] <- x
  }
  data
}

# Alle Sitzungen einer Batterie; ohne Ergebnisse Demodaten
load_battery <- function(battery, data_root) {
  def <- batteries[[battery]]
  dir <- file.path(data_root, def$results_dir)
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  rows <- Filter(Negate(is.null), lapply(files, read_result_file, variables = def$variables))
  if (length(rows) == 0) {
    return(list(data = def$simulate(), demo = TRUE, dir = dir))
  }
  data <- convert_variables(do.call(rbind, rows), def$variables)
  data <- data[order(data$time), ]
  rownames(data) <- NULL
  list(data = data, demo = FALSE, dir = dir)
}

# Für den Download: lesbare Spalten, Faktoren als Text
export_table <- function(data, battery) {
  vars <- variable_table(battery)
  out <- data.frame(session = data$session,
                    date    = format(data$time, "%Y-%m-%d %H:%M"),
                    complete = data$complete,
                    stringsAsFactors = FALSE)
  for (id in vars$id) out[[id]] <- if (is.factor(data[[id]])) as.character(data[[id]]) else data[[id]]
  out
}
