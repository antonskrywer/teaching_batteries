# Mozart-Effekt

Replikation von Rauscher, F. H., Shaw, G. L., & Ky, K. N. (1993).
Music and spatial task performance. *Nature, 365*(6447), 611.
https://doi.org/10.1038/365611a0

## Design

Between-Subjects, 3 × 2: Hörbedingung × kognitiver Test.

| Bedingung | Audio |
|---|---|
| `music` | `www/audio/music.mp3` |
| `speech` | `www/audio/speech.mp3` |
| `silence` | keine Datei, 10-Minuten-Timer |

| Test | Abhängige Variable |
|---|---|
| `miq` | Fähigkeitsschätzung im adaptiven Matrizentest MIQ (12 Items) |
| `pft` | Paper Folding Test ([antonskrywer/PFT](https://github.com/antonskrywer/PFT)), Anzahl richtiger Antworten (0–20), Zeitlimit 6 Minuten |

Im Original: Mozart KV 448, Entspannungsinstruktion, Stille; danach räumliches
Denken (Stanford-Binet). Der PFT misst räumliches Vorstellungsvermögen und
liegt damit näher am Original als der MIQ.

## Ablauf

1. Consent (Checkbox, Pflicht)
2. Anonymer Code (`show_id_page`, derzeit ausgeblendet)
3. Demografie (psyquest `DEG`: Alter, Geschlecht, Land der prägenden Jahre, Erst- und Zweitsprache)
4. Audio-Instruktion
5. Audio-Seite: Track startet automatisch, Weiter-Button erst nach dem Ende
6. Instruktion kognitive Aufgabe
7. Je nach Zuweisung MIQ (Instruktion und 12 Items) oder PFT (Instruktion,
   Beispiel-Item, 20 Items in 6 Minuten); beide ohne Ergebnisrückmeldung
8. Abschluss

## Zuweisung

- Per Link, einzeln oder kombiniert:
  `.../mozart_effect/?condition=music` (bzw. `speech`, `silence`),
  `.../mozart_effect/?test=pft` (bzw. `miq`),
  `.../mozart_effect/?condition=silence&test=miq`
- Was nicht (gültig) vorgegeben ist, wird **balanciert** gezogen: zufällig unter
  den bisher am seltensten belegten der sechs Zellen (Bedingung × Test), die zu
  den Vorgaben passen. Ohne Parameter sind die Zellen also nach je sechs
  Sitzungen gleich groß; mit `?test=pft` wird die Bedingung innerhalb des PFT
  ausgeglichen.
- Gezählt wird über `output/assignments.csv` (eine Zeile pro Sitzung, wird
  schon bei der Zuweisung geschrieben). Auch abgebrochene Sitzungen und
  Testläufe mit URL-Parametern zählen mit; das Löschen von `output/` vor der
  Erhebung (DEPLOY.md, Schritt 9) setzt die Zählung zurück.

Gespeichert in `results$setup$condition`, `results$setup$test` und den
Herkunftsfeldern `condition_source`, `test_source` (`url`/`balanced`).

## Ergebnisse

| Feld | Inhalt |
|---|---|
| `setup$consent`, `setup$condition`, `setup$condition_source` | Consent, Bedingung, Herkunft der Bedingung |
| `setup$test`, `setup$test_source` | zugewiesener Test, Herkunft |
| `setup$p_code` | anonymer Code (nur mit `show_id_page <- TRUE`) |
| `DEG$...` | Demografie |
| `audio$listen_seconds` | tatsächliche Dauer bis zum Ende des Tracks/Timers |
| `MIQ$ability`, `MIQ$ability_sem` | Ergebnis MIQ (nur `test = miq`) |
| `PFT$score`, `PFT$n_answered`, `PFT$time_used`, `PFT$taskXX_...` | Ergebnis PFT (nur `test = pft`), Details im PFT-README |

## Hinweise

- **MIQ** ist nicht öffentlich und nur auf dem Dots-Server installiert. Lokal
  erscheint an seiner Stelle eine Platzhalterseite.
- **PFT** muss installiert sein: `remotes::install_github("antonskrywer/PFT")`.
- **Debug-Modus:** `Sys.setenv(MOZART_DEBUG = "TRUE")` vor dem Start: Stille
  dauert 5 s, der Weiter-Button ist sofort sichtbar.
- **Autoplay:** Falls der Browser Autoplay blockiert, erscheint ein Start-Button.
- **Admin-Passwort** über die Umgebungsvariable `TEACHING_ADMIN_PASSWORD`.
