# Deskly ohne eigenen Mac bauen

Das Projekt ist für einen browserbasierten Cloud-Build mit Codemagic vorbereitet. Es gibt zwei getrennte Abläufe:

- **Deskly – kostenloser Prüf-Build:** kompiliert das Projekt für einen iPhone-Simulator. Dafür werden weder eine Apple-Developer-Mitgliedschaft noch Zertifikate benötigt.
- **Deskly – TestFlight:** erstellt eine signierte iPhone-/iPad-App und lädt sie zu TestFlight. Dieser Ablauf wird erst nach der Apple-Einrichtung verwendet.

## Jetzt schon möglich: Prüf-Build

1. Ein kostenloses Konto bei GitHub anlegen.
2. Ein neues **privates** Repository erstellen.
3. Den vollständigen Inhalt dieses Ordners hochladen. `codemagic.yaml` muss dabei direkt im Hauptverzeichnis des Repositorys liegen.
4. Bei [Codemagic](https://codemagic.io/) mit GitHub anmelden und das Repository hinzufügen.
5. Den Ablauf **Deskly – kostenloser Prüf-Build** manuell starten.

Der erfolgreiche Prüf-Build bestätigt, dass das Xcode-Projekt in der Apple-Umgebung kompiliert. Die erzeugte Simulator-App kann nicht direkt auf einem iPhone installiert werden.

## Später: Apple-Mitgliedschaft und TestFlight

1. Über die Apple-Developer-App auf dem iPhone oder iPad dem Apple Developer Program beitreten.
2. In Apple Developer die App-ID `com.deskly.timer` registrieren. Falls diese Kennung nicht verfügbar ist, muss sie sowohl im Xcode-Projekt als auch in `codemagic.yaml` identisch geändert werden.
3. In App Store Connect einen App-Eintrag für **Deskly** mit derselben Bundle-ID erstellen.
4. Unter **Benutzer und Zugriff > Integrationen > App Store Connect API** einen Schlüssel mit der Rolle **App Manager** erzeugen. Die `.p8`-Datei sofort sicher speichern; Apple bietet sie nur einmal zum Download an.
5. In Codemagic unter **Team settings > Integrations > Developer Portal** diesen Schlüssel hinzufügen und exakt `deskly-app-store` nennen.
6. In Codemagic passende Apple-Distribution-Zertifikate und ein App-Store-Provisioning-Profil für `com.deskly.timer` erzeugen bzw. abrufen.
7. Den Ablauf **Deskly – TestFlight** manuell starten.

Dieser Ablauf vergibt automatisch eine neue Buildnummer, erstellt die signierte `.ipa` und lädt sie zu TestFlight hoch. Er reicht Deskly **nicht** automatisch zur öffentlichen App-Store-Prüfung ein.

## Vor einer öffentlichen Veröffentlichung

- App auf einem echten iPhone und iPad testen.
- Benachrichtigungen, Alarmton und die Aktion „Alarm stoppen“ im Hintergrund prüfen.
- App-Store-Screenshots und eine öffentlich erreichbare Datenschutzseite ergänzen.
- Angaben, Altersfreigabe, Kategorie und Datenschutzinformationen in App Store Connect vollständig ausfüllen.
- Erst nach dieser Prüfung die App manuell zur App-Store-Prüfung einreichen.

Geheime Apple-Schlüssel, Zertifikate und Profile gehören ausschließlich in Codemagic bzw. App Store Connect und niemals in das Repository.
