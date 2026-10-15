# Data Monitor

Shiny-App mit einem Überblick über die Daten aller Lehrbatterien: Metadaten,
univariate und bivariate Verteilungen, CSV-Download. Oberfläche auf Englisch,
Design in den DGM-Farben.

## Starten

```r
install.packages(c("shiny", "bslib", "ggplot2"))
Sys.setenv(TEACHING_ADMIN_PASSWORD = "…")   # sonst bleibt der Monitor gesperrt
shiny::runApp("monitor")                     # Arbeitsverzeichnis = Projektwurzel
```

## Umgebungsvariablen

| Variable | Bedeutung |
|---|---|
| `TEACHING_ADMIN_PASSWORD` | Passwort (dasselbe wie das Admin-Passwort der Batterien). Ohne Variable ist der Monitor gesperrt |
| `MONITOR_DATA_ROOT` | Ordner, in dem die Batterien liegen. Standard: `..` (Ordner über dem Monitor), auf dem Server also `/srv/shiny-server` |

Gibt es für eine Batterie noch keine Ergebnisse, zeigt der Monitor Demodaten
und weist darauf hin.

## Seiten

| Seite | Inhalt |
|---|---|
| Metadata | Studie, Design, Zahl der Sitzungen (gesamt, vollständig, unvollständig), Zeitraum, gemessene Konstrukte, gültige Werte pro Variable |
| Univariate | Histogramm (metrisch) bzw. Balkendiagramm (kategorial) mit Kennwerten |
| Bivariate | metrisch × metrisch: Streudiagramm mit Regressionsgerade, Pearson r · kategorial × metrisch: Mittelwerte mit 95 %-KI und Datenpunkten, Welch-t-Test mit Cohens d (2 Gruppen) bzw. einfaktorielle ANOVA mit η² · kategorial × kategorial: Kreuztabelle mit Zeilenprozenten, χ²-Test mit Cramérs V |

Seitenleiste: Batterie, Datumsfilter (Beginn der Sitzung), Schalter
„Include incomplete sessions", Daten neu laden, CSV-Download (gefilterte
Daten).

## Daten

- psychTestR legt pro Sitzung eine Datei an; eine Datei ist eine Zeile.
- Vollständig = `session$complete` ist `TRUE` (nach dem letzten Test
  gespeichert). Unvollständige Sitzungen zählen immer in den Metadaten; in
  Plots und Download nur mit dem Schalter, und dann nur mit den Variablen, die
  sie haben.
- Gruppenvergleiche lassen Gruppen mit weniger als zwei Sitzungen weg.

## Neue Batterie aufnehmen

Einen Eintrag in `R/registry.R` (`batteries`) anlegen: Titel, Studie, Design,
Ergebnisordner (`<batterie>/output/results`), gemessene Konstrukte und die
Variablen. Jede Variable nennt Modul und Feld in der Ergebnisdatei, das
Skalenniveau (`numeric` oder `categorical`) und optional eine Umrechnung;
dazu eine Funktion `simulate` für Demodaten.

Beispiel Mozart-Effekt:

| Variable | Quelle | Typ |
|---|---|---|
| Listening condition | `setup$condition` | kategorial |
| MIQ ability | `MIQ$ability` | metrisch |
| Gender | `DEG$Gender` (Code 1–4 → female, male, diverse, rather not say) | kategorial |
| Age (years) | `DEG$Age` (Monate → volle Jahre) | metrisch |
