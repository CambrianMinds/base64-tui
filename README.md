# CAMBRIANSYSTEMS // DATA TRANSMUTATION WORKSTATION v5.0
**CAMBRIANSYSTEMS INTERNAL DEVELOPER & DATA OPERATIONS UTILITY**  
*Document Ref: CS-TUI-B64-OPERATIONS-MANUAL-2026-REV5*

---

## 1. SYSTEM OVERVIEW

The **CambrianSystems Data Transmutation Workstation (`base64-tui`)** is an enterprise data and security terminal designed for high-speed encoding, decoding, inspecting, and converting data streams, cryptographic payloads, photographic media, and system commands.

```
+========================================================================================+
| CAMBRIANSYSTEMS CORP. // DATA INTEGRITY & BASE64 TRANSMUTATION WORKSTATION             |
| [ SYS: ONLINE ] [ PROTOCOL: ACTIVE ] [ RFC-4648 / JWT / GZIP / HEX-DUMP ]              |
+========================================================================================+
```

---

## 2. HOW TO LAUNCH

### Option A: 1-Click Launch

Double-click **`launch.bat`** in File Explorer.

### Option B: Terminal Command

From PowerShell or CMD:

```powershell
.\launch.bat
# or
powershell -ExecutionPolicy Bypass -File .\base64-tui.ps1
```

---

## 3. FULL OPERATIONS DIRECTORY

### [1] TEXT TRANSMUTATION

- **RFC-4648 Base64 Encoding & Decoding** for UTF-8 / ASCII text.
- Supports multiline console input (with `EOF` stop delimiter), Windows Clipboard integration, and file ingest.
- Selectable line wrapping: RFC 2045 (76 chars), RFC 1421 (64 chars), or continuous stream.
- In-depth telemetry: raw byte size, string length, bandwidth expansion percentage, and padding breakdown.

### [2] PHOTO & IMAGE TRANSMUTATION

- Drag-and-drop file paths, manual input, or Windows GUI file chooser.
- Auto-extracts image dimensions ($W \times H$) and file size.
- **In-Terminal Phosphor ASCII Art Scan**: Visualizes a downsampled retro thumbnail of the image right in the console window!
- **Magic-Byte Sniffer**: Automatically detects format on decode: PNG, JPEG, GIF, WebP, BMP, TIFF, ICO, SVG, PDF, and ZIP.
- Supports output as Raw Base64, HTML/CSS Data URI (`data:image/png;base64,...`), or Markdown image tags.
- Direct launch into Windows Photo Viewer (`[O]`).

### [3] JWT (JSON WEB TOKEN) CORPORATE INSPECTOR

- Parses JWTs (`header.payload.signature`) into structured JSON.
- Evaluates token lifetime claims (`exp`, `iat`, `nbf`) showing whether the token is currently **ACTIVE** or **EXPIRED**, with minutes elapsed/remaining.
- Displays standard identity claims: Issuer (`iss`), Subject (`sub`), Audience (`aud`), Algorithm (`alg`), and Key ID (`kid`).
- One-key copy of formatted claims to Windows Clipboard.

### [4] MULTI-TRANSCODER & HEURISTIC AUTO-SNIFFER

- **Heuristic Auto-Sniffer ("Auto-Crack")**: Paste an unknown string, and the engine automatically diagnoses whether it is a JWT, Base64, Base64URL, Hex, URL-encoded, or GZip stream, and extracts the decoded payload immediately!
- **Base64URL (RFC 4648 §5)**: Safe for URL query strings, OAuth tokens, and web APIs (uses `-` and `_`, removes `=` padding).
- **Hexadecimal / Base16**: Converts between raw binary bytes, hexadecimal strings (`0x...`), and UTF-8 plaintext.
- **URL Percent-Encoding**: Encodes and decodes web URIs (`%20`, `%2F`, etc.).

### [5] GZIP COMPRESSION LAB

- Compresses text or files with `.NET` `GZipStream` before Base64 encoding.
- Ideal for high-density payloads (SAML assertions, Kubernetes secrets, cloud configs).
- Typical compression ratio: **60% to 95% space reduction**.
- Decompresses GZip Base64 back into plaintext or binary files.

### [6] POWERSHELL `-EncodedCommand` WORKSTATION

- Encodes PowerShell commands and one-liners into UTF-16LE Base64 strings for `powershell.exe -EncodedCommand <B64>`.
- Generates a ready-to-run execution command line and copies it to the clipboard.
- Decodes obfuscated or encoded PowerShell commands found in scripts or system audits.

### [7] NORTON-STYLE HEX DUMP MEMORY INSPECTOR

- Interactive memory dump viewer for any file or Base64 payload.
- Formatted in classic DOS / Norton Commander style (16 bytes per line):
  `00000000: 4D 5A 90 00 03 00 00 00 - 04 00 00 00 FF FF 00 00  |MZ..............|`
- Paging controls: `[N]ext Page`, `[P]rev Page`, `[G]oto Offset`, `[Q]uit`.

### [8] BATCH TRANSMUTATION & OFFLINE HTML GALLERY GENERATOR

- Select any directory of images/photos.
- Converts all images in bulk to Base64 Data URIs.
- Generates a standalone, self-contained **`cambriansystems_offline_gallery.html`** with retro CRT styling, thumbnail cards, and 1-click clipboard copy buttons for every image. Works 100% offline without external dependencies.

### [9] BASE64 INTEGRITY INSPECTOR

- Validates Modulo 4 alignment, padding integrity, raw length vs cleaned length, identifies format, and generates a **SHA-256 Checksum**.

### [0] CRT DISPLAY THEMES & AUDIO

- 4 Switchable retro themes:
  1. `Corporate IBM/Novell Blue` (Navy background, cyan/yellow/white)
  2. `Amber Phosphor CRT` (DEC VT-220 monochrome amber terminal)
  3. `Green Matrix Phosphor` (IBM 3270 monochrome cathode-ray terminal)
  4. `Cambrian Slate & Crimson` (Dark gray, cyan, and red alerts)
- Toggle acoustic terminal beeps (`[Console]::Beep`).

---

## 4. SYSTEM COMPATIBILITY

- Windows 10, Windows 11, Windows Server.
- Windows PowerShell 5.1 (standard built-in) and PowerShell 7+ (pwsh).
- Zero external package dependencies.
