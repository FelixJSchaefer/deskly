# Checkliste für TestFlight und App Store

Ohne eigenen Mac zuerst die Anleitung `OHNE-MAC-STARTEN.md` verwenden. Der dort vorbereitete Codemagic-Ablauf übernimmt später den signierten Build und den Upload zu TestFlight.

- Xcode 26 oder neuer auf einem kompatiblen Mac installieren oder den vorbereiteten Codemagic-Cloud-Build verwenden.
- Apple-Developer-Team im Deskly-Target auswählen.
- Eindeutigen Bundle Identifier festlegen.
- Versions- und Buildnummer kontrollieren.
- Auf mindestens einem iPhone und einem iPad testen.
- Benachrichtigungsfreigabe, Hintergrundzustand und „Alarm stoppen“ auf echten Geräten prüfen.
- VoiceOver, Dynamic Type, Hoch- und Querformat prüfen.
- App-Store-Screenshots für iPhone und iPad erstellen.
- Eine öffentlich erreichbare Datenschutzseite mit dem Text aus `APP-STORE-TEXTE.md` bereitstellen.
- In App Store Connect bei der Datenerhebung „Keine Daten erfasst“ angeben, sofern die App unverändert bleibt.
- Archiv mit `Product > Archive` erzeugen und zunächst über TestFlight verteilen.
