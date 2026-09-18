# CAMBRIANSYSTEMS // DATA TRANSMUTATION WORKSTATION v5.2
**CAMBRIANSYSTEMS INTERNAL DEVELOPER & DATA OPERATIONS UTILITY**  
*Document Ref: CS-TUI-B64-OPERATIONS-MANUAL-2026-REV5.2*

---

## 1. SYSTEM OVERVIEW

The **CambrianSystems Data Transmutation Workstation (`base64-tui`)** is an enterprise data and security terminal designed for high-speed encoding, decoding, inspecting, and converting data streams, cryptographic payloads, photographic media, and system commands.

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║   ██████╗  █████╗ ███████╗███████╗ ██████╗ ██╗  ██╗   CAMBRIANSYSTEMS WORKSTATION v5.2 ║
║   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██║  ██║   SEC-CLEARANCE: LEVEL-4 // RELAY  ║
║   ██████╔╝███████║███████╗█████╗  ███████╗ ███████║   [RFC-4648 / JWT / GZIP / HEXDUMP] ║
║   ██╔══██╗██╔══██║╚════██║██╔══╝  ██╔═══██╗╚════██║   [SYSTEM: ONLINE] [STATUS: ARMED]  ║
║   ██████╔╝██║  ██║███████║███████╗╚██████╔╝     ██║   [THEME: CORPORATE IBM/NOVE] [BOX: Double] ║
║   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝      ╚═╝   ================================= ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

---

## 2. HOW TO LAUNCH

### Option A: 1-Click Launch

Double-click **`launch.bat`** in File Explorer (automatically provisions UTF-8 code page `chcp 65001` and standard 90x34 terminal geometry).

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
- **Visual Meter Bar Telemetry**: Live graphical expansion ratio meter (`[██████░░░░░░] +33.3% EXPANSION`), raw byte size, string length, and padding breakdown.

### [2] PHOTO & IMAGE TRANSMUTATION

- Drag-and-drop file paths, manual input, or Windows GUI file chooser.
- Auto-extracts image dimensions ($W \times H$) and file size.
- **In-Terminal Phosphor ASCII Art Scan**: Visualizes a downsampled retro thumbnail of the image right in the console window framed in authentic box characters!
- **Magic-Byte Sniffer**: Automatically detects format on decode: PNG, JPEG, GIF, WebP, BMP, TIFF, ICO, SVG, PDF, and ZIP.
- Supports output as Raw Base64, HTML/CSS Data URI (`data:image/png;base64,...`), or Markdown image tags.
- Direct launch into Windows Photo Viewer (`[O]`).

### [3] JWT (JSON WEB TOKEN) CORPORATE INSPECTOR

- Parses JWTs (`header.payload.signature`) into structured JSON.
- Evaluates token lifetime claims (`exp`, `iat`, `nbf`) showing whether the token is currently **ACTIVE** or **EXPIRED**, with a **Visual Lifetime Timeline Meter** (`[██████████░░░░░░] 64.2% REMAINING`).
- Displays standard identity claims: Issuer (`iss`), Subject (`sub`), Audience (`aud`), Algorithm (`alg`), and Key ID (`kid`).
- Pretty-printed JSON payload viewer with syntax coloring and one-key clipboard copy.

### [4] MULTI-TRANSCODER & HEURISTIC AUTO-SNIFFER

- **Heuristic Auto-Sniffer ("Auto-Crack")**: Paste an unknown string, and the engine automatically diagnoses whether it is a JWT, Base64, Base64URL, Hex, URL-encoded, or GZip stream, and extracts the decoded payload immediately!
- **Base64URL (RFC 4648 §5)**: Safe for URL query strings, OAuth tokens, and web APIs (uses `-` and `_`, removes `=` padding).
- **Hexadecimal / Base16**: Converts between raw binary bytes, hexadecimal strings (`0x...`), and UTF-8 plaintext.
- **URL Percent-Encoding**: Encodes and decodes web URIs (`%20`, `%2F`, etc.).

### [5] GZIP COMPRESSION LAB

