# teaching_batteries

Sammlung von [psychTestR](https://github.com/pmcharrison/psychTestR)- und
[psyquest](https://github.com/klausfrieler/psyquest)-Testbatterien für die Lehre.
Jede Batterie repliziert (vereinfacht) eine klassische Studie der
Musikpsychologie und kann im Seminar direkt durchgeführt und ausgewertet werden.

## Batterien

| Ordner | Studie | Status |
|---|---|---|
| [`mozart_effect/`](mozart_effect/) | Rauscher, Shaw & Ky (1993). Music and spatial task performance. *Nature, 365*, 611. | bereit zum Testen |

## Aufbau

Jede Batterie liegt in einem eigenen Ordner und ist als eigenständige Shiny-App lauffähig:

```
<batterie>/
├── app.R               # psychTestR-Timeline (Einstieg)
├── <batterie>_dict.csv # Texte (i18n_dict, UTF-8, Semikolon-getrennt)
├── www/                # Stimuli, CSS, Bilder
├── analysis/           # Auswertungsskripte für das Seminar
├── output/             # Ergebnisse (nicht im Repository)
└── README.md           # Studie, Design, Ablauf, Hinweise für Lehrende
```

Start einer Batterie (Arbeitsverzeichnis = Projektwurzel):

```r
shiny::runApp("mozart_effect")
```

## Voraussetzungen

- R ≥ 4.3
- `psychTestR`, `psyquest` (GitHub: `klausfrieler/psyquest`), ggf. `psychTestRCAT`

```r
install.packages(c("shiny", "remotes"))
remotes::install_github("pmcharrison/psychTestR")
remotes::install_github("klausfrieler/psyquest")
```

## Hinweise

- Admin-Passwörter stehen nicht im Code (öffentliches Repository), sondern
  kommen aus Umgebungsvariablen (`.Renviron`, nicht versioniert).
- Ergebnisordner `output/` werden nie committet.
- Deployment auf dem Dots-Server: siehe [DEPLOY.md](DEPLOY.md).
