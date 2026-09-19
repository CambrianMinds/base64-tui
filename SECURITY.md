# Security Policy

## Supported Versions

| Version | Supported          | Security Maintenance |
| ------- | ------------------ | -------------------- |
| 5.2.x   | :white_check_mark: | Active               |
| 5.0.x   | :white_check_mark: | Critical patches     |
| < 5.0   | :x:                | Deprecated           |

## Security Architecture & Guarantees

The **CambrianSystems Data Transmutation Workstation** (`cambriansystems-tui`) adheres to strict operational security principles:

1. **Air-Gapped & Fully Offline**:
   - Zero outbound HTTP/HTTPS requests or telemetry phoning home.
   - All transmutations, hash computations, and steganographic processing execute entirely within local workstation memory.

2. **No Third-Party Package Dependencies**:
   - Built exclusively using native Windows PowerShell 5.1 / .NET framework assemblies (`System.Drawing`, `System.Security.Cryptography`, `System.IO.Compression`).
   - Eliminates supply-chain risks associated with unvetted package registries.

3. **In-Memory Buffer Safety**:
   - Payloads and sensitive tokens (such as JWTs, carrier payloads, and cryptographic hashes) are processed in memory and released upon session termination.
   - Session exit commands flush volatile display buffers.

4. **Cryptographic Standards Compliance**:
   - RFC 4648 (Base64, Base64URL, Base32, Base16)
   - RFC 7519 (JSON Web Tokens)
   - RFC 1952 (GZIP Format)
   - FIPS 180-4 / RFC 1321 (SHA-256, SHA-384, SHA-512, SHA-1, MD5)

## Reporting a Security Vulnerability

If you discover a potential security flaw or unintended memory retention issue:
- Please do **not** open a public issue on GitHub.
- Submit a detailed report to the security maintainers via GitHub Private Vulnerability Reporting or contact the CambrianSystems security operations team.
- Reports are acknowledged within 24 hours with remediation coordinated prior to disclosure.
