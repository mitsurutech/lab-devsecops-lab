# Lab für DevSecOps-Pipelines mit Docker Compose: Semgrep, Gitleaks, pip-audit, Trivy und ein Security Gate

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml)

Ein fertiges Lab für den Unterricht von der [MitsuruTech Learning Platform](https://mitsurutech.co.uk/de/learning), auf der Schulen, Colleges und Hochschulen allen Studierenden eigene Datenbanken, Container und ein Terminal im Browser geben. Es vermittelt DevSecOps, indem eine Sicherheits-Pipeline um einen kleinen Webshop gebaut wird, in dem absichtlich Fehler stecken: statische Analyse mit Semgrep, Suche nach Geheimnissen in Dateien und in der Git-Historie mit Gitleaks, Prüfung der Abhängigkeiten mit pip-audit, ein dynamischer Basisscan des laufenden Shops, Prüfung von Infrastructure as Code mit Trivy und ein Security Gate, das in Gitea einen Commit-Status setzt, sodass ein geschützter Branch einen Merge ablehnt, bis das Gate bestanden ist. Es ist das Lab zum Modul [DevSecOps pipelines](https://mitsurutech.co.uk/resources/university/devsecops-pipeline).

Es ist eine einzige `docker-compose`-Datei, `compose.yaml`, und läuft auf dem eigenen Rechner genauso wie auf der Plattform, wo alle Studierenden eine private Kopie bekommen. **Scannen und greifen Sie nur Ihre eigene Kopie an.** Die Website oder den Code anderer zu scannen erfordert deren schriftliche Erlaubnis; im Vereinigten Königreich ist das unerlaubte Eindringen in einen Computer nach dem Computer Misuse Act 1990 eine Straftat.

## Was darin ist

| Dienst | Was es ist |
|---|---|
| `gitea` | Gitea, ein Git-Server, mit `student/tuckshop` und vier Commits, die beim ersten Start angelegt werden. Konto `student`, Passwort `student`, beides erfunden. Port 3000. |
| `shop` | Der Schulkiosk-Shop, direkt aus dem Repository gestartet: Port 8000 so, wie er zuerst geschrieben wurde, Port 8001 dieselbe Datei mit `--hardened` gestartet. |
| `ci` | Der Schritt-Runner der Pipeline, Python 3.12: `dast.py`, ein kleiner dynamischer Scanner, für dieses Lab nach dem Vorbild des Basisscans von OWASP ZAP geschrieben, und `gate.py`, ein Security Gate. pip-audit wird hier aus PyPI installiert, wenn eine Lektion es verlangt. |
| `semgrep` | Semgrep 1.185.0, offline, mit den eigenen Regeln des Repositorys. |
| `gitleaks` | Gitleaks 8.30.1. Es klont das Repository beim Start in das gemeinsame Volume `/work`, wo jeder Scanner es liest. |
| `trivy` | Trivy 0.76.2, für Fehlkonfigurationen im Dockerfile und in Terraform, offline mit den eingebauten Prüfungen. |

Jedes Image ist per Digest festgelegt. **Die Fehler des Shops, sein einziges Konto und der Zahlungsschlüssel in seiner Git-Historie (`tuck_live_...`) sind eingebaute Übungsdaten**, für die Übungen erfunden: Der Schlüssel ist genau das, was die Lektion zur Suche nach Geheimnissen findet, und nichts davon ist eine echte Zugangsangabe. OWASP ZAP ist nicht im Lab, weil sein Image über ein Gigabyte Java groß ist und mehr Speicher braucht, als ein Lab-Dienst bekommt; deshalb vertritt `dast.py` seinen Basisscan und sagt das auch.

## Ausprobieren

Im Terminal neben dem Lab läuft jedes Werkzeug mit `docker exec`:

```bash
docker exec semgrep semgrep scan --config /work/tuckshop/.semgrep.yml --metrics=off /work/tuckshop
docker exec gitleaks gitleaks git /work/tuckshop --no-banner --redact -v
docker exec trivy trivy config -q /work/tuckshop
docker exec ci python3 dast.py http://shop:8000/ --active
docker exec ci python3 gate.py
```

Der letzte Befehl liest die JSON-Berichte, die die Scanner nach `/work/reports` geschrieben haben. Führen Sie die Scanner also zuerst mit ihren JSON-Optionen aus, so wie es die Lektion zu Security Gates mit einer einzigen Pipeline-Datei tut.

## Verwendung auf der Plattform

Die Plattform gibt allen Studierenden eine eigene Kopie eines Labs im Browser, mit einem Terminal daneben.

**Zum Ausprobieren:** Öffnen Sie die [Container-Seite](https://mitsurutech.co.uk/de/container), suchen Sie dieses Lab unter **Sample labs** und drücken Sie Start. Dafür ist ein kostenloses Konto nötig.

**Als Aufgabe für eine Klasse:**

1. Legen Sie in Ihrem Modul eine Aufgabe vom Typ **Lab** an und wählen Sie **In a GitHub repository**.
2. Geben Sie `https://github.com/mitsurutech/lab-devsecops-lab` mit dem Branch `main` an. Die Compose-Datei ist die Vorgabe, `compose.yaml`. Forken Sie das Repository zuerst, wenn Sie es ändern möchten.
3. Veröffentlichen Sie. Jede Kopie startet von dem Commit, den Sie veröffentlicht haben, sodass eine spätere Änderung hier ein bereits gestelltes Lab nicht verändert.

Die [Seite zu diesem Lab](https://mitsurutech.co.uk/help/lab-devsecops-lab) im Hilfehandbuch und sein [Leitfaden zu Container-Labs](https://mitsurutech.co.uk/de/help/labs) erklären den Rest. Die passende Grundlagenlektion ist **DevSecOps Basics**. Noch kein College-Konto? [Das erste Jahr ist kostenlos](https://mitsurutech.co.uk/de/pricing) für bis zu 50 Studierende, und für die [Anmeldung](https://mitsurutech.co.uk/de/signup) genügt eine E-Mail-Adresse.

## Auf dem eigenen Rechner ausführen

Sie brauchen Docker mit dem Compose-Plugin.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Gitea antwortet unter <http://127.0.0.1:3000> und der Shop unter <http://127.0.0.1:8000> und <http://127.0.0.1:8001>. `local.yaml` veröffentlicht die Ports nur auf `127.0.0.1`. Der Shop ist absichtlich unsicher, also führen Sie ihn nicht dort aus, wo andere ihn erreichen können. Starten Sie die Werkzeuge mit `docker compose exec`, zum Beispiel `docker compose exec semgrep semgrep --version`. Entfernen Sie alles mit `docker compose -f compose.yaml -f local.yaml down -v`.

## Was in einem Lab nicht geht

Auf der Plattform erreicht ein Lab nur eine Positivliste von Paketseiten: pip-audit kommt auf diesem Weg aus PyPI, und sonst wird nichts heruntergeladen. Semgrep erreicht seine Regel-Registry nicht, deshalb nutzt es die Regeln des Repositorys und die eigenen der Studierenden, und Trivy nutzt seine eingebauten Prüfungen. Gitea hat keinen Actions-Runner, also führen die Studierenden die Pipeline-Datei selbst aus, wie es ein Runner täte. Das Repository und `/work` bleiben erhalten, wenn das Lab stoppt; das pip-audit des Schritt-Runners nicht.

## Das Lab prüfen

`test/check.sh` startet das Lab so, wie der Runner der Plattform jeden Dienst startet (alle Capabilities entzogen, `no-new-privileges`, ein Prozesslimit, ein Speicherlimit und kein Weg ins Internet außer für die PyPI-Installation des Schritt-Runners), führt dann jeden Befehl aus, den die Lektionen zitieren, und prüft die Ausgabe, aus einem Terminal mit den Werkzeugen, die das Terminal der Plattform hat. Es braucht Docker und läuft bei jedem Push, das ist das Abzeichen oben.

```bash
test/check.sh
```

## Lizenz

Dieses Werk steht unter der Lizenz [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.de). Sie dürfen es zum Lernen und Lehren teilen und bearbeiten, wenn Sie Mitsuru Technologies Ltd nennen, es nicht kommerziell nutzen und alles, was Sie daraus machen, unter derselben Lizenz weitergeben. Der vollständige Text steht in der Datei `LICENSE`. Gitea, Semgrep, Gitleaks, Trivy und Python laufen unverändert aus ihren eigenen öffentlichen Images, jeweils unter ihrer eigenen Lizenz.

## Über uns

Erstellt von [Mitsuru Technologies](https://mitsurutech.co.uk/de) für die [MitsuruTech Learning Platform](https://mitsurutech.co.uk/de/learning): Python, Java, Go, Node, SQL und Linux im Browser für Schulen und Colleges, mit Container-Labs, aus GitHub bereitgestellten Web-Apps und Quizzen, die sich selbst bewerten. Probieren Sie Code ohne Konto im [Playground](https://mitsurutech.co.uk/de/playground) aus.

Weitere Sicherheits-Labs aus demselben Haus: [lab-graphql-lab](https://github.com/mitsurutech/lab-graphql-lab), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
