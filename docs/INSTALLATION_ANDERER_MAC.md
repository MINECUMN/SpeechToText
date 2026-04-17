# SpeechToText auf einem anderen Mac installieren

## Voraussetzungen

- macOS 13 Ventura oder neuer
- OpenAI API Key ([platform.openai.com/api-keys](https://platform.openai.com/api-keys))
- Anthropic API Key ([console.anthropic.com](https://console.anthropic.com))

---

## Schritt 1: App auf dem Haupt-Mac exportieren

Am Mac, auf dem Xcode installiert ist:

```bash
cd "/Users/Daddy/Library/CloudStorage/GoogleDrive-michael.netzig@minec.tech/Meine Ablage/Claude/Projekte/MINEC/Voice-Eingabe/SpeechToText"

# Release-Archiv erstellen
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText \
  -configuration Release -archivePath ~/Desktop/SpeechToText.xcarchive archive

# .app aus dem Archiv extrahieren
cp -R ~/Desktop/SpeechToText.xcarchive/Products/Applications/SpeechToText.app \
  ~/Desktop/SpeechToText.app

# Archiv aufraumen
rm -rf ~/Desktop/SpeechToText.xcarchive
```

Die Datei `SpeechToText.app` liegt jetzt auf dem Desktop.

---

## Schritt 2: App auf das MacBook Air ubertragen

Eine der folgenden Methoden:

| Methode | Vorgehensweise |
|---------|---------------|
| **AirDrop** | Rechtsklick auf `SpeechToText.app` → Teilen → AirDrop → MacBook Air auswahlen |
| **USB-Stick** | App auf USB-Stick kopieren, am MacBook Air einstecken |
| **iCloud Drive** | App in iCloud Drive ablegen, auf dem MacBook Air herunterladen |
| **Google Drive** | App in Google Drive hochladen, auf dem MacBook Air herunterladen |

---

## Schritt 3: App installieren (auf dem MacBook Air)

```bash
# In den Programme-Ordner verschieben
cp -R ~/Desktop/SpeechToText.app /Applications/SpeechToText.app

# Oder per Finder: SpeechToText.app in den Ordner "Programme" ziehen
```

---

## Schritt 4: Erststart und Gatekeeper

Beim ersten Offnen erscheint moglicherweise die Meldung:

> "SpeechToText" kann nicht geoffnet werden, da es von einem nicht identifizierten Entwickler stammt.

**Losung:**

1. **Systemeinstellungen** → **Datenschutz & Sicherheit**
2. Ganz unten steht: *"SpeechToText" wurde blockiert*
3. Auf **Trotzdem offnen** klicken
4. Im Dialog erneut **Offnen** bestatigen

---

## Schritt 5: Mikrofon-Berechtigung

Beim ersten Aufnehmen fragt macOS nach Mikrofonzugriff.

→ **Erlauben** klicken.

Falls verpasst:
1. **Systemeinstellungen** → **Datenschutz & Sicherheit** → **Mikrofon**
2. SpeechToText aktivieren

---

## Schritt 6: Bedienungshilfen-Berechtigung

Die App braucht Bedienungshilfen-Zugriff fur die globalen Hotkeys (Option+S/M/E).

1. **Systemeinstellungen** → **Datenschutz & Sicherheit** → **Bedienungshilfen**
2. Auf das **+** klicken
3. `/Applications/SpeechToText.app` auswahlen
4. Toggle **aktivieren**

> Bei exportierten .app-Dateien bleibt diese Berechtigung dauerhaft bestehen (anders als bei Xcode-Debug-Builds).

---

## Schritt 7: API Keys eingeben

1. Auf das **Mikrofon-Icon** in der Menubar klicken
2. **Settings...** auswahlen
3. **OpenAI API Key** eingeben → Save
4. **Anthropic (Claude) API Key** eingeben → Save

Beide Keys werden sicher im macOS Keychain gespeichert.

---

## Schritt 8: Testen

1. Ein beliebiges Textfeld offnen (Notes, Mail, Browser, Terminal...)
2. In das Textfeld klicken
3. **Option+S** gedruckt halten, einen Satz sprechen, loslassen
4. Der verbesserte Text erscheint automatisch

| Hotkey | Modus | Funktion |
|--------|-------|----------|
| **Option+S** | Standard | Grammatik/Rechtschreibung korrigieren |
| **Option+M** | Social Media | Korrektur + Emojis einfugen |
| **Option+E** | Email | Als E-Mail formatieren (Anrede, Hauptteil, Verabschiedung) |

---

## Optional: Autostart aktivieren

Damit die App bei jedem Mac-Start automatisch lauft:

**Per App:** Menubar-Icon → Settings → **Launch at Login** aktivieren

**Per Terminal:**
```bash
defaults write tech.minec.SpeechToText stt_launchAtLogin -bool true
```

---

## Troubleshooting

| Problem | Losung |
|---------|--------|
| Hotkeys reagieren nicht | Bedienungshilfen-Berechtigung prufen (Schritt 6) |
| Keine Aufnahme | Mikrofon-Berechtigung prufen (Schritt 5) |
| "Nicht identifizierter Entwickler" | Gatekeeper-Freigabe (Schritt 4) |
| Kein Text erscheint | API Keys prufen (Schritt 7) |
| App startet nicht | macOS 13+ erforderlich |
