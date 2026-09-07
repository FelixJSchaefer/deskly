# Deskly für iPhone und iPad

Native SwiftUI-Version des ergonomischen Phasenwechsel-Timers. Das Projekt unterstützt iPhone und iPad ab iOS/iPadOS 17.

## Enthalten

- 16-teiliger Deskly-Standardplan von 08:30 bis 17:00 Uhr
- frei editierbare Phasen für Bürostuhl, Stehen, Bewegung, Sitzball, Mittagspause und eigene Einträge
- Start, Pause, Weiter, Zurück und Tag neu starten
- adaptive Oberfläche für iPhone und iPad
- touchgerechtes Drag-and-drop mit Kachelvorschau und vollständiger Einfügelücke
- lokale Benachrichtigungen für alle verbleibenden Phasen, auch wenn Deskly im Hintergrund liegt
- Benachrichtigungsaktion „Alarm stoppen“, ohne die App in den Vordergrund zu holen
- 12-sekündiger Klopfton für iOS-Mitteilungen und wiederholter Alarm im Vordergrund
- lokale Speicherung ohne Konto, Server, Tracking oder Kalendertermine
- App-Icon, Datenschutzmanifest und zwei grundlegende Tests

## In Xcode öffnen

1. Den Ordner auf einen Mac kopieren.
2. `Deskly.xcodeproj` mit Xcode 26 oder neuer öffnen.
3. Im Deskly-Target unter „Signing & Capabilities“ das eigene Apple-Developer-Team auswählen.
4. Bundle Identifier bei Bedarf von `com.deskly.timer` auf einen eigenen eindeutigen Wert ändern.
5. Als Ziel ein iPhone, iPad oder einen Simulator wählen und `⌘R` drücken.
6. Tests mit `⌘U` starten.

## Ohne eigenen Mac

Das Projekt enthält eine vorbereitete `codemagic.yaml` mit einem unsignierten Prüf-Build und einem späteren TestFlight-Build. Die vollständige browserbasierte Anleitung steht in [`OHNE-MAC-STARTEN.md`](OHNE-MAC-STARTEN.md). Für den Prüf-Build ist noch keine Apple-Developer-Mitgliedschaft nötig.

## App Store

Für die Einreichung `Product > Archive` wählen und den Organizer verwenden. Seit dem 28. April 2026 verlangt App Store Connect für iPhone-/iPad-Apps mindestens das iOS/iPadOS-26-SDK. Das Projekt kann weiterhin Geräte ab iOS 17 unterstützen.

## Wichtige iOS-Grenze

iOS erlaubt Apps keinen unbegrenzt laufenden Benachrichtigungston im Hintergrund. `Knock.wav` wird dort einmal abgespielt. Solange Deskly im Vordergrund aktiv ist, wiederholt die App den Ton bis „Alarm stoppen“ gewählt wird.

## Assets neu erzeugen

`GenerateIOSAssets.ps1` erzeugt alle App-Icon-Größen, das Header-Logo und `Knock.wav` aus dem bestehenden Deskly-Logo. Das Skript ist nur für die Asset-Pflege nötig; Xcode benötigt es nicht.
