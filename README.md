# CAMBRIANSYSTEMS // DATA TRANSMUTATION WORKSTATION

<div align="center">

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue?logo=powershell&logoColor=white)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-0078D6?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20(Native%20.NET)-success)](#system-architecture)
[![Test Suite](https://img.shields.io/badge/Tests-16%2F16%20Passed%20(100%25)-brightgreen)](#automated-test-suite)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Encoding](https://img.shields.io/badge/Encoding-UTF--8%20%2F%20CP65001-blueviolet)](#powershell-encoding-standard)

**Enterprise Retro-Corporate Terminal & Security Workstation for Data Streams, Media Transmutation, Cryptographic Payloads & System Operations**

[System Overview](#1-system-overview) • [Quickstart & Launch](#2-how-to-launch) • [Operations Deck](#3-full-operations-directory) • [Architecture](#4-system-architecture) • [Testing & Verification](#5-automated-test-suite) • [Standards](#6-standards-compliance)

</div>

---

## 1. SYSTEM OVERVIEW

The **CambrianSystems Data Transmutation Workstation (`cambriansystems-tui`)** is a self-contained, air-gapped security workstation and data transmutation console for developers, system operators, and security engineers. Built from the ground up in pure Windows PowerShell and native .NET runtime assemblies, it provides comprehensive data processing, format conversion, cryptographic inspection, and payload encoding inside an authentic retro-computing terminal interface.

```
+==================================================================================+
|    CAMBRIANSYSTEMS CORP. // DATA INTEGRITY & BASE64 TRANSMUTATION WORKSTATION    |
|    [ SYS: ONLINE ] [ SEC-LVL: 4 ] [ RFC-4648 / MIME / JWT / GZIP / HEX-DUMP ]    |
|                 >> WORKSTATION OPERATIONAL COMMAND DECK: ROOT <<                 |
+==================================================================================+

+- [ DATA TRANSMUTATION OPERATIONS ] ----------------------------------------------+
|  --- [ DIVISION 01: CORE DATA TRANSMUTATION ] ---------------------------------  |
|   [1] TEXT TRANSMUTATION          -> Base64 Encode / Decode Plaintext (RFC-4648) |
|   [2] PHOTO & MEDIA VAULT         -> Image Ingestion, Rebuild & Phosphor Scan    |
|   [4] MULTI-TRANSCODER & SNIFFER  -> Base64URL, Hex/Base16, URI & Auto-Crack     |
|                                                                                  |
|  --- [ DIVISION 02: DOCUMENT & MEDIA CONVERSION ] ------------------------------ |
|   [A] IMAGE FORMAT TRANSCODER     -> PNG, JPG, ICO, BMP, GIF, TIFF Resizer       |
|   [C] PDF TRANSMUTATION HUB       -> PDF Data URI Packing, Rebuild & Reader      |
|   [D] MARKDOWN ASSET PACKAGER     -> Inline Local Media to Data URIs/Extract     |
|                                                                                  |
|  --- [ DIVISION 03: SECURITY TOKENS & CRYPTO PROBES ] -------------------------- |
|   [3] JWT CORPORATE INSPECTOR     -> Header & Claims Decoder with Lifetime Meter |
|   [9] BASE64 INTEGRITY INSPECTOR  -> RFC-4648 Modulo-4 Checker & SHA-256 Check   |
|   [H] MULTI-HASH TELEMETRY GRID   -> MD5, SHA-1, SHA-256, SHA-384, SHA-512       |
|   [E] STEGANOGRAPHY CARRIER       -> Hide & Extract Base64 Payloads in Media     |
|                                                                                  |
|  --- [ DIVISION 04: BINARY, COMPRESSION & QR PIPELINES ] ----------------------- |
|   [5] GZIP COMPRESSION LAB        -> High-Ratio Compressed Streams (RFC-1952)    |
|   [6] POWERSHELL ENCODED COMMAND  -> Generate & Reverse UTF-16LE -EncodedCommand |
|   [7] NORTON HEX DUMP INSPECTOR   -> Byte Memory Grid with Offset & ASCII Gutter |
|   [8] OFFLINE BATCH HTML VAULT    -> Bulk Directory Scanner & Cyber Gallery      |
|   [R] PHOSPHOR QR GENERATOR       -> Render In-Terminal Dual-Cell QR Code        |
|                                                                                  |
|  --- [ DIVISION 05: TERMINAL ENVIRONMENT & SYSTEM EXIT ] ----------------------- |
|   [0] TERMINAL ENVIRONMENT        -> CRT Themes, Sound & Line Formatting         |
|   [Q] TERMINATE WORKSTATION       -> Flush Cache Buffers & Disconnect Session    |
+----------------------------------------------------------------------------------+

 [STATUS: READY // WORKSTATION ONLINE // CAMBRIANSYSTEMS v5.2                   ]

 >> COMMAND SELECTION [0-9, A, C, D, H, E, R, Q] OR CLICK:
```

### Key Capabilities

- **Zero Installation & Zero External Dependencies**: Runs out-of-the-box on any standard Windows machine using built-in PowerShell 5.1 or PowerShell 7+. No `npm`, `pip`, `cargo`, or package managers required.
- **Air-Gapped & Secure**: Executes 100% locally in-memory with zero outbound network traffic, external API requests, or telemetry tracking.
- **Dual-Input Engine**: Navigate effortlessly by clicking any option or row with your physical mouse (ANSI VT-100 SGR mouse tracking) or typing keyboard hotkeys.
- **Robust Pipeline Support**: Seamlessly falls back to standard input streams when invoked inside automated scripts, CI/CD runners, or redirected pipelines.

---

## 2. HOW TO LAUNCH

### Option A: Command Line (CMD / PowerShell / Windows Terminal)

If the repository folder is in your system `PATH` (or while inside the project directory):

```cmd
cambriansystems-tui
```

*(Legacy command `base64-tui` is maintained as a backward-compatible alias).*

### Option B: 1-Click Launch (File Explorer)

Double-click **`launch.bat`** from Windows File Explorer. It automatically initializes UTF-8 code page `chcp 65001`, configures terminal geometry to 90×36 columns, and executes the workstation.

### Option C: Direct PowerShell Script Execution

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\cambriansystems-tui.ps1
```

### Option D: Adding to System PATH for Global Access

To launch the workstation from any command prompt across your system:

```powershell
# Add repository folder to current user's PATH (PowerShell)
$repoPath = (Get-Item .).FullName
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$repoPath", [EnvironmentVariableTarget]::User)
```

---

## 3. FULL OPERATIONS DIRECTORY

The workstation is partitioned into five distinct operational divisions:

### DIVISION 01: Core Data Transmutation

#### `[1]` Text Transmutation
- **RFC-4648 Base64 Encoding & Decoding** for UTF-8 and ASCII plaintext.
- Supports console multiline ingestion with an explicit `EOF` stop delimiter, direct Windows Clipboard ingestion, and local disk file input.
- Selectable line wrapping presets: **RFC 2045** (76 characters for MIME email), **RFC 1421** (64 characters for PEM/certificates), or continuous stream.
- **Live Graphical Expansion Meter**: Real-time ratio bar showing byte expansion (`[######------] +33.3% EXPANSION`), original string length, decoded byte length, and modulo-4 padding character count.

#### `[2]` Photo & Media Vault
- Ingest local images via drag-and-drop file paths, manual typing, or an interactive Windows GUI file chooser dialog.
- **In-Terminal Phosphor ASCII Art Scan**: Downsamples and visualizes images directly in the console screen using retro phosphor ASCII gray scales.
- **Magic-Byte Sniffer**: Automatically identifies image formats on raw byte inspection (PNG, JPEG, GIF, WebP, BMP, TIFF, ICO, SVG, PDF, and ZIP).
- Export formats: Clean Base64 stream, HTML/CSS Data URI (`data:image/png;base64,...`), or Markdown image embed tags (`![Asset](data:...)`).
- Direct 1-key launch (`[O]`) into Windows Photo Viewer.

#### `[4]` Multi-Transcoder & Heuristic Auto-Sniffer
- **Heuristic Auto-Sniffer ("Auto-Crack Engine")**: Paste any mystery encoded string, and the engine automatically detects whether it is a JWT, Base64, Base64URL, Hexadecimal (Base16), URL-encoded string, or GZip binary stream, decoding it immediately.
- **Base64URL (RFC 4648 §5)**: Converts between standard Base64 and URL-safe Base64 (substituting `+`/`/` with `-`/`_` and omitting trailing `=` padding).
- **Hexadecimal / Base16**: Bi-directional conversion between binary bytes, hex string digests (`0x...`), and UTF-8 strings.
- **URL Percent-Encoding**: Encodes and decodes web URIs (`%20`, `%2F`, `%3D`).

---

### DIVISION 02: Document & Media Conversion

#### `[A]` Image Format Transcoder & Resizer
- **Cross-Format Conversion Matrix**: Ingest images in any format and convert seamlessly between **PNG**, **JPG / JPEG**, **Windows ICO**, **BMP**, **GIF**, and **TIFF**.
- **High-Fidelity Bicubic Resizer**: Scale images to specified pixel dimensions with aspect ratio preservation or custom width/height parameters.
- **Adjustable JPEG Compression**: Calibrate JPEG quality from 1% to 100% with immediate file size delta analysis.
- **Windows Application ICO Generator**: Convert standard images into multi-resolution Windows executable icons and website favicons (16×16, 32×32, 48×48, 64×64, 128×128, 256×256).

#### `[C]` PDF Transmutation Hub
- **PDF to Base64 Data URI**: Transmute any binary PDF document into a portable `data:application/pdf;base64,...` stream.
- **Standalone Offline Cyber Reader**: Automatically generate an offline, self-contained HTML PDF viewer (`*_reader.html`) with embedded responsive canvas and download links.
- **PDF Reconstitution Engine**: Decode any pasted Base64 stream back into a 100% valid binary `.pdf` file with magic-byte validation (`%PDF-`).
- **Structural Telemetry**: Inspect PDF specification version (`%PDF-1.x`), estimate total page count, and extract document metadata.

#### `[D]` Markdown Asset Packager & Unpacker
- **Single-File Markdown Packager**: Scan any Markdown document (`.md`) for relative local image references (`![Architecture](images/diagram.png)`) and automatically inline the referenced assets into self-contained Base64 Data URIs (`![Architecture](data:image/png;base64,...)`).
- **Asset Unpacker & Re-linker**: Ingest a packaged Markdown document with inline Data URIs, extract all images to disk into an `./assets/` folder, and reconstruct clean relative Markdown links.

---

### DIVISION 03: Security Tokens & Cryptographic Probes

#### `[3]` JWT (JSON Web Token) Corporate Inspector
- Decodes standard JWT tokens (`header.payload.signature`) into structured, syntax-highlighted JSON.
- Evaluates token lifetime claims (`exp`, `iat`, `nbf`), indicating whether the token is currently **ACTIVE** or **EXPIRED**.
- **Visual Lifetime Timeline Meter**: Graphical bar indicating percentage of token validity remaining (`[##########------] 64.2% REMAINING`).
- Displays standard RFC 7519 identity claims: Issuer (`iss`), Subject (`sub`), Audience (`aud`), Algorithm (`alg`), and Key ID (`kid`).

#### `[9]` Base64 Integrity Inspector
- Tests raw strings against RFC 4648 Modulo-4 alignment requirements.
- Detects missing or invalid padding characters (`=`), identifying whitespace corruption and illegal characters.
- Generates SHA-256 cryptographic telemetry with visual pass/fail indicator badges (`[✓ PASSED]`, `[✗ FAILED]`).

#### `[H]` Cryptographic Multi-Hash Telemetry Grid
- Computes cryptographic message digests across 5 industry-standard algorithms simultaneously:
  - **MD5** (RFC 1321)
  - **SHA-1** (FIPS 180-1)
  - **SHA-256** (FIPS 180-4 Secure Hash Algorithm)
  - **SHA-384** (High-Density Suite B Digest)
  - **SHA-512** (Military-Grade Cryptographic Digest)
- **Interactive Checksum Verifier**: Paste an expected checksum to perform instant verification with automated algorithm matching and visual pass/fail confirmation (`[✓ MATCH VERIFIED]`).

#### `[E]` Digital Steganography Media Carrier
- **Payload Infiltration (Stego Inject)**: Conceal secret text or Base64 payloads inside ordinary carrier images (PNG, JPG) without affecting visual image display in Windows Photo Viewer or web browsers.
- **Carrier Recovery (Stego Scan)**: Scan media files for embedded transmission markers and extract the concealed payload with automated file type detection and 1-click clipboard extraction.

---

### DIVISION 04: Binary, Compression & QR Pipelines

#### `[5]` GZip Compression Lab
- Compresses text or files with `.NET` `GZipStream` prior to Base64 encoding.
- Ideal for high-density payloads (Kubernetes configmaps, SAML assertions, cloud-init scripts).
- **Compression Savings Ratio Meter**: Graphical progress bar displaying bytes saved (`[##############--] 88.4% SAVED`).
- Decompresses GZip Base64 back into plaintext or binary files.

#### `[6]` PowerShell `-EncodedCommand` Workstation
- Encodes PowerShell script blocks and one-liners into UTF-16LE Base64 strings for `powershell.exe -EncodedCommand <B64>`.
- Generates a ready-to-execute command line and copies it to the clipboard.
- Decodes obfuscated PowerShell commands found during security audits and incident response into syntax-highlighted script previews.

#### `[7]` Norton-Style Hex Dump Memory Inspector
- Interactive memory dump viewer for any file or Base64 payload.
- Formatted in classic DOS / Norton Commander style (16 bytes per row with offset ruler and ASCII gutter):
  ```
  00000000: 4D 5A 90 00 03 00 00 00 - 04 00 00 00 FF FF 00 00  |MZ..............|
  00000010: B8 00 00 00 00 00 00 00 - 40 00 00 00 00 00 00 00  |........@.......|
  ```
- Interactive pagination controls: `[N]ext Page`, `[P]rev Page`, `[G]oto Offset`, `[Q]uit`.

#### `[8]` Offline Batch HTML Cyber Gallery
- Select any directory of images or photos.
- Automatically processes and converts all images into self-contained Base64 Data URIs.
- Generates a standalone, dependency-free **`cambriansystems_offline_gallery.html`** styled in retro CRT phosphor with image cards and 1-click clipboard copy buttons. Works 100% offline.

#### `[R]` Phosphor Terminal QR-Code Generator
- Renders 25×25 Version 2 QR code matrices directly inside the terminal console using dual-cell Unicode block characters (`██`).
- Optical calibration: Built-in 2-module quiet zone allows physical smartphones to scan authentication tokens, URLs, and secrets straight off your physical monitor.

---

### DIVISION 05: Terminal Environment & Settings

#### `[0]` Terminal Configuration & Theming
- **Point-and-Click Mouse Support**:
  - Direct mouse clicks on any menu option or interactive box row.
  - Native Win32 Console Mode management and ANSI VT-100 SGR mouse sequences (`\e[?1000h\e[?1006h`).
  - Dual-input architecture: switch freely between mouse clicks and keyboard hotkeys.
- **7 Switchable Retro Computing Palettes**:
  1. `Corporate IBM/Novell Blue` (Royal Navy background, cyan/yellow/white)
  2. `Amber Phosphor CRT` (DEC VT-220 monochrome amber terminal)
  3. `Green Matrix Phosphor` (IBM 3270 monochrome cathode-ray terminal)
  4. `Cyberpunk Synthwave 2088` (Dark magenta/neon yellow/cyan cyberdeck)
  5. `Turbo Pascal Borland Blue` (Classic Turbo Vision IDE blue & yellow)
  6. `Solarized Hacker Monokai` (Warm terminal dark gray with yellow & cyan)
  7. `Cambrian Slate & Crimson` (Tactical slate with cyan & crimson alerts)
- **5 Configurable Window Border Styles**:
  - `Ascii`: Classic universal 7-bit ASCII (`+-+|`) *(Default)*
  - `Double`: Double-line retro Norton Commander (`╔═╗║╚═╝`)
  - `Single`: Vintage DEC VT-100 / ANSI terminal (`┌─┐│└─┘`)
  - `Rounded`: Modern boutique Unix CLI style (`╭─╮│╰─╯`)
  - `Block`: Cyberdeck / Heavy mainframe phosphor (`█▀█▌█`)
- **Acoustic Terminal Audio**: Toggle retro PC-speaker acoustic feedback (`[Console]::Beep`).

#### `[Q]` Terminate Workstation
- Flushes display and memory buffers.
- Restores standard console modes and disconnects session cleanly.

---

## 4. SYSTEM ARCHITECTURE

```
                                 [ USER INTERFACE ]
                    +------------------------------------------+
                    |   Dual-Input Engine (Mouse & Keyboard)   |
                    |   ANSI VT-100 / Win32 Console API Host   |
                    +------------------------------------------+
                                         |
                                         v
+==================================================================================+
|                 CAMBRIANSYSTEMS TRANSMUTATION KERNEL (v5.2)                      |
+==================================================================================+
|  [CORE TRANSMUTATION]    [MEDIA CONVERTER]     [SECURITY & CRYPTO]  [COMPRESSION]|
|  - RFC 4648 Base64       - Bicubic Resizer     - JWT Inspector      - GZipStream |
|  - Base64URL Encoding    - Windows ICO Engine  - Multi-Hash Grid    - Hex Dump   |
|  - Hex/Base16 Transcode  - PDF Data URI Hub    - Steganography      - QR Engine  |
|  - URI Percent-Codec     - Markdown Packager   - Modulo-4 Checker   - Batch HTML |
+==================================================================================+
                                         |
                                         v
+----------------------------------------------------------------------------------+
|                    NATIVE MICROSOFT .NET RUNTIME ASSEMBLIES                      |
|      System.Drawing  |  System.Security.Cryptography  |  System.IO.Compression   |
+----------------------------------------------------------------------------------+
```

### PowerShell Encoding Standard

> [!IMPORTANT]
> `cambriansystems-tui.ps1` is saved with **UTF-8 with BOM (`0xEF, 0xBB, 0xBF`)**. Windows PowerShell 5.1 interprets un-BOM'd UTF-8 files as Windows-1252/ANSI, which corrupts multi-byte box characters and causes script parsing failures. The repository includes an automated test suite verifying encoding health.

---

## 5. AUTOMATED TEST SUITE

The repository includes a comprehensive, automated test suite in **`test_suite.ps1`**. It verifies every core transmutation and encoding algorithm without launching the interactive user loop:

```powershell
powershell -ExecutionPolicy Bypass -File .\test_suite.ps1
```

### Verification Matrix

| Test ID | Subsystem Tested | Verification Criteria | Status |
| :---: | :--- | :--- | :---: |
| **01** | `Clean-Base64Input` | Strips Data URI headers, linefeeds, and carriage returns | :white_check_mark: **PASS** |
| **02** | `Base64 Text Roundtrip` | Full UTF-8 roundtrip encode and decode fidelity | :white_check_mark: **PASS** |
| **03** | `ConvertTo-Base64Url` | RFC 4648 §5 character substitution (`-`, `_`) and unpadding | :white_check_mark: **PASS** |
| **04** | `ConvertTo-HexString` | Hexadecimal byte array serialization and deserialization | :white_check_mark: **PASS** |
| **05** | `Compress-GZipBytes` | RFC 1952 GZip stream compression and decompress roundtrip | :white_check_mark: **PASS** |
| **06** | `PowerShell -EncodedCommand` | Windows Unicode UTF-16LE command line roundtrip | :white_check_mark: **PASS** |
| **07** | `Parse-JwtToken` | JWT header, payload claims, expiration and subject parsing | :white_check_mark: **PASS** |
| **08** | `Format-HexDumpLine` | 16-byte Norton offset ruler and ASCII gutter format | :white_check_mark: **PASS** |
| **09** | `Render-AsciiThumbnail` | Phosphor ASCII art gray scale scan generation | :white_check_mark: **PASS** |
| **10** | `Convert-ImageBytes` (JPG) | Bicubic resizing and JPEG format transcoding | :white_check_mark: **PASS** |
| **11** | `Convert-ImageBytes` (ICO) | Windows application icon container header synthesis | :white_check_mark: **PASS** |
| **12** | `Parse-PdfTelemetry` | `%PDF-1.x` magic-byte inspection and page tree estimation | :white_check_mark: **PASS** |
| **13** | `Pack-MarkdownDocument` | Inline asset bundling into Data URIs and disk unpacking | :white_check_mark: **PASS** |
| **14** | `[MiniQr]::Generate` | 25×25 Version 2 QR matrix generation with quiet zones | :white_check_mark: **PASS** |
| **15** | `Inject-StegoCarrier` | Conceals and extracts binary payloads within media carriers | :white_check_mark: **PASS** |
| **16** | `Get-MultiHashTelemetry` | Concurrent MD5, SHA-1, SHA-256, SHA-384, SHA-512 calculation | :white_check_mark: **PASS** |

---

## 6. STANDARDS COMPLIANCE

| Standard | Specification Description |
| :--- | :--- |
| **RFC 4648** | The Base16, Base32, and Base64 Data Encodings (Standard & URL-Safe) |
| **RFC 2045** | Multipurpose Internet Mail Extensions (MIME) Part One: 76-Character Wrapping |
| **RFC 1421** | Privacy Enhancement for Internet Electronic Mail: 64-Character PEM Wrapping |
| **RFC 1952** | GZIP File Format Specification version 4.3 |
| **RFC 7519** | JSON Web Token (JWT) Architecture & Claims Processing |
| **RFC 1321** | The MD5 Message-Digest Algorithm |
| **FIPS 180-4** | Secure Hash Standard (SHS): SHA-1, SHA-224, SHA-256, SHA-384, SHA-512 |
| **ANSI X3.64** | Control Sequences for Video Terminals (VT-100 / VT-220 / SGR Mouse Reporting) |

---

## 7. LICENSE & CREDITS

Developed by **CambrianSystems / CambrianMinds**.  
Released under the [MIT License](LICENSE).
