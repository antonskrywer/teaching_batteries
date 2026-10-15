# Mozart-Effekt

Replikation von Rauscher, F. H., Shaw, G. L., & Ky, K. N. (1993).
Music and spatial task performance. *Nature, 365*(6447), 611.
https://doi.org/10.1038/365611a0

## Design

Between-Subjects mit drei Bedingungen (je ca. 10 Minuten):

| Bedingung | Audio |
|---|---|
| `music` | `www/audio/music.mp3` |
| `speech` | `www/audio/speech.mp3` |
| `silence` | keine Datei, 10-Minuten-Timer |

Abhängige Variable: Fähigkeitsschätzung im adaptiven Matrizentest MIQ (12 Items).
Im Original: Mozart KV 448, Entspannungsinstruktion, Stille; danach räumliches
Denken (Stanford-Binet).

## Ablauf

1. Consent (Checkbox, Pflicht)
2. Anonymer Code (`show_id_page`, derzeit ausgeblendet)
3. Demografie (psyquest `DEG`: Alter, Geschlecht, Land der prägenden Jahre, Erst- und Zweitsprache)
4. Audio-Instruktion
5. Audio-Seite: Track startet automatisch, Weiter-Button erst nach dem Ende
6. Instruktion kognitive Aufgabe
7. MIQ mit Instruktion und 12 Items
8. Abschluss

## Bedingungszuweisung

- Per Link: `.../mozart_effect/?condition=music` (bzw. `speech`, `silence`)
- Ohne (gültigen) Parameter: zufällig

Gespeichert in `results$setup$condition` und `results$setup$condition_source` (`url`/`random`).

## Ergebnisse

| Feld | Inhalt |
|---|---|
| `setup$consent`, `setup$condition`, `setup$condition_source` | Consent, Bedingung, Herkunft der Bedingung |
| `setup$p_code` | anonymer Code (nur mit `show_id_page <- TRUE`) |
| `DEG$...` | Demografie |
| `audio$listen_seconds` | tatsächliche Dauer bis zum Ende des Tracks/Timers |
| `MIQ$ability`, `MIQ$ability_sem` | Ergebnis MIQ |

## Hinweise

- **MIQ** ist nicht öffentlich und nur auf dem Dots-Server installiert. Lokal
  erscheint an seiner Stelle eine Platzhalterseite.
- **Debug-Modus:** `Sys.setenv(MOZART_DEBUG = "TRUE")` vor dem Start: Stille
  dauert 5 s, der Weiter-Button ist sofort sichtbar.
- **Autoplay:** Falls der Browser Autoplay blockiert, erscheint ein Start-Button.
- **Admin-Passwort** über die Umgebungsvariable `TEACHING_ADMIN_PASSWORD`.
