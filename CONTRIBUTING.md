# Contributing to CambrianSystems TUI

Thank you for your interest in contributing to the **CambrianSystems Data Transmutation Workstation (`cambriansystems-tui`)**!

## Development Guidelines

1. **Native Dependencies Only**:
   - Do not add external PowerShell gallery modules (`Install-Module`) or third-party binary dependencies.
   - Use built-in Windows PowerShell 5.1 / .NET APIs (`System.Drawing`, `System.IO.Compression`, `System.Security.Cryptography`, etc.) to guarantee zero-installation portability across any modern Windows system.

2. **PowerShell Encoding Requirements (CRITICAL)**:
   - `cambriansystems-tui.ps1` **must be saved with UTF-8 with BOM (Byte Order Mark, `0xEF, 0xBB, 0xBF`)**.
   - Windows PowerShell 5.1 interprets `.ps1` files without a BOM as Windows-1252/ANSI, which corrupts multi-byte box-drawing characters and ASCII art.

3. **Visual Style Standards**:
   - Maintain the classic retro corporate terminal aesthetic:
     - Header: Centered corporate text banner framed with `+===+` borders.
     - Boxes: Clean `+---+` ASCII frames with title brackets `+- [ TITLE ] -+`.
     - Prompts: Standard single-line prompt `>> COMMAND SELECTION [...] OR CLICK: `.
     - Geometry: Default 84-column width constraint to prevent line-wrapping artifacts in 90-column consoles.

4. **Running the Automated Test Suite**:
   - Before opening a Pull Request, run the automated test suite and ensure a 100% pass rate:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\test_suite.ps1
     ```
   - If introducing a new operation or algorithm, add corresponding unit tests to `test_suite.ps1`.

## Submitting Pull Requests

1. Fork the repository and create a feature branch (`git checkout -b feat/my-enhancement`).
2. Verify all 16 tests in `test_suite.ps1` pass.
3. Commit your changes with clear, conventional commit messages (`feat: ...`, `fix: ...`, `docs: ...`).
4. Submit a Pull Request targeting `main`.