- Compresses text or files with `.NET` `GZipStream` before Base64 encoding.
- Ideal for high-density payloads (SAML assertions, Kubernetes secrets, cloud configs).
- **Visual Compression Savings Meter**: Graphical progress bar showing space saved (`[██████████████░░] 88.4% SAVED`).
- Decompresses GZip Base64 back into plaintext or binary files.

### [6] POWERSHELL `-EncodedCommand` WORKSTATION

- Encodes PowerShell commands and one-liners into UTF-16LE Base64 strings for `powershell.exe -EncodedCommand <B64>`.
- Generates a ready-to-run execution command line and copies it to the clipboard.
- Decodes obfuscated or encoded PowerShell commands found in scripts or system audits into a framed script preview.

### [7] NORTON-STYLE HEX DUMP MEMORY INSPECTOR

- Interactive memory dump viewer for any file or Base64 payload.
- Formatted in classic DOS / Norton Commander style (16 bytes per line with offset ruler and ASCII gutter):
  `00000000: 4D 5A 90 00 03 00 00 00 - 04 00 00 00 FF FF 00 00  |MZ..............|`
- Paging controls: `[N]ext Page`, `[P]rev Page`, `[G]oto Offset`, `[Q]uit`.

### [8] BATCH TRANSMUTATION & OFFLINE HTML GALLERY GENERATOR

- Select any directory of images/photos.
- Converts all images in bulk to Base64 Data URIs.
- Generates a standalone, self-contained **`cambriansystems_offline_gallery.html`** with retro CRT styling, thumbnail cards, and 1-click clipboard copy buttons for every image. Works 100% offline without external dependencies.

### [9] BASE64 INTEGRITY INSPECTOR

- Validates Modulo 4 alignment, padding integrity, raw length vs cleaned length, identifies format, verifies cryptographic health, and generates a **SHA-256 Checksum** with visual pass/fail indicator pills (`[✓ PASSED]`, `[✗ FAILED]`).

### [A] IMAGE FORMAT TRANSCODER & RESIZER

- **Cross-Format Transcoder**: Seamlessly convert between **PNG**, **JPG / JPEG**, **Windows ICO**, **BMP**, **GIF**, and **TIFF**.
- **High-Quality Bicubic Resizing**: Scale images to custom pixel dimensions while preserving aspect ratios or specifying exact width/height.
- **Adjustable JPEG Quality Engine**: Fine-tune JPEG compression levels (1-100%) with instant size delta telemetry and visual ratio meter bars.
- **Direct Windows ICO Generator**: Convert standard images into Windows application icons and website favicons with standard dimensions (16x16, 32x32, 48x48, 64x64, 128x128, 256x256).
- **Flexible Export Deck**: Save transmuted media directly to disk, copy clean Base64 strings, or copy pre-formatted HTML `<img>` Data URI tags with one keystroke or mouse click.

### [C] PDF TRANSMUTATION HUB & VIEWER

- **PDF to Base64 Data URI**: Transmute any binary PDF document into a portable `data:application/pdf;base64,...` stream.
- **Standalone Offline Cyber Reader**: Automatically generate an offline, self-contained HTML PDF viewer (`*_reader.html`) styled in dark CRT phosphor with built-in download links and embedded responsive canvas.
- **PDF Reconstitution Engine**: Decode any pasted Base64 stream back into a 100% valid binary `.pdf` document with magic-byte verification (`%PDF-`).
- **Deep Structural Telemetry**: Inspect PDF specification version (`%PDF-1.x`), estimate total page counts from catalog trees, and extract title, author, and producer attributes.

### [D] MARKDOWN ASSET PACKAGER & UNPACKER

- **Standalone Offline Packager**: Scan any Markdown document (`.md`) for relative image links (`![alt](images/diagram.png)`) and automatically bundle all referenced media assets directly into inline Base64 Data URIs (`![alt](data:image/png;base64,...)`). Produce a 100% self-contained Markdown file that requires no external assets folder!
- **Asset Unpacker & Re-linker**: Take any Markdown file with inline Base64 Data URIs, automatically extract all embedded images to disk in a dedicated `./assets/` directory, and regenerate clean relative Markdown image links.

### [R] PHOSPHOR TERMINAL QR-CODE GENERATOR

