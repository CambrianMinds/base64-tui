# cambriansystems-tui

<div align="center">

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue?logo=powershell&logoColor=white)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-0078D6?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero%20(Native%20.NET)-success)](#architecture)
[![Test Suite](https://img.shields.io/badge/Tests-16%2F16%20Passed%20(100%25)-brightgreen)](#automated-test-suite)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**A self-contained terminal workstation for encoding, decoding, hashing, and inspecting data — with zero installations and no internet access required.**

[Use Cases](#use-cases) • [Quick Start](#quick-start) • [Features](#features) • [Architecture](#architecture) • [Tests](#automated-test-suite) • [Standards](#standards-compliance)

</div>

---

A single PowerShell script that bundles the data-handling utilities I kept reaching for during daily development and security work — Base64 encoding, JWT inspection, file hashing, hex dumps, image conversion, and more — into one keyboard-driven terminal interface.

It runs on any Windows machine out of the box: no `npm`, no `pip`, no package manager, no internet. Drop it in your PATH and call it from anywhere.

```
+==================================================================================+
|    CAMBRIANSYSTEMS CORP. // DATA INTEGRITY & BASE64 TRANSMUTATION WORKSTATION    |
|    [ SYS: ONLINE ] [ SEC-LVL: 4 ] [ RFC-4648 / MIME / JWT / GZIP / HEX-DUMP ]   |
|                 >> WORKSTATION OPERATIONAL COMMAND DECK: ROOT <<                 |
+==================================================================================+

+- [ OPERATIONS ] ----------------------------------------------------------------+
|  --- [ DIVISION 01: CORE DATA TRANSMUTATION ] --------------------------------- |
|   [1] TEXT TRANSMUTATION          -> Base64 Encode / Decode Plaintext           |
|   [2] PHOTO & MEDIA VAULT         -> Image Ingestion, Rebuild & ASCII Scan      |
|   [4] MULTI-TRANSCODER & SNIFFER  -> Base64URL, Hex/Base16, URI & Auto-Crack    |
|                                                                                 |
|  --- [ DIVISION 02: DOCUMENT & MEDIA CONVERSION ] ----------------------------- |
|   [A] IMAGE FORMAT TRANSCODER     -> PNG, JPG, ICO, BMP, GIF, TIFF Resizer      |
|   [C] PDF TRANSMUTATION HUB       -> PDF Data URI Packing, Rebuild & Reader     |
|   [D] MARKDOWN ASSET PACKAGER     -> Inline Local Media to Data URIs / Extract  |
|                                                                                 |
|  --- [ DIVISION 03: SECURITY TOKENS & CRYPTO PROBES ] ------------------------- |
|   [3] JWT INSPECTOR               -> Header & Claims Decoder with Lifetime Meter|
|   [9] BASE64 INTEGRITY INSPECTOR  -> RFC-4648 Modulo-4 Checker & SHA-256        |
|   [H] MULTI-HASH TELEMETRY GRID   -> MD5, SHA-1, SHA-256, SHA-384, SHA-512      |
|   [E] STEGANOGRAPHY CARRIER       -> Hide & Extract Base64 Payloads in Media    |
|                                                                                 |
|  --- [ DIVISION 04: BINARY, COMPRESSION & QR PIPELINES ] ---------------------- |
|   [5] GZIP COMPRESSION LAB        -> Compressed Streams (RFC-1952)              |
|   [6] POWERSHELL ENCODED COMMAND  -> Generate & Reverse UTF-16LE -EncodedCommand|
|   [7] HEX DUMP INSPECTOR          -> Byte Memory Grid with Offset & ASCII Gutter|
|   [8] OFFLINE BATCH HTML VAULT    -> Bulk Directory Scanner & Gallery           |
|   [R] QR GENERATOR                -> Render In-Terminal Dual-Cell QR Code       |
|                                                                                 |
|  --- [ DIVISION 05: TERMINAL ENVIRONMENT ] ------------------------------------- |
|   [0] TERMINAL ENVIRONMENT        -> Themes, Sound & Line Formatting            |
|   [Q] QUIT                        -> Exit                                       |
+---------------------------------------------------------------------------------+
```

---

## Use Cases

The following are real workflows this tool was built to handle. Each one maps to one or more of the menu options above.

---

### Inspecting a JWT from a browser, curl response, or log file

When debugging an auth issue, you don't want to paste tokens into an online decoder. Option `[3]` decodes the header and payload locally, shows you all registered claims (`sub`, `iss`, `aud`, `exp`, `nbf`, `iat`, `alg`, `kid`), and tells you whether the token is currently valid or expired — with a visual timeline bar.

```
  TOKEN LIFETIME: [##########----------] 52.4% REMAINING
  ISSUED:    2024-01-15 10:30:22 UTC
  EXPIRES:   2024-01-16 10:30:22 UTC   [ ACTIVE ]
  SUBJECT:   service-account@project.iam
```

---

### Verifying a file download's integrity checksum

Option `[H]` computes MD5, SHA-1, SHA-256, SHA-384, and SHA-512 simultaneously for any file or pasted string. Paste in the expected hash from the download page and get an instant verified/failed result — no separate CLI commands needed.

```
  SHA-256  [MATCH VERIFIED]  e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

---

### Decoding an obfuscated PowerShell command found during an incident

Security logs and malware samples often contain `powershell.exe -EncodedCommand <blob>`. Option `[6]` decodes any UTF-16LE Base64 string back into a readable script preview in-terminal. Going the other way, it also encodes legitimate scripts for scheduled tasks or remote deployment.

---

### Auto-identifying an unknown encoded blob

Received a string and not sure if it's Base64, Base64URL, a JWT, hex, or URL-encoded? Option `[4]`'s heuristic sniffer identifies and decodes it automatically. Useful when reading config files, log entries, or API responses from an unfamiliar system.

---

### Converting an image for use in a web page, email, or Kubernetes ConfigMap

Option `[2]` takes any image from disk and outputs:
- A clean Base64 stream
- An HTML/CSS Data URI (`data:image/png;base64,...`)
- A Markdown embed tag (`![Asset](data:...)`)

Useful for embedding images in single-file HTML reports, email templates, or cloud configuration payloads that must be self-contained.

---

### Packaging a Markdown document with embedded images for sharing

Option `[D]` scans a `.md` file for all relative image references and replaces them with inline Base64 Data URIs, producing a single portable file that renders correctly anywhere without needing the source `images/` folder. The reverse (extract Data URIs back to disk) is also supported.

---

### Compressing a large config payload before Base64 encoding

GZip + Base64 is a common pattern for Kubernetes `configmap` values, SAML assertions, and `cloud-init` scripts. Option `[5]` compresses text or binary data before encoding and shows the compression ratio. Decompression works the same way in reverse.

---

### Generating a favicon or app icon from an existing image

Option `[A]` converts any image to a multi-resolution `.ico` file (16x16 through 256x256) for use as a Windows executable icon or browser favicon. Resizing, format conversion (PNG/JPG/BMP/TIFF/GIF), and JPEG quality control are all on the same screen.

---

### Generating a QR code for a URL, secret, or TOTP token

Option `[R]` renders a 25x25 Version 2 QR code directly in the terminal using Unicode block characters. Sized and padded to be physically scannable from a phone against a typical monitor. Useful for TOTP setup flows, sharing URLs during demos, or embedding auth tokens in physical documentation.

---

### Inspecting raw bytes of a file or payload

Option `[7]` renders a Norton-style hex dump of any file or decoded Base64 payload — 16 bytes per row, hex columns, ASCII gutter, navigable with `[N]ext`, `[P]rev`, and `[G]oto Offset`. Useful for verifying magic bytes, checking binary structure, or debugging a corrupt encoded payload.

```
00000000: 4D 5A 90 00 03 00 00 00 - 04 00 00 00 FF FF 00 00  |MZ..............|
00000010: B8 00 00 00 00 00 00 00 - 40 00 00 00 00 00 00 00  |........@.......|
```

---

### Building an offline image gallery

Option `[8]` processes a directory of images and produces a single self-contained `.html` file — all images embedded as Data URIs, no server required. Useful for client deliverables, offline documentation bundles, or internal reports that need to stay portable.

---

## Quick Start

**Option A: From within the project directory**

```cmd
cambriansystems-tui
```

The backward-compatible alias `base64-tui` is also maintained.

**Option B: 1-Click Launch from File Explorer**

Double-click `launch.bat`. It configures the terminal geometry, sets UTF-8 code page (`chcp 65001`), and starts the workstation.

**Option C: Direct PowerShell execution**

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\cambriansystems-tui.ps1
```

**Option D: Add to system PATH for global access**

```powershell
$repoPath = (Get-Item .).FullName
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$repoPath", [EnvironmentVariableTarget]::User)
```

---

## Features

### Core Encoding & Decoding
- **RFC 4648 Base64** — encode and decode text, files, and binary data; supports console multiline input, clipboard, and file input
- **Selectable line wrapping** — RFC 2045 (76 chars, MIME/email), RFC 1421 (64 chars, PEM), or continuous stream
- **Base64URL (RFC 4648 §5)** — URL-safe variant using `-`/`_` substitution and no `=` padding
- **Hexadecimal / Base16** — bidirectional conversion between bytes, hex digests, and strings
- **URL Percent-Encoding** — encode and decode web URIs (`%20`, `%2F`, etc.)
- **Heuristic Auto-Sniffer** — paste any mystery string; auto-detects and decodes JWT, Base64, Base64URL, Hex, URL-encoded, or GZip

### Security & Cryptography
- **JWT Inspector** — decodes any JWT locally with full claim inspection, expiry checking, and a visual lifetime progress meter
- **Multi-Hash Grid** — simultaneous MD5, SHA-1, SHA-256, SHA-384, SHA-512 with interactive checksum verifier (`[MATCH VERIFIED]`)
- **Base64 Integrity Inspector** — RFC 4648 modulo-4 alignment check, padding validation, and SHA-256 fingerprint
- **Digital Steganography** — conceal and recover binary payloads inside PNG/JPG image carriers without affecting visual display
- **PowerShell EncodedCommand** — encode and decode `powershell.exe -EncodedCommand` UTF-16LE blobs with syntax-highlighted preview

### Image & Document Processing
- **Image Format Transcoder** — convert between PNG, JPG, BMP, GIF, TIFF, and ICO with bicubic resizing and JPEG quality control
- **Windows ICO Generator** — produces multi-resolution icon containers (16x16 through 256x256) with Windows magic-byte headers
- **PDF Hub** — Data URI packing, Base64 reconstitution, structural inspection (`%PDF-1.x` version, page count), and offline reader generation
- **Markdown Asset Packager** — inline all local image references as Data URIs into a single portable `.md` file; reverse-unpack back to disk
- **Offline HTML Gallery** — convert any image directory into a single self-contained HTML file

### Binary & Compression Tools
- **GZip Lab** — compress/decompress text or binary data with a graphical savings ratio meter; integrates with the Base64 encode pipeline
- **Hex Dump Inspector** — 16-byte row viewer with offset ruler, ASCII gutter, and interactive page navigation
- **Terminal QR Generator** — 25x25 Version 2 QR matrix rendered with Unicode block characters; physically scannable from a monitor

### Terminal Environment
- **Mouse & Keyboard Dual-Input** — navigate with mouse clicks (ANSI VT-100 SGR tracking) or keyboard hotkeys
- **7 Color Palettes** — Corporate Blue, Amber Phosphor, Green Matrix, Cyberpunk Synthwave, Borland Blue, Solarized Hacker, Slate & Crimson
- **5 Border Styles** — ASCII, Double, Single, Rounded, Block
- **Pipeline Mode** — detects non-interactive or redirected STDIN; safe for use in CI/CD runners and automated scripts

---

## Architecture

The entire workstation is a single `.ps1` file with no external dependencies. It uses only assemblies that ship with the Windows .NET runtime:

| Assembly | Used for |
| :--- | :--- |
| `System.Drawing` | Image transcoding, bicubic resizing, ICO synthesis, ASCII thumbnail rendering |
| `System.Windows.Forms` | GUI file picker dialog, clipboard access |
| `System.IO.Compression` | GZip stream compression and decompression |
| `System.Security.Cryptography` | MD5, SHA-1, SHA-256, SHA-384, SHA-512 |

An inline C# block compiled at runtime via `Add-Type` provides two things the PowerShell runtime doesn't expose natively:

- **`ConsoleMouseHelper`** — Win32 `kernel32.dll` P/Invoke to toggle `ENABLE_MOUSE_INPUT` and `ENABLE_EXTENDED_FLAGS` without permanently clobbering Quick-Edit mode on exit
- **`MiniQr`** — a self-contained Version 2 QR encoder that places finder patterns, alignment patterns, timing strips, and data modules to generate a 25x25 matrix from scratch

> [!IMPORTANT]
> `cambriansystems-tui.ps1` is saved as **UTF-8 with BOM (`0xEF, 0xBB, 0xBF`)**. Windows PowerShell 5.1 interprets un-BOM'd UTF-8 as Windows-1252, which corrupts box-drawing characters and causes parse failures. The test suite verifies encoding health on every run.

---

## Automated Test Suite

```powershell
powershell -ExecutionPolicy Bypass -File .\test_suite.ps1
```

The test suite dot-sources all functions from the main script without launching the interactive loop, then runs 16 independent algorithmic verification tests. No manual interaction required.

| Test | Subsystem | Verifies |
| :---: | :--- | :--- |
| 01 | `Clean-Base64Input` | Strips Data URI headers, linefeeds, carriage returns |
| 02 | Base64 Text Roundtrip | Full UTF-8 encode/decode fidelity |
| 03 | `ConvertTo-Base64Url` | RFC 4648 §5 character substitution and unpadding |
| 04 | `ConvertTo-HexString` | Byte array hex serialization and deserialization |
| 05 | `Compress-GZipBytes` | RFC 1952 compress/decompress roundtrip |
| 06 | PowerShell `-EncodedCommand` | UTF-16LE command line roundtrip |
| 07 | `Parse-JwtToken` | Header, payload claims, expiration, subject parsing |
| 08 | `Format-HexDumpLine` | 16-byte offset ruler and ASCII gutter format |
| 09 | `Render-AsciiThumbnail` | In-terminal ASCII scan generation from image bytes |
| 10 | `Convert-ImageBytes` (JPG) | Bicubic resizing and JPEG format transcoding |
| 11 | `Convert-ImageBytes` (ICO) | Windows icon container header synthesis |
| 12 | `Parse-PdfTelemetry` | Magic-byte inspection and page tree estimation |
| 13 | `Pack-MarkdownDocument` | Inline asset bundling and disk unpack roundtrip |
| 14 | `[MiniQr]::Generate` | 25x25 Version 2 QR matrix with quiet zones |
| 15 | `Inject-StegoCarrier` | Payload injection and recovery from image carriers |
| 16 | `Get-MultiHashTelemetry` | Concurrent MD5, SHA-1, SHA-256, SHA-384, SHA-512 |

**Current status: 16/16 PASS (100%)**

---

## Standards Compliance

| Standard | Description |
| :--- | :--- |
| **RFC 4648** | Base16, Base32, and Base64 Data Encodings (Standard & URL-Safe) |
| **RFC 2045** | MIME Part One: 76-character line wrapping |
| **RFC 1421** | PEM Privacy Enhancement: 64-character line wrapping |
| **RFC 1952** | GZIP File Format Specification v4.3 |
| **RFC 7519** | JSON Web Token (JWT) Architecture & Claims |
| **RFC 1321** | MD5 Message-Digest Algorithm |
| **FIPS 180-4** | Secure Hash Standard: SHA-1, SHA-256, SHA-384, SHA-512 |
| **ANSI X3.64** | VT-100 / VT-220 / SGR Mouse Reporting Control Sequences |

---

## License

Developed by **Justin Bogner** with **Cambrian Minds**.  
Released under the [MIT License](LICENSE).
