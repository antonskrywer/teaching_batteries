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
| `TEACHING_DATA_ROOT` | Ordner, in dem die Batterien liegen. Standard: `/srv/shiny-server`, falls vorhanden (egal, wo der Monitor selbst liegt), sonst `..` (Ordner über dem Monitor, für lokale Tests). Eigener Name, damit Variablen anderer Apps auf dem Server (z. B. `MONITOR_DATA_ROOT`) nicht greifen |

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

## Batterien im Monitor

| Batterie | Ergebnisordner auf dem Server | Variablen |
|---|---|---|
| Mozart effect (Rauscher et al., 1993) | `/srv/shiny-server/mozart_effect/output/results` | Listening condition, MIQ ability, Gender, Age |
| Personality and musical preferences ([Ruth & Müllensiefen, 2020](https://psycnet.apa.org/record/2020-68799-001)) | `/srv/shiny-server/ruth_muellensiefen_2020/output/results` | MUS: Mellow, Unpretentious, Sophisticated, Intense, Contemporary (1–9) · TPI: Big Five (1–7) · GMS: General und fünf Subskalen (1–7) · Gender, Age |

Die Batterie von Ruth & Müllensiefen liegt nicht in diesem Repository, nur
auf dem Server. Aus dem Gold-MSI fehlen bewusst die Einzelitems Instrument,
Start Age und Absolute Pitch.