- **In-Terminal CRT Display**: Generate 25x25 Version 2 QR code matrices directly in the console using high-contrast dual-cell Unicode blocks (`██`).
- **Direct Phone Scanning**: Scan authentication tokens, Base64 strings, URLs, and secrets directly off your physical computer screen using your smartphone camera or barcode scanner.
- **Quiet-Zone Calibration**: Built-in 2-module white quiet zone ensures rapid, reliable optical decoding by mobile device cameras.

### [E] DIGITAL STEGANOGRAPHY MEDIA CARRIER

- **Payload Infiltration (Stego Inject)**: Conceal secret Base64 payloads or text inside ordinary images (JPG, PNG) without distorting visual image display in Windows Photo Viewer or web browsers.
- **Carrier Recovery (Stego Scan)**: Scan media files for hidden transmission markers and extract the recovered payload with automated file type detection and 1-click clipboard extraction.

### [H] CRYPTOGRAPHIC MULTI-HASH TELEMETRY GRID

- **Multi-Algorithm Telemetry**: Compute cryptographic message digests across 5 industry-standard algorithms simultaneously:
  - **MD5** (RFC 1321)
  - **SHA-1** (FIPS 180-1)
  - **SHA-256** (FIPS 180-4 Secure Hash)
  - **SHA-384**
  - **SHA-512** (High-Density Digest)
- **Interactive Checksum Verification**: Paste an expected checksum to perform instant verification with automated algorithm detection and visual pass/fail confirmation (`[✓ MATCH VERIFIED]`).

### [0] CRT DISPLAY THEMES, BORDERS & MOUSE CONTROL

- **Full Mouse Point-and-Click Support**:
  - Direct point-and-click selection on any menu option or interactive box row.
  - Automatic ANSI VT-100 SGR mouse reporting (`\e[?1000h\e[?1006h`) with QuickEdit console mode management.
  - Seamless dual-input architecture: select by clicking with your mouse or typing the hotkey.
  - Safe automatic fallback for headless, redirected, or automated execution pipelines.
  - Quick toggle in configuration menu: `[M] Mouse VT Tracking: ENABLED / DISABLED`.
- **7 Switchable Retro Computing Palettes**:
  1. `Corporate IBM/Novell Blue` (Royal Navy background, cyan/yellow/white)
  2. `Amber Phosphor CRT` (DEC VT-220 monochrome amber terminal)
  3. `Green Matrix Phosphor` (IBM 3270 monochrome cathode-ray terminal)
  4. `Cyberpunk Synthwave 2088` (Dark magenta/neon yellow/cyan cyberdeck)
  5. `Turbo Pascal Borland Blue` (Classic Turbo Vision IDE blue & yellow)
  6. `Solarized Hacker Monokai` (Warm terminal dark gray with yellow & cyan)
  7. `Cambrian Slate & Crimson` (Tactical slate with cyan & crimson alerts)
- **5 Configurable Window Border Styles**:
  - `Double-Line Retro`: Classic Norton Commander & Turbo Vision (`╔═╗║╚═╝`)
  - `Single-Line Clean`: Vintage DEC VT-100 / ANSI terminal (`┌─┐│└─┘`)
  - `Rounded Modern Retro`: Boutique Unix CLI style (`╭─╮│╰─╯`)
  - `Heavy Block Phosphor`: Cyberdeck / Mainframe terminal (`█▀█▌█`)
  - `Pure 7-Bit ASCII`: Universal compatibility fallback (`+-+|`)
- **Interactive Live Preview**: Real-time test box in the config menu showing the active palette, border, mouse status, and telemetry meter bar.
- Toggle acoustic terminal beeps (`[Console]::Beep`).

---

## 4. SYSTEM COMPATIBILITY & TESTS

- Windows 10, Windows 11, Windows Server.
- Windows PowerShell 5.1 (standard built-in) and PowerShell 7+ (pwsh).
- Zero external package dependencies (pure PowerShell + .NET built-ins).
- Comprehensive automated verification:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\test_suite.ps1
  ```
  Runs 16 engine test routines (RFC-4648, Base64URL, Hex, GZip, JWT, PS-EncodedCommand, HexDump, ASCII Phosphor, Image Transcoder, ICO Generator, PDF Inspector, Markdown Packager, QR Engine, Stego Carrier, Multi-Hash Grid) with 100% pass rate.


