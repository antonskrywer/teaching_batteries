# Deployment auf dem Dots-Server

Gilt für alle Batterien; Beispiel `mozart_effect`. Server: der AWS-Shiny-Server
(wie DMT, SLT und die Lernprotokolle), Login `ubuntu@…`.

Grundsätze: **kein** `sudo systemctl restart shiny-server` (bricht laufende
Sitzungen anderer Studien ab). Einzelne Apps lädt man mit `restart.txt` neu.

## Erstes Deployment

### 1. Einloggen

Wie gewohnt per SSH auf den Server einloggen.

### 2. Repository auf den Server holen *(harmlos)*

```bash
cd /srv/shiny-server
sudo git clone https://github.com/antonskrywer/teaching_batteries.git
```

### 3. Pakete prüfen *(harmlos, nur lesen)*

```bash
Rscript -e 'packageVersion("psychTestR"); packageVersion("psyquest"); packageVersion("MIQ"); args(MIQ::MIQ)'
```

Erwartet: drei Versionsnummern, und `args(MIQ::MIQ)` enthält `num_items`,
`take_training`, `with_welcome`, `with_finish` und `feedback`.

### 4. App in einen eigenen Ordner kopieren *(harmlos)*

```bash
sudo rsync -a --exclude output /srv/shiny-server/teaching_batteries/mozart_effect/ /srv/shiny-server/mozart_effect/
sudo chown -R shiny:shiny /srv/shiny-server/mozart_effect
```

Der Schrägstrich am Ende der Quelle (`mozart_effect/`) ist wichtig.

### 5. Admin-Passwort setzen *(einmalig für alle Batterien)*

Prüfen, ob es schon gesetzt ist (Ausgabe `1` = ja, `0` = nein):

```bash
sudo grep -c TEACHING_ADMIN_PASSWORD /home/shiny/.Renviron
```

Nur bei `0`, `DEIN_PASSWORT` ersetzen:

```bash
echo 'TEACHING_ADMIN_PASSWORD=DEIN_PASSWORT' | sudo tee -a /home/shiny/.Renviron
```

`tee -a` hängt an, bestehende Einträge bleiben erhalten (nie `tee` ohne `-a`).

### 6. App neu laden *(harmlos, betrifft nur diese App)*

```bash
sudo touch /srv/shiny-server/mozart_effect/restart.txt
```

### 7. Im Browser ausprobieren

```
http://<Server>:3838/mozart_effect/?condition=music
http://<Server>:3838/mozart_effect/?condition=speech
http://<Server>:3838/mozart_effect/?condition=silence
http://<Server>:3838/mozart_effect/            (zufällige Bedingung)
```

Ein Durchlauf dauert rund 20 Minuten (Audio und MIQ). Prüfen: Audio startet
von selbst, Restzeit läuft, „Next" erscheint erst am Ende, danach MIQ mit
Instruktion und 12 Items.

### 8. Ergebnisse prüfen

```bash
ls /srv/shiny-server/mozart_effect/output/results
```

Oder im Browser unten auf „Admin login" (Passwort aus Schritt 5) und Daten
herunterladen.

### 9. Testdaten löschen, bevor echte Daten kommen *(löscht Daten!)*

Nur ausführen, wenn noch keine echten Teilnehmenden dabei waren:

```bash
sudo rm -rf /srv/shiny-server/mozart_effect/output
```

Der Ordner wird beim nächsten Durchlauf neu angelegt.

## Updates

```bash
cd /srv/shiny-server/teaching_batteries && sudo git pull
sudo rsync -a --exclude output /srv/shiny-server/teaching_batteries/mozart_effect/ /srv/shiny-server/mozart_effect/
sudo chown -R shiny:shiny /srv/shiny-server/mozart_effect
sudo touch /srv/shiny-server/mozart_effect/restart.txt
```

`--exclude output` sorgt dafür, dass erhobene Daten erhalten bleiben.

## Data Monitor

Der Monitor liest die Ergebnisse unter `/srv/shiny-server/<batterie>/output/results`
(Standard für `MONITOR_DATA_ROOT`, egal in welchem Unterordner der Monitor liegt). Passwort
ist `TEACHING_ADMIN_PASSWORD` aus Schritt 5. Pakete prüfen:

```bash
Rscript -e 'packageVersion("shiny"); packageVersion("bslib"); packageVersion("ggplot2")'
```

Erstes Deployment und Updates (nach `git pull` wie oben):

```bash
sudo rsync -a /srv/shiny-server/teaching_batteries/monitor/ /srv/shiny-server/teaching_monitor/
sudo chown -R shiny:shiny /srv/shiny-server/teaching_monitor
sudo touch /srv/shiny-server/teaching_monitor/restart.txt
```

Aufruf: `http://<Server>:3838/teaching_monitor/`

Der Monitor braucht Lesezugriff auf die `output/`-Ordner der Batterien; das ist
gegeben, solange beides dem Benutzer `shiny` gehört.

## Fehlersuche

App zeigt „An error has occurred":

```bash
ls -t /var/log/shiny-server/ | grep mozart | head -3
sudo tail -50 /var/log/shiny-server/<neueste Datei>
```
