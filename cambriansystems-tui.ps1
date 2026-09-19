<#
.SYNOPSIS
    CAMBRIANSYSTEMS // DATA TRANSMUTATION RELAY CONSOLE (CAMBRIANSYSTEMS-TUI v5.2)
    Retro-Corporate Terminal & Security Workstation
    RFC 4648 / MIME Base64 / JWT / Base64URL / Hex / GZip / PS-EncodedCommand / HexDump
.AUTHOR
    Justin Bogner with Cambrian Minds
#>

# Ensure UTF-8 Console Output Encoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Ensure required assemblies are loaded
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression

# Win32 Console Mouse & QR Code Engine
$helperCSharp = @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ConsoleMouseHelper {
    private const int STD_INPUT_HANDLE = -10;
    private const uint ENABLE_MOUSE_INPUT = 0x0010;
    private const uint ENABLE_EXTENDED_FLAGS = 0x0080;
    private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

    private static uint _origMode;
    private static bool _initialized = false;

    public static bool EnableMouse() {
        try {
            IntPtr handle = GetStdHandle(STD_INPUT_HANDLE);
            if (!GetConsoleMode(handle, out _origMode)) return false;
            uint newMode = (_origMode | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS) & ~ENABLE_QUICK_EDIT_MODE;
            bool ok = SetConsoleMode(handle, newMode);
            _initialized = ok;
            return ok;
        } catch {
            return false;
        }
    }

    public static void DisableMouse() {
        if (_initialized) {
            try {
                IntPtr handle = GetStdHandle(STD_INPUT_HANDLE);
                SetConsoleMode(handle, _origMode);
                _initialized = false;
            } catch {}
        }
    }
}

public class MiniQr {
    public static bool[,] Generate(string text) {
        byte[] data = System.Text.Encoding.UTF8.GetBytes(text);
        if (data.Length > 28) {
            byte[] truncated = new byte[28];
            Array.Copy(data, truncated, 28);
            data = truncated;
        }
        int size = 25;
        bool[,] matrix = new bool[size, size];
        bool[,] isFunction = new bool[size, size];

        AddFinder(matrix, isFunction, 0, 0);
        AddFinder(matrix, isFunction, size - 7, 0);
        AddFinder(matrix, isFunction, 0, size - 7);
        AddAlignment(matrix, isFunction, 18, 18);

        for (int i = 8; i < size - 8; i++) {
            matrix[6, i] = (i % 2 == 0); isFunction[6, i] = true;
            matrix[i, 6] = (i % 2 == 0); isFunction[i, 6] = true;
        }

        matrix[size - 8, 8] = true; isFunction[size - 8, 8] = true;
        for (int i = 0; i < 9; i++) { isFunction[i, 8] = true; isFunction[8, i] = true; }
        for (int i = size - 8; i < size; i++) { isFunction[8, i] = true; isFunction[i, 8] = true; }

        int bitIdx = 0;
        List<bool> bits = new List<bool>();
        bits.Add(false); bits.Add(true); bits.Add(false); bits.Add(false);
        for (int i = 7; i >= 0; i--) bits.Add(((data.Length >> i) & 1) == 1);
        foreach (byte b in data) {
            for (int i = 7; i >= 0; i--) bits.Add(((b >> i) & 1) == 1);
        }
        for (int i = 0; i < 4 && bits.Count < 224; i++) bits.Add(false);
        while (bits.Count % 8 != 0) bits.Add(false);
        byte[] pad = new byte[] { 0xEC, 0x11 };
        int padIdx = 0;
        while (bits.Count < 224) {
            byte pb = pad[padIdx % 2]; padIdx++;
            for (int i = 7; i >= 0; i--) bits.Add(((pb >> i) & 1) == 1);
        }

        int row = size - 1, col = size - 1, dir = -1;
        while (col > 0) {
            if (col == 6) col--;
            for (int r = 0; r < size; r++) {
                int actualRow = dir == -1 ? (size - 1 - r) : r;
                for (int c = 0; c < 2; c++) {
                    int actualCol = col - c;
                    if (!isFunction[actualRow, actualCol]) {
                        bool bit = (bitIdx < bits.Count) ? bits[bitIdx++] : false;
                        bool mask = ((actualRow + actualCol) % 2 == 0);
                        matrix[actualRow, actualCol] = bit ^ mask;
                    }
                }
            }
            dir = -dir;
            col -= 2;
        }
        return matrix;
    }

    private static void AddFinder(bool[,] m, bool[,] f, int x, int y) {
        for (int r = 0; r < 7; r++) {
            for (int c = 0; c < 7; c++) {
                bool val = (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4));
                m[x + r, y + c] = val;
                f[x + r, y + c] = true;
            }
        }
        for (int i = 0; i < 8; i++) {
            if (x + 7 < m.GetLength(0) && y + i < m.GetLength(1)) { f[x + 7, y + i] = true; m[x + 7, y + i] = false; }
            if (x + i < m.GetLength(0) && y + 7 < m.GetLength(1)) { f[x + i, y + 7] = true; m[x + i, y + 7] = false; }
            if (x - 1 >= 0 && y + i < m.GetLength(1)) { f[x - 1, y + i] = true; m[x - 1, y + i] = false; }
            if (x + i < m.GetLength(0) && y - 1 >= 0) { f[x + i, y - 1] = true; m[x + i, y - 1] = false; }
        }
    }

    private static void AddAlignment(bool[,] m, bool[,] f, int x, int y) {
        for (int r = -2; r <= 2; r++) {
            for (int c = -2; c <= 2; c++) {
                bool val = (Math.Abs(r) == 2 || Math.Abs(c) == 2 || (r == 0 && c == 0));
                m[x + r, y + c] = val;
                f[x + r, y + c] = true;
            }
        }
    }
}
"@

try {
    Add-Type -TypeDefinition $helperCSharp
} catch {}

# Global Configuration & State
$script:Config = @{
    ThemeIndex = 0
    SoundEnabled = $true
    MouseEnabled = $true
    LineWidth = 85
    WrapMode = 76 # 0 = None, 64 = RFC1421, 76 = RFC2045
    DefaultEncoding = "UTF8"
    BorderStyle = "Ascii" # Ascii, Double, Single, Rounded, Block
}

# Mouse Hitbox Tracking Engine
$script:Hitboxes = @()

function Register-Hitbox {
    param(
        [string]$key,
        [int]$row,
        [int]$startCol = 0,
        [int]$endCol = 85
    )
    $script:Hitboxes += @{
        Key = $key.ToUpper()
        Row = $row
        StartCol = $startCol
        EndCol = $endCol
    }
}

function Clear-Hitboxes {
    $script:Hitboxes = @()
}

function Read-MenuSelectionOrClick {
    param([string]$prompt = " >> SELECTION: ")
    $t = Get-Theme
    Write-Host $prompt -NoNewline -ForegroundColor $t.Alert
    
    if (-not $script:Config.MouseEnabled) {
        $in = [Console]::ReadLine()
        if ($null -eq $in) { return "" } else { return $in.ToUpper().Trim() }
    }
    
    try {
        if ([Console]::IsInputRedirected -or (-not [Environment]::UserInteractive)) {
            $in = [Console]::ReadLine()
            if ($null -eq $in) { return "" } else { return $in.ToUpper().Trim() }
        }
    } catch {
        $in = [Console]::ReadLine()
        if ($null -eq $in) { return "" } else { return $in.ToUpper().Trim() }
    }
    
    try {
        [ConsoleMouseHelper]::EnableMouse()
        Write-Host "`e[?1000h`e[?1006h" -NoNewline
    } catch {}
    
    try {
        while ($true) {
            $hasKey = $false
            try {
                $hasKey = [Console]::KeyAvailable
            } catch {
                $in = [Console]::ReadLine()
                if ($null -eq $in) { return "" } else { return $in.ToUpper().Trim() }
            }
            if ($hasKey) {
                $keyInfo = [Console]::ReadKey($true)
                
                # Check for VT SGR Mouse Sequence: \e[<0;x;yM
                if ($keyInfo.Key -eq [ConsoleKey]::Escape) {
                    Start-Sleep -Milliseconds 25
                    if ([Console]::KeyAvailable) {
                        $seq = ""
                        while ([Console]::KeyAvailable) {
                            $seq += [Console]::ReadKey($true).KeyChar
                        }
                        if ($seq -match '^\[<(\d+);(\d+);(\d+)([Mm])') {
                            $btn = [int]$matches[1]
                            $col = [int]$matches[2]
                            $row = [int]$matches[3]
                            $isPress = ($matches[4] -eq 'M')
                            
                            if ($isPress -and $btn -eq 0) {
                                foreach ($hb in $script:Hitboxes) {
                                    if ($row -eq $hb.Row -and $col -ge $hb.StartCol -and $col -le $hb.EndCol) {
                                        Play-Sound "blip"
                                        Write-Host " [CLICK: $($hb.Key)]" -ForegroundColor $t.Alert
                                        Start-Sleep -Milliseconds 120
                                        return $hb.Key
                                    }
                                }
                            }
                            continue
                        }
                    } else {
                        return "B"
                    }
                }
                
                if ($keyInfo.Key -eq [ConsoleKey]::Enter) {
                    Write-Host ""
                    return ""
                }
                
                $char = $keyInfo.KeyChar.ToString().ToUpper()
                if ($char) {
                    Write-Host $char -ForegroundColor $t.Alert
                    Play-Sound "blip"
                    Start-Sleep -Milliseconds 80
                    return $char
                }
            }
            Start-Sleep -Milliseconds 30
        }
    } finally {
        try {
            Write-Host "`e[?1000l`e[?1006l" -NoNewline
            [ConsoleMouseHelper]::DisableMouse()
        } catch {}
    }
}

# Retro Box Framing Engine (Double, Single, Rounded, Block, Ascii)
$script:BoxStyles = @{
    "Double" = @{
        Name = "DOUBLE-LINE RETRO (Norton/Turbo)"
        TL = [string][char]0x2554; TR = [string][char]0x2557; BL = [string][char]0x255A; BR = [string][char]0x255D
        H = [string][char]0x2550;  V = [string][char]0x2551;  LT = [string][char]0x2560; RT = [string][char]0x2563
        TT = [string][char]0x2566; BT = [string][char]0x2569; Cross = [string][char]0x256C
        Fill = [string][char]0x2588; Empty = [string][char]0x2591; Arrow = [string][char]0x25BA
    }
    "Single" = @{
        Name = "SINGLE-LINE CLEAN (VT-100/ANSI)"
        TL = [string][char]0x250C; TR = [string][char]0x2510; BL = [string][char]0x2514; BR = [string][char]0x2518
        H = [string][char]0x2500;  V = [string][char]0x2502;  LT = [string][char]0x251C; RT = [string][char]0x2524
        TT = [string][char]0x252C; BT = [string][char]0x2534; Cross = [string][char]0x253C
        Fill = [string][char]0x2588; Empty = [string][char]0x2591; Arrow = [string][char]0x25BA
    }
    "Rounded" = @{
        Name = "ROUNDED MODERN RETRO (CLI Boutique)"
        TL = [string][char]0x256D; TR = [string][char]0x256E; BL = [string][char]0x2570; BR = [string][char]0x256F
        H = [string][char]0x2500;  V = [string][char]0x2502;  LT = [string][char]0x251C; RT = [string][char]0x2524
        TT = [string][char]0x252C; BT = [string][char]0x2534; Cross = [string][char]0x253C
        Fill = [string][char]0x2588; Empty = [string][char]0x2591; Arrow = [string][char]0x25BA
    }
    "Block" = @{
        Name = "HEAVY BLOCK PHOSPHOR (Cyberdeck)"
        TL = [string][char]0x2588; TR = [string][char]0x2588; BL = [string][char]0x2588; BR = [string][char]0x2588
        H = [string][char]0x2580;  V = [string][char]0x2588;  LT = [string][char]0x2588; RT = [string][char]0x2588
        TT = [string][char]0x2580; BT = [string][char]0x2584; Cross = [string][char]0x2588
        Fill = [string][char]0x2588; Empty = [string][char]0x2592; Arrow = [string][char]0x25BA
    }
    "Ascii" = @{
        Name = "PURE 7-BIT ASCII (Compatibility)"
        TL = "+"; TR = "+"; BL = "+"; BR = "+"
        H = "-";  V = "|";  LT = "+"; RT = "+"
        TT = "+"; BT = "+"; Cross = "+"
        Fill = "#"; Empty = "-"; Arrow = ">"
    }
}

function Get-BoxStyle {
    $styleKey = $script:Config.BorderStyle
    if ($script:BoxStyles.ContainsKey($styleKey)) {
        return $script:BoxStyles[$styleKey]
    }
    return $script:BoxStyles["Double"]
}

# Retro Themes Palette (7 Authentic Computing Presets)
$script:Themes = @(
    @{
        Name = "CORPORATE IBM/NOVELL BLUE"
        Bg = "DarkBlue"
        Fg = "White"
        Accent = "Cyan"
        Dim = "Gray"
        Alert = "Yellow"
        Error = "Red"
        HeaderBg = "Blue"
        HeaderFg = "Yellow"
    },
    @{
        Name = "AMBER PHOSPHOR CRT (VT-220)"
        Bg = "Black"
        Fg = "DarkYellow"
        Accent = "Yellow"
        Dim = "DarkGray"
        Alert = "White"
        Error = "Red"
        HeaderBg = "Black"
        HeaderFg = "Yellow"
    },
    @{
        Name = "GREEN MATRIX PHOSPHOR (3270)"
        Bg = "Black"
        Fg = "Green"
        Accent = "DarkGreen"
        Dim = "DarkGray"
        Alert = "White"
        Error = "Red"
        HeaderBg = "Black"
        HeaderFg = "Green"
    },
    @{
        Name = "CYBERPUNK SYNTHWAVE 2088"
        Bg = "Black"
        Fg = "Cyan"
        Accent = "Magenta"
        Dim = "DarkGray"
        Alert = "Yellow"
        Error = "DarkRed"
        HeaderBg = "DarkMagenta"
        HeaderFg = "White"
    },
    @{
        Name = "TURBO PASCAL BORLAND BLUE"
        Bg = "DarkBlue"
        Fg = "White"
        Accent = "DarkCyan"
        Dim = "Gray"
        Alert = "Yellow"
        Error = "Red"
        HeaderBg = "DarkCyan"
        HeaderFg = "White"
    },
    @{
        Name = "SOLARIZED HACKER MONOKAI"
        Bg = "DarkGray"
        Fg = "Yellow"
        Accent = "Cyan"
        Dim = "Black"
        Alert = "White"
        Error = "DarkRed"
        HeaderBg = "Black"
        HeaderFg = "Green"
    },
    @{
        Name = "CAMBRIAN SLATE & CRIMSON"
        Bg = "Black"
        Fg = "Gray"
        Accent = "Cyan"
        Dim = "DarkGray"
        Alert = "Magenta"
        Error = "DarkRed"
        HeaderBg = "DarkGray"
        HeaderFg = "White"
    }
)

function Get-Theme {
    return $script:Themes[$script:Config.ThemeIndex]
}

# Sound FX
function Play-Sound {
    param([string]$type = "beep")
    if (-not $script:Config.SoundEnabled) { return }
    try {
        switch ($type) {
            "beep"    { [Console]::Beep(1200, 45) }
            "blip"    { [Console]::Beep(1800, 30); [Console]::Beep(2200, 30) }
            "error"   { [Console]::Beep(400, 120); [Console]::Beep(300, 160) }
            "success" { [Console]::Beep(880, 50); [Console]::Beep(1174, 50); [Console]::Beep(1760, 70) }
            "alert"   { [Console]::Beep(1500, 60); [Console]::Beep(1200, 60) }
        }
    } catch {}
}

# Telemetry Progress / Ratio Meter Bar Generator
function Draw-MeterBar {
    param(
        [double]$percent,
        [int]$width = 16,
        [string]$label = ""
    )
    $pctClamped = [Math]::Max(0.0, [Math]::Min(100.0, $percent))
    $fillCount = [int][Math]::Round(($pctClamped / 100.0) * $width)
    $emptyCount = [Math]::Max(0, $width - $fillCount)
    
    $filledStr = "#" * $fillCount
    $emptyStr = "-" * $emptyCount
    
    if ($label) {
        return "[$filledStr$emptyStr] $label".Trim()
    }
    return "[$filledStr$emptyStr] $([Math]::Round($percent, 1))%"
}

# Drawing & Layout Utilities
function Draw-Header {
    param(
        [string]$subTitle = "",
        [switch]$IsMainMenu
    )
    $t = Get-Theme
    $w = 84
    try {
        if ([Console]::WindowWidth -gt 84) { $w = [Console]::WindowWidth }
    } catch {}
    
    try {
        [Console]::BackgroundColor = [ConsoleColor]::$($t.Bg)
        [Console]::Clear()
    } catch {}
    Clear-Hitboxes
    
    # Corporate Top Warning
    Write-Host ("+" + ("=" * ($w - 2)) + "+") -ForegroundColor $t.Dim -BackgroundColor $t.Bg
    
    $bannerText = "CAMBRIANSYSTEMS CORP. // DATA INTEGRITY & BASE64 TRANSMUTATION WORKSTATION"
    $spaces = [Math]::Max(0, ($w - 2 - $bannerText.Length) / 2)
    $bannerLine = "|" + (" " * [Math]::Floor($spaces)) + $bannerText + (" " * [Math]::Ceiling($spaces)) + "|"
    if ($bannerLine.Length -gt $w) { $bannerLine = $bannerLine.Substring(0, $w) }
    Write-Host $bannerLine -ForegroundColor $t.HeaderFg -BackgroundColor $t.HeaderBg
    
    $secText = "[ SYS: ONLINE ] [ SEC-LVL: 4 ] [ RFC-4648 / MIME / JWT / GZIP / HEX-DUMP ]"
    $secSpaces = [Math]::Max(0, ($w - 2 - $secText.Length) / 2)
    $secLine = "|" + (" " * [Math]::Floor($secSpaces)) + $secText + (" " * [Math]::Ceiling($secSpaces)) + "|"
    if ($secLine.Length -gt $w) { $secLine = $secLine.Substring(0, $w) }
    Write-Host $secLine -ForegroundColor $t.Accent -BackgroundColor $t.Bg
    
    $sub = if ($subTitle) {
        ">> WORKSTATION SUB-SYSTEM: $subTitle <<"
    } elseif ($IsMainMenu) {
        ">> WORKSTATION OPERATIONAL COMMAND DECK: ROOT <<"
    } else {
        ""
    }
    if ($sub) {
        $subSpaces = [Math]::Max(0, ($w - 2 - $sub.Length) / 2)
        $subLine = "|" + (" " * [Math]::Floor($subSpaces)) + $sub + (" " * [Math]::Ceiling($subSpaces)) + "|"
        if ($subLine.Length -gt $w) { $subLine = $subLine.Substring(0, $w) }
        Write-Host $subLine -ForegroundColor $t.Alert -BackgroundColor $t.Bg
    }
    
    Write-Host ("+" + ("=" * ($w - 2)) + "+") -ForegroundColor $t.Dim -BackgroundColor $t.Bg
    Write-Host ""
}

function Draw-StatusBar {
    param([string]$msg = "READY // AWAITING OPERATOR INPUT")
    $t = Get-Theme
    $w = 84
    try {
        if ([Console]::WindowWidth -gt 84) { $w = [Console]::WindowWidth }
    } catch {}
    $bar = " [STATUS: " + $msg.PadRight($w - 14) + "]"
    if ($bar.Length -gt $w) { $bar = $bar.Substring(0, $w) }
    Write-Host $bar -ForegroundColor $t.Bg -BackgroundColor $t.Accent
}

function Draw-Box {
    param(
        [string[]]$lines,
        [string]$title = "",
        [string]$color = "Fg"
    )
    $t = Get-Theme
    $c = $t[$color]
    $w = 84
    try {
        $w = [Math]::Min(84, [Console]::WindowWidth - 2)
    } catch {}
    if ($w -lt 40) { $w = 84 }
    
    if ($title) {
        $dispTitle = " [ $title ] "
        if ($dispTitle.Length -gt ($w - 4)) {
            $dispTitle = $dispTitle.Substring(0, $w - 7) + "... ] "
        }
        $fill = [Math]::Max(0, $w - 3 - $dispTitle.Length)
        $top = "+-" + $dispTitle + ("-" * $fill) + "+"
    } else {
        $top = "+" + ("-" * ($w - 2)) + "+"
    }
    Write-Host $top -ForegroundColor $t.Accent -BackgroundColor $t.Bg
    
    foreach ($line in $lines) {
        $str = if ($null -eq $line) { "" } else { $line.ToString() }
        if ($str.Length -gt ($w - 4)) {
            $str = $str.Substring(0, $w - 7) + "..."
        }
        $padLen = [Math]::Max(0, $w - 4 - $str.Length)
        $padded = "| " + $str + (" " * $padLen) + " |"
        
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0 -and $str -match '^\s*\[([A-Za-z0-9])\]') {
            Register-Hitbox -key $matches[1] -row $r -startCol 0 -endCol $w
        }
        
        Write-Host $padded -ForegroundColor $c -BackgroundColor $t.Bg
    }
    
    $bot = "+" + ("-" * ($w - 2)) + "+"
    Write-Host $bot -ForegroundColor $t.Accent -BackgroundColor $t.Bg
}

# Image Header Magic-Byte Inspector
function Get-MediaInfoFromBytes {
    param([byte[]]$bytes)
    
    if (-not $bytes -or $bytes.Length -lt 4) {
        return @{ Format = "UNKNOWN"; Extension = ".bin"; Mime = "application/octet-stream"; IsImage = $false }
    }
    
    # GZIP: 1F 8B
    if ($bytes[0] -eq 0x1F -and $bytes[1] -eq 0x8B) {
        return @{ Format = "GZIP COMPRESSED ARCHIVE"; Extension = ".gz"; Mime = "application/gzip"; IsImage = $false }
    }
    
    # PNG: 89 50 4E 47 0D 0A 1A 0A
    if ($bytes.Length -ge 8 -and 
        $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47 -and
        $bytes[4] -eq 0x0D -and $bytes[5] -eq 0x0A -and $bytes[6] -eq 0x1A -and $bytes[7] -eq 0x0A) {
        return @{ Format = "PNG IMAGE"; Extension = ".png"; Mime = "image/png"; IsImage = $true }
    }
    
    # JPEG: FF D8 FF
    if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) {
        return @{ Format = "JPEG IMAGE"; Extension = ".jpg"; Mime = "image/jpeg"; IsImage = $true }
    }
    
    # GIF: 47 49 46 38 (GIF87a / GIF89a)
    if ($bytes[0] -eq 0x47 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46 -and $bytes[3] -eq 0x38) {
        return @{ Format = "GIF IMAGE"; Extension = ".gif"; Mime = "image/gif"; IsImage = $true }
    }
    
    # BMP: 42 4D (BM)
    if ($bytes[0] -eq 0x42 -and $bytes[1] -eq 0x4D) {
        return @{ Format = "WINDOWS BITMAP (BMP)"; Extension = ".bmp"; Mime = "image/bmp"; IsImage = $true }
    }
    
    # WEBP: 52 49 46 46 (RIFF) ... 57 45 42 50 (WEBP)
    if ($bytes.Length -ge 12 -and
        $bytes[0] -eq 0x52 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46 -and $bytes[3] -eq 0x46 -and
        $bytes[8] -eq 0x57 -and $bytes[9] -eq 0x45 -and $bytes[10] -eq 0x42 -and $bytes[11] -eq 0x50) {
        return @{ Format = "WEBP IMAGE"; Extension = ".webp"; Mime = "image/webp"; IsImage = $true }
    }
    
    # TIFF: 49 49 2A 00 or 4D 4D 00 2A
    if (($bytes[0] -eq 0x49 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x2A -and $bytes[3] -eq 0x00) -or
        ($bytes[0] -eq 0x4D -and $bytes[1] -eq 0x4D -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x2A)) {
        return @{ Format = "TIFF IMAGE"; Extension = ".tif"; Mime = "image/tiff"; IsImage = $true }
    }
    
    # ICO: 00 00 01 00
    if ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0x01 -and $bytes[3] -eq 0x00) {
        return @{ Format = "WINDOWS ICON (ICO)"; Extension = ".ico"; Mime = "image/x-icon"; IsImage = $true }
    }
    
    # PDF: 25 50 44 46 (%PDF)
    if ($bytes[0] -eq 0x25 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x44 -and $bytes[3] -eq 0x46) {
        return @{ Format = "PDF DOCUMENT"; Extension = ".pdf"; Mime = "application/pdf"; IsImage = $false }
    }
    
    # ZIP / DOCX / XLSX: 50 4B 03 04 (PK..)
    if ($bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B -and $bytes[2] -eq 0x03 -and $bytes[3] -eq 0x04) {
        return @{ Format = "ZIP ARCHIVE"; Extension = ".zip"; Mime = "application/zip"; IsImage = $false }
    }
    
    # SVG (Check if starts with xml / svg)
    try {
        $sample = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(128, $bytes.Length))
        if ($sample -match "<\?xml" -or $sample -match "<svg") {
            return @{ Format = "SVG VECTOR IMAGE"; Extension = ".svg"; Mime = "image/svg+xml"; IsImage = $true }
        }
    } catch {}
    
    return @{ Format = "GENERIC BINARY PAYLOAD"; Extension = ".bin"; Mime = "application/octet-stream"; IsImage = $false }
}

# In-Terminal ASCII Thumbnail Generator
function Render-AsciiThumbnail {
    param(
        [byte[]]$bytes,
        [int]$targetWidth = 44,
        [int]$targetHeight = 16
    )
    $t = Get-Theme
    $b = Get-BoxStyle
    try {
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $origBmp = [System.Drawing.Image]::FromStream($ms)
        
        $w = $origBmp.Width
        $h = $origBmp.Height
        
        $aspectRatio = ($w / [Math]::Max(1, $h)) * 0.5
        $scaledW = [int]($targetHeight * $aspectRatio * 2)
        $scaledW = [Math]::Max(16, [Math]::Min($targetWidth, $scaledW))
        $scaledH = [int]($scaledW / [Math]::Max(0.1, ($aspectRatio * 2)))
        $scaledH = [Math]::Max(6, [Math]::Min($targetHeight, $scaledH))
        
        $resized = New-Object System.Drawing.Bitmap($scaledW, $scaledH)
        $g = [System.Drawing.Graphics]::FromImage($resized)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
        $g.DrawImage($origBmp, 0, 0, $scaledW, $scaledH)
        
        $ramp = " .:-=+*#%@"
        $headerTag = $b.TL + ($b.H * 2) + " [ IMAGE PHOSPHOR SCAN: ${w}x${h} ] "
        $fillLen = [Math]::Max(2, $scaledW + 4 - $headerTag.Length)
        Write-Host $headerTag -NoNewline -ForegroundColor $t.Accent
        Write-Host (($b.H * $fillLen) + $b.TR) -ForegroundColor $t.Dim
        
        for ($y = 0; $y -lt $scaledH; $y++) {
            Write-Host ($b.V + " ") -NoNewline -ForegroundColor $t.Accent
            for ($x = 0; $x -lt $scaledW; $x++) {
                $pixel = $resized.GetPixel($x, $y)
                $luma = [int](0.299 * $pixel.R + 0.587 * $pixel.G + 0.114 * $pixel.B)
                $charIndex = [int](($luma / 255.0) * ($ramp.Length - 1))
                if ($charIndex -ge $ramp.Length) { $charIndex = $ramp.Length - 1 }
                if ($charIndex -lt 0) { $charIndex = 0 }
                $ch = $ramp[$charIndex]
                
                if ($luma -gt 180) {
                    Write-Host $ch -NoNewline -ForegroundColor $t.Alert
                } elseif ($luma -gt 80) {
                    Write-Host $ch -NoNewline -ForegroundColor $t.Fg
                } else {
                    Write-Host $ch -NoNewline -ForegroundColor $t.Dim
                }
            }
            Write-Host (" " + $b.V) -ForegroundColor $t.Accent
        }
        $footer = $b.BL + ($b.H * ($scaledW + 2)) + $b.BR
        Write-Host $footer -ForegroundColor $t.Accent
        
        $g.Dispose()
        $resized.Dispose()
        $origBmp.Dispose()
        $ms.Dispose()
        return $true
    } catch {
        Write-Host " [!] ASCII scan conversion bypassed: $($_.Exception.Message)" -ForegroundColor $t.Dim
        return $false
    }
}

# Formatting Helper
function Format-Base64Lines {
    param(
        [string]$b64,
        [int]$chunkSize = 76
    )
    if ($chunkSize -le 0 -or $b64.Length -le $chunkSize) {
        return $b64
    }
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $b64.Length; $i += $chunkSize) {
        $len = [Math]::Min($chunkSize, $b64.Length - $i)
        [void]$sb.AppendLine($b64.Substring($i, $len))
    }
    return $sb.ToString().TrimEnd("`r`n")
}

# Clean input helper
function Clean-Base64Input {
    param([string]$inputString)
    if (-not $inputString) { return "" }
    
    $clean = $inputString.Trim()
    if (($clean.StartsWith('"') -and $clean.EndsWith('"')) -or
        ($clean.StartsWith("'") -and $clean.EndsWith("'"))) {
        $clean = $clean.Substring(1, $clean.Length - 2)
    }
    
    if ($clean -match '^data:[^;]+;base64,(.+)$') {
        $clean = $matches[1]
    }
    
    $clean = $clean -replace '[\s\r\n\t]+', ''
    return $clean
}

# Base64URL Encoding & Decoding Helpers (RFC 4648 §5)
function ConvertTo-Base64Url {
    param([byte[]]$bytes)
    $b64 = [System.Convert]::ToBase64String($bytes)
    return $b64.Replace('+', '-').Replace('/', '_').TrimEnd('=')
}

function ConvertFrom-Base64Url {
    param([string]$b64Url)
    $clean = $b64Url.Trim().Replace('-', '+').Replace('_', '/')
    $pad = 4 - ($clean.Length % 4)
    if ($pad -lt 4) {
        $clean += ("=" * $pad)
    }
    return [System.Convert]::FromBase64String($clean)
}

# Hex (Base16) Helpers
function ConvertTo-HexString {
    param([byte[]]$bytes)
    return -join ($bytes | ForEach-Object { "{0:x2}" -f $_ })
}

function ConvertFrom-HexString {
    param([string]$hexStr)
    $clean = $hexStr -replace '[\s\r\n\t:-]+', ''
    if ($clean.Length % 2 -ne 0) {
        throw "Hex string length must be even (currently $($clean.Length) chars)."
    }
    $bytes = New-Object byte[] ($clean.Length / 2)
    for ($i = 0; $i -lt $clean.Length; $i += 2) {
        $bytes[$i / 2] = [System.Convert]::ToByte($clean.Substring($i, 2), 16)
    }
    return $bytes
}

# GZip Compression & Decompression Helpers
function Compress-GZipBytes {
    param([byte[]]$rawBytes)
    $ms = New-Object System.IO.MemoryStream
    $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $gz.Write($rawBytes, 0, $rawBytes.Length)
    $gz.Close()
    $res = $ms.ToArray()
    $ms.Dispose()
    return $res
}

function Decompress-GZipBytes {
    param([byte[]]$gzipBytes)
    $inMs = New-Object System.IO.MemoryStream(,$gzipBytes)
    $gz = New-Object System.IO.Compression.GZipStream($inMs, [System.IO.Compression.CompressionMode]::Decompress)
    $outMs = New-Object System.IO.MemoryStream
    $buffer = New-Object byte[] 4096
    while (($read = $gz.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $outMs.Write($buffer, 0, $read)
    }
    $gz.Close()
    $res = $outMs.ToArray()
    $inMs.Dispose()
    $outMs.Dispose()
    return $res
}

# GUI File Picker Dialog
function Show-FileDialog {
    param(
        [string]$title = "SELECT FILE FOR BASE64 PROCESSING",
        [string]$filter = "All Files (*.*)|*.*|Images (*.png;*.jpg;*.jpeg;*.gif;*.bmp;*.webp)|*.png;*.jpg;*.jpeg;*.gif;*.bmp;*.webp",
        [bool]$save = $false
    )
    if ($save) {
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
    } else {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
    }
    $dialog.Title = $title
    $dialog.Filter = $filter
    $dialog.RestoreDirectory = $true
    
    $topForm = New-Object System.Windows.Forms.Form
    $topForm.TopMost = $true
    $result = $dialog.ShowDialog($topForm)
    $topForm.Dispose()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

# Folder Browser Dialog
function Show-FolderDialog {
    param([string]$description = "SELECT DIRECTORY FOR BULK PROCESSING")
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $description
    $dialog.ShowNewFolderButton = $true
    
    $topForm = New-Object System.Windows.Forms.Form
    $topForm.TopMost = $true
    $result = $dialog.ShowDialog($topForm)
    $topForm.Dispose()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# ==============================================================================
# OPERATION 1: TEXT TRANSMUTATION
# ==============================================================================
function Invoke-TextMenu {
    $t = Get-Theme
    Draw-Header "TEXT TRANSMUTATION (BASE64)"
    Play-Sound "blip"
    
    Write-Host " [TEXT OPERATIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [1] ENCODE Plaintext -> RFC-4648 Base64" -ForegroundColor $t.Fg
    Write-Host "  [2] DECODE Base64 -> Plaintext" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Main Menu" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $opt = [Console]::ReadLine().ToUpper().Trim()
    
    if ($opt -eq "1") { Invoke-EncodeText }
    elseif ($opt -eq "2") { Invoke-DecodeText }
}

function Invoke-EncodeText {
    $t = Get-Theme
    Draw-Header "TEXT ENCODE >> BASE64"
    Play-Sound "blip"
    
    Write-Host " [INPUT SOURCE]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Direct Console Keyboard Input" -ForegroundColor $t.Fg
    Write-Host "  [2] Ingest from Windows Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [3] Ingest File from Disk" -ForegroundColor $t.Fg
    Write-Host "  [B] Cancel" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $choice = [Console]::ReadLine().ToUpper().Trim()
    
    $inputText = ""
    switch ($choice) {
        "1" {
            Write-Host "`n Enter text (End with 'EOF' or blank line):" -ForegroundColor $t.Dim
            $lines = @()
            while ($true) {
                Write-Host " IN > " -NoNewline -ForegroundColor $t.Accent
                $line = [Console]::ReadLine()
                if ($line -eq "EOF" -or ($lines.Count -gt 0 -and [string]::IsNullOrEmpty($line))) { break }
                if ($lines.Count -eq 0 -and [string]::IsNullOrEmpty($line)) { break }
                $lines += $line
            }
            $inputText = $lines -join "`r`n"
        }
        "2" {
            try {
                $inputText = [System.Windows.Forms.Clipboard]::GetText()
                if (-not $inputText) {
                    Write-Host "`n [!] CLIPBOARD EMPTY." -ForegroundColor $t.Error
                    Start-Sleep -Seconds 2; return
                }
            } catch {
                Write-Host "`n [!] Clipboard error: $_" -ForegroundColor $t.Error
                Start-Sleep -Seconds 2; return
            }
        }
        "3" {
            Write-Host "`n File path (leave empty to browse): " -NoNewline -ForegroundColor $t.Accent
            $filePath = [Console]::ReadLine().Trim('"', "'", " ")
            if (-not $filePath) { $filePath = Show-FileDialog -title "SELECT TEXT FILE" }
            if (-not $filePath -or -not (Test-Path $filePath)) { return }
            $inputText = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
        }
        default { return }
    }
    
    if ([string]::IsNullOrEmpty($inputText)) { return }
    
    $rawBytes = [System.Text.Encoding]::UTF8.GetBytes($inputText)
    $b64Result = [System.Convert]::ToBase64String($rawBytes)
    $formattedB64 = Format-Base64Lines $b64Result $script:Config.WrapMode
    
    Play-Sound "success"
    Draw-Header "TEXT ENCODE COMPLETE"
    
    $ratio = [Math]::Round((($b64Result.Length - $rawBytes.Length) / [Math]::Max(1, $rawBytes.Length)) * 100, 1)
    $expansionMeter = Draw-MeterBar $ratio 16 "+$ratio% EXPANSION"
    $stats = @(
        "SOURCE FORMAT        : UTF-8 PLAINTEXT",
        "BYTE SIZE            : $($rawBytes.Length) bytes ($($inputText.Length) characters)",
        "BASE64 STRING LENGTH : $($b64Result.Length) characters",
        "BANDWIDTH EXPANSION  : $expansionMeter",
        "PADDING              : $(if ($b64Result.EndsWith('==')) { '[==] 2 BYTES' } elseif ($b64Result.EndsWith('=')) { '[=] 1 BYTE' } else { '[NONE] 0 BYTES' })"
    )
    Draw-Box $stats "TELEMETRY METRICS" "Fg"
    Write-Host ""
    
    $b = Get-BoxStyle
    Write-Host (" " + $b.TL + ($b.H * 2) + " [ BASE64 STREAM PREVIEW (FIRST 400 CHARS) ] " + ($b.H * 24)) -ForegroundColor $t.Accent
    $previewLen = [Math]::Min(400, $formattedB64.Length)
    Write-Host $formattedB64.Substring(0, $previewLen) -ForegroundColor $t.Alert
    if ($formattedB64.Length -gt 400) {
        Write-Host " ... [$(($formattedB64.Length - 400)) CHARACTERS TRUNCATED] ..." -ForegroundColor $t.Dim
    }
    Write-Host (" " + $b.BL + ($b.H * 68)) -ForegroundColor $t.Accent
    Write-Host ""
    
    Write-Host " [ACTIONS]: [C] Copy to Clipboard | [S] Save to File | [ENTER] Main Menu" -ForegroundColor $t.Accent
    Write-Host " >> ACTION: " -NoNewline -ForegroundColor $t.Alert
    $act = [Console]::ReadLine().ToUpper().Trim()
    
    if ($act -eq "C") {
        [System.Windows.Forms.Clipboard]::SetText($b64Result)
        Play-Sound "blip"
        Write-Host "`n [OK] COPIED TO CLIPBOARD." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 2
    } elseif ($act -eq "S") {
        $savePath = Show-FileDialog -title "SAVE BASE64 OUTPUT" -filter "Base64 (*.b64)|*.b64|Text (*.txt)|*.txt" -save $true
        if ($savePath) {
            [System.IO.File]::WriteAllText($savePath, $formattedB64)
            Play-Sound "success"
            Write-Host "`n [OK] SAVED TO $savePath" -ForegroundColor $t.Alert
            Start-Sleep -Seconds 2
        }
    }
}

function Invoke-DecodeText {
    $t = Get-Theme
    Draw-Header "BASE64 >> TEXT DECODE"
    Play-Sound "blip"
    
    Write-Host " [INPUT SOURCE]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Read from Windows Clipboard" -ForegroundColor $t.Alert
    Write-Host "  [2] Direct Keyboard Entry" -ForegroundColor $t.Fg
    Write-Host "  [3] Ingest File (.b64 / .txt)" -ForegroundColor $t.Fg
    Write-Host "  [B] Cancel" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $choice = [Console]::ReadLine().ToUpper().Trim()
    
    $rawB64 = ""
    switch ($choice) {
        "1" {
            try {
                $rawB64 = [System.Windows.Forms.Clipboard]::GetText()
                if (-not $rawB64) {
                    Write-Host "`n [!] CLIPBOARD EMPTY." -ForegroundColor $t.Error
                    Start-Sleep -Seconds 2; return
                }
            } catch { return }
        }
        "2" {
            Write-Host "`n Enter Base64 string (End with 'EOF' or blank line):" -ForegroundColor $t.Dim
            $lines = @()
            while ($true) {
                Write-Host " B64 > " -NoNewline -ForegroundColor $t.Accent
                $line = [Console]::ReadLine()
                if ($line -eq "EOF" -or ($lines.Count -gt 0 -and [string]::IsNullOrEmpty($line))) { break }
                if ($lines.Count -eq 0 -and [string]::IsNullOrEmpty($line)) { break }
                $lines += $line
            }
            $rawB64 = $lines -join ""
        }
        "3" {
            Write-Host "`n File path (leave empty to browse): " -NoNewline -ForegroundColor $t.Accent
            $filePath = [Console]::ReadLine().Trim('"', "'", " ")
            if (-not $filePath) { $filePath = Show-FileDialog -title "SELECT BASE64 FILE" }
            if (-not $filePath -or -not (Test-Path $filePath)) { return }
            $rawB64 = [System.IO.File]::ReadAllText($filePath)
        }
        default { return }
    }
    
    $cleanB64 = Clean-Base64Input $rawB64
    if ([string]::IsNullOrEmpty($cleanB64)) { return }
    
    try {
        $decodedBytes = [System.Convert]::FromBase64String($cleanB64)
        $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
    } catch {
        Write-Host "`n [FATAL] DECODE ERROR: $($_.Exception.Message)" -ForegroundColor $t.Error
        Play-Sound "error"
        Start-Sleep -Seconds 2
        return
    }
    
    $mediaInfo = Get-MediaInfoFromBytes $decodedBytes
    if ($mediaInfo.IsImage) {
        Write-Host "`n [!] Payload is an image ($($mediaInfo.Format)). Switching to Photo View..." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 1
        Show-DecodedPhotoMenu $decodedBytes $cleanB64 $mediaInfo
        return
    }
    
    Play-Sound "success"
    Draw-Header "DECODE TEXT COMPLETE"
    
    $stats = @(
        "CLEANED BASE64 LENGTH: $($cleanB64.Length) characters",
        "RECOVERED BYTE COUNT : $($decodedBytes.Length) bytes",
        "ENCODING             : UTF-8 PLAINTEXT",
        "MODULO-4 INTEGRITY   : $(if ($cleanB64.Length % 4 -eq 0) { '[✓ PASSED] (Remainder: 0)' } else { '[✗ FAILED] (Remainder: ' + ($cleanB64.Length % 4) + ')' })",
        "LINES DETECTED       : $(($decodedText -split "`r`n|`n").Length) lines detected"
    )
    Draw-Box $stats "PAYLOAD TELEMETRY" "Fg"
    Write-Host ""
    
    $b = Get-BoxStyle
    Write-Host (" " + $b.TL + ($b.H * 2) + " [ DECODED PLAINTEXT PREVIEW (FIRST 500 CHARS) ] " + ($b.H * 22)) -ForegroundColor $t.Accent
    $textPreview = if ($decodedText.Length -gt 500) { $decodedText.Substring(0, 500) + "`n... [TRUNCATED] ..." } else { $decodedText }
    Write-Host $textPreview -ForegroundColor $t.Alert
    Write-Host (" " + $b.BL + ($b.H * 68)) -ForegroundColor $t.Accent
    Write-Host ""
    
    Write-Host " [ACTIONS]: [C] Copy Decoded Text | [S] Save to File | [ENTER] Main Menu" -ForegroundColor $t.Accent
    Write-Host " >> ACTION: " -NoNewline -ForegroundColor $t.Alert
    $act = [Console]::ReadLine().ToUpper().Trim()
    
    if ($act -eq "C") {
        [System.Windows.Forms.Clipboard]::SetText($decodedText)
        Play-Sound "blip"
        Write-Host "`n [OK] COPIED TO CLIPBOARD." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 2
    } elseif ($act -eq "S") {
        $savePath = Show-FileDialog -title "SAVE DECODED TEXT" -filter "Text (*.txt)|*.txt" -save $true
        if ($savePath) {
            [System.IO.File]::WriteAllText($savePath, $decodedText, [System.Text.Encoding]::UTF8)
            Play-Sound "success"
            Write-Host "`n [OK] SAVED TO $savePath" -ForegroundColor $t.Alert
            Start-Sleep -Seconds 2
        }
    }
}

# ==============================================================================
# OPERATION 2: PHOTO TRANSMUTATION
# ==============================================================================
function Invoke-PhotoMenu {
    $t = Get-Theme
    Draw-Header "PHOTO & IMAGE TRANSMUTATION"
    Play-Sound "blip"
    
    Write-Host " [PHOTO OPERATIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [1] ENCODE Image -> Base64 / Data URI / Markdown" -ForegroundColor $t.Fg
    Write-Host "  [2] DECODE Base64 -> Image Rebuild & ASCII Phosphor Scan" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Main Menu" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $opt = [Console]::ReadLine().ToUpper().Trim()
    
    if ($opt -eq "1") { Invoke-EncodePhoto }
    elseif ($opt -eq "2") { Invoke-DecodePhoto }
}

function Invoke-EncodePhoto {
    $t = Get-Theme
    Draw-Header "PHOTO ENCODE >> BASE64"
    Play-Sound "blip"
    
    Write-Host " Enter image file path (Drag & Drop or leave blank to browse):" -ForegroundColor $t.Accent
    Write-Host " >> PATH: " -NoNewline -ForegroundColor $t.Alert
    $filePath = [Console]::ReadLine().Trim('"', "'", " ")
    
    if (-not $filePath) {
        $filePath = Show-FileDialog -title "SELECT IMAGE TO ENCODE" -filter "Images (*.png;*.jpg;*.gif;*.bmp;*.webp;*.ico;*.tif)|*.png;*.jpg;*.gif;*.bmp;*.webp;*.ico;*.tif|All Files (*.*)|*.*"
    }
    if (-not $filePath -or -not (Test-Path $filePath)) { return }
    
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $mediaInfo = Get-MediaInfoFromBytes $fileBytes
    
    $dimInfo = "N/A"
    try {
        $ms = New-Object System.IO.MemoryStream(,$fileBytes)
        $img = [System.Drawing.Image]::FromStream($ms)
        $dimInfo = "$($img.Width) x $($img.Height) pixels"
        $img.Dispose()
        $ms.Dispose()
    } catch {}
    
    $rawB64 = [System.Convert]::ToBase64String($fileBytes)
    $dataUri = "data:$($mediaInfo.Mime);base64,$rawB64"
    $mdTag = "![image]($dataUri)"
    $formattedB64 = Format-Base64Lines $rawB64 $script:Config.WrapMode
    
    Play-Sound "success"
    Draw-Header "PHOTO ENCODING COMPLETED"
    
    $ratio = [Math]::Round((($rawB64.Length - $fileBytes.Length) / $fileBytes.Length) * 100, 1)
    $expansionMeter = Draw-MeterBar $ratio 16 "+$ratio%"
    $stats = @(
        "SOURCE FILE          : $([System.IO.Path]::GetFileName($filePath))",
        "FORMAT               : $($mediaInfo.Format) ($($mediaInfo.Mime))",
        "DIMENSIONS           : $dimInfo",
        "RAW SIZE             : $([Math]::Round($fileBytes.Length / 1024, 2)) KB ($($fileBytes.Length) bytes)",
        "BASE64 STRING LENGTH : $($rawB64.Length) characters",
        "EXPANSION RATIO      : $expansionMeter"
    )
    Draw-Box $stats "IMAGE TELEMETRY" "Fg"
    Write-Host ""
    
    if ($mediaInfo.IsImage) {
        Render-AsciiThumbnail $fileBytes
        Write-Host ""
    }
    
    Write-Host " [DISPOSITION]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Copy Raw Base64 string to Clipboard" -ForegroundColor $t.Alert
    Write-Host "  [2] Copy HTML/CSS Data URI to Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [3] Copy Markdown Image Tag to Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [4] Save to .b64 File on Disk" -ForegroundColor $t.Fg
    Write-Host "  [ENTER] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    switch ($c) {
        "1" { [System.Windows.Forms.Clipboard]::SetText($rawB64); Play-Sound "blip"; Start-Sleep -Seconds 2 }
        "2" { [System.Windows.Forms.Clipboard]::SetText($dataUri); Play-Sound "blip"; Start-Sleep -Seconds 2 }
        "3" { [System.Windows.Forms.Clipboard]::SetText($mdTag); Play-Sound "blip"; Start-Sleep -Seconds 2 }
        "4" {
            $savePath = Show-FileDialog -title "SAVE BASE64" -filter "Base64 (*.b64)|*.b64" -save $true
            if ($savePath) { [System.IO.File]::WriteAllText($savePath, $formattedB64); Play-Sound "success"; Start-Sleep -Seconds 2 }
        }
    }
}

function Show-DecodedPhotoMenu {
    param(
        [byte[]]$bytes,
        [string]$cleanB64,
        [hashtable]$mediaInfo
    )
    $t = Get-Theme
    Draw-Header "PHOTO RECONSTRUCTION COMPLETE"
    Play-Sound "success"
    
    $dimInfo = "N/A"
    try {
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $img = [System.Drawing.Image]::FromStream($ms)
        $dimInfo = "$($img.Width) x $($img.Height) pixels"
        $img.Dispose()
        $ms.Dispose()
    } catch {}
    
    $stats = @(
        "MAGIC HEADER         : $($mediaInfo.Format)",
        "MIME TYPE            : $($mediaInfo.Mime)",
        "SUGGESTED EXTENSION  : $($mediaInfo.Extension)",
        "DIMENSIONS           : $dimInfo",
        "RECOVERED FILE SIZE  : $([Math]::Round($bytes.Length / 1024, 2)) KB ($($bytes.Length) bytes)",
        "RECONSTRUCTION       : [✓ INTEGRITY RESTORED 100%]"
    )
    Draw-Box $stats "TELEMETRY SPECTRUM" "Fg"
    Write-Host ""
    
    if ($mediaInfo.IsImage) {
        Render-AsciiThumbnail $bytes
        Write-Host ""
    }
    
    Write-Host " [PHOTO ACTIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [S] Save Image to Disk" -ForegroundColor $t.Alert
    Write-Host "  [O] Save & Open in Windows Photo Viewer" -ForegroundColor $t.Fg
    Write-Host "  [C] Copy Data URI to Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [ENTER] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> ACTION: " -NoNewline -ForegroundColor $t.Alert
    $act = [Console]::ReadLine().ToUpper().Trim()
    
    if ($act -eq "S" -or $act -eq "O") {
        $ext = $mediaInfo.Extension
        $savePath = Show-FileDialog -title "SAVE RECOVERED PHOTO" -filter "$($mediaInfo.Format) (*$ext)|*$ext|All Files (*.*)|*.*" -save $true
        if (-not $savePath) {
            $savePath = [System.IO.Path]::Combine((Get-Location).Path, "recovered_photo_" + (Get-Date -Format "yyyyMMdd_HHmmss") + $ext)
        }
        try {
            [System.IO.File]::WriteAllBytes($savePath, $bytes)
            Play-Sound "success"
            Write-Host "`n [OK] FILE WRITTEN: $savePath" -ForegroundColor $t.Alert
            if ($act -eq "O") { Invoke-Item $savePath }
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "`n [!] Save error: $_" -ForegroundColor $t.Error
            Start-Sleep -Seconds 2
        }
    } elseif ($act -eq "C") {
        $dataUri = "data:$($mediaInfo.Mime);base64,$cleanB64"
        [System.Windows.Forms.Clipboard]::SetText($dataUri)
        Play-Sound "blip"
        Write-Host "`n [OK] DATA URI COPIED." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 2
    }
}

function Invoke-DecodePhoto {
    $t = Get-Theme
    Draw-Header "BASE64 >> PHOTO RECONSTRUCTION"
    Play-Sound "blip"
    
    Write-Host " [SOURCE SELECTION]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Ingest from Windows Clipboard" -ForegroundColor $t.Alert
    Write-Host "  [2] Ingest Base64 File from Disk (.b64 / .txt)" -ForegroundColor $t.Fg
    Write-Host "  [3] Paste Raw Base64 string into Terminal" -ForegroundColor $t.Fg
    Write-Host "  [B] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $choice = [Console]::ReadLine().ToUpper().Trim()
    
    $rawB64 = ""
    switch ($choice) {
        "1" {
            try { $rawB64 = [System.Windows.Forms.Clipboard]::GetText() } catch { return }
        }
        "2" {
            $filePath = Show-FileDialog -title "SELECT BASE64 FILE" -filter "Base64 (*.b64;*.txt)|*.b64;*.txt"
            if ($filePath -and (Test-Path $filePath)) { $rawB64 = [System.IO.File]::ReadAllText($filePath) }
        }
        "3" {
            Write-Host "`n Paste Base64 (End with 'EOF' or blank line):" -ForegroundColor $t.Dim
            $lines = @()
            while ($true) {
                Write-Host " B64 > " -NoNewline -ForegroundColor $t.Accent
                $line = [Console]::ReadLine()
                if ($line -eq "EOF" -or ($lines.Count -gt 0 -and [string]::IsNullOrEmpty($line))) { break }
                if ($lines.Count -eq 0 -and [string]::IsNullOrEmpty($line)) { break }
                $lines += $line
            }
            $rawB64 = $lines -join ""
        }
        default { return }
    }
    
    $cleanB64 = Clean-Base64Input $rawB64
    if ([string]::IsNullOrEmpty($cleanB64)) { return }
    
    try {
        $decodedBytes = [System.Convert]::FromBase64String($cleanB64)
    } catch {
        Write-Host "`n [FATAL] MALFORMED BASE64: $($_.Exception.Message)" -ForegroundColor $t.Error
        Play-Sound "error"
        Start-Sleep -Seconds 2
        return
    }
    
    $mediaInfo = Get-MediaInfoFromBytes $decodedBytes
    Show-DecodedPhotoMenu $decodedBytes $cleanB64 $mediaInfo
}

# ==============================================================================
# OPERATION 3: JWT (JSON WEB TOKEN) CORPORATE INSPECTOR
# ==============================================================================
function Parse-JwtToken {
    param([string]$jwtString)
    
    $token = $jwtString.Trim()
    if ($token.StartsWith("Bearer ", [System.StringComparison]::OrdinalIgnoreCase)) {
        $token = $token.Substring(7).Trim()
    }
    
    $parts = $token.Split('.')
    if ($parts.Length -lt 2) {
        throw "String is not a valid JWT format (expected 3 segments separated by dots)."
    }
    
    # Decode Header
    $headerBytes = ConvertFrom-Base64Url $parts[0]
    $headerJson = [System.Text.Encoding]::UTF8.GetString($headerBytes)
    $headerObj = $headerJson | ConvertFrom-Json
    
    # Decode Payload
    $payloadBytes = ConvertFrom-Base64Url $parts[1]
    $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
    $payloadObj = $payloadJson | ConvertFrom-Json
    
    $sig = if ($parts.Length -ge 3) { $parts[2] } else { "(NO SIGNATURE)" }
    
    return @{
        Header = $headerObj
        HeaderRaw = $headerJson
        Payload = $payloadObj
        PayloadRaw = $payloadJson
        Signature = $sig
        PartCount = $parts.Length
    }
}

function Invoke-JwtInspector {
    $t = Get-Theme
    Draw-Header "JWT CORPORATE TOKEN INSPECTOR"
    Play-Sound "blip"
    
    Write-Host " Ingest JSON Web Token (JWT):" -ForegroundColor $t.Accent
    Write-Host "  [1] Read Token from Windows Clipboard" -ForegroundColor $t.Alert
    Write-Host "  [2] Manually Enter / Paste JWT" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Main Menu" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    $token = ""
    if ($c -eq "1") {
        try { $token = [System.Windows.Forms.Clipboard]::GetText() } catch {}
    } elseif ($c -eq "2") {
        Write-Host "`n Paste JWT: " -NoNewline -ForegroundColor $t.Accent
        $token = [Console]::ReadLine()
    } else { return }
    
    if ([string]::IsNullOrEmpty($token)) { return }
    
    try {
        $jwt = Parse-JwtToken $token
    } catch {
        Write-Host "`n [!] JWT DECODE FAULT: $($_.Exception.Message)" -ForegroundColor $t.Error
        Play-Sound "error"
        Start-Sleep -Seconds 2
        return
    }
    
    Play-Sound "success"
    Draw-Header "JWT CLAIMS & LIFETIME TELEMETRY"
    
    # Check Timestamps
    $now = (Get-Date).ToUniversalTime()
    $statusText = "UNKNOWN LIFETIME (NO 'exp' CLAIM)"
    $statusColor = "Alert"
    $timelineMeter = ""
    
    if ($jwt.Payload.PSObject.Properties['exp']) {
        $expVal = [long]$jwt.Payload.exp
        $expTime = ([DateTimeOffset]::FromUnixTimeSeconds($expVal)).UtcDateTime
        if ($expTime -lt $now) {
            $diff = $now - $expTime
            $statusText = "EXPIRED ($([Math]::Round($diff.TotalMinutes, 1))m ago at $(($expTime.ToLocalTime()).ToString('yyyy-MM-dd HH:mm:ss')))"
            $statusColor = "Error"
            $timelineMeter = Draw-MeterBar 0.0 16 "0% (EXPIRED)"
        } else {
            $diff = $expTime - $now
            $statusText = "ACTIVE ($([Math]::Round($diff.TotalMinutes, 1))m remaining until $(($expTime.ToLocalTime()).ToString('yyyy-MM-dd HH:mm:ss')))"
            $statusColor = "Fg"
            if ($jwt.Payload.PSObject.Properties['iat']) {
                $iatVal = [long]$jwt.Payload.iat
                $totalSec = [Math]::Max(1, $expVal - $iatVal)
                $nowSec = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                $elapsedSec = [Math]::Max(0, $nowSec - $iatVal)
                $pctRemaining = [Math]::Max(0.0, [Math]::Min(100.0, (1.0 - ($elapsedSec / $totalSec)) * 100))
                $timelineMeter = Draw-MeterBar $pctRemaining 16 "$([Math]::Round($pctRemaining, 1))% REMAINING"
            } else {
                $timelineMeter = "[✓ VALID SIGNED TOKEN]"
            }
        }
    }
    
    $headerSummary = @(
        "ALGORITHM (alg)      : $($jwt.Header.alg)",
        "TOKEN TYPE (typ)     : $($jwt.Header.typ)",
        "KEY ID (kid)         : $(if ($jwt.Header.PSObject.Properties['kid']) { $jwt.Header.kid } else { 'NONE' })"
    )
    Draw-Box $headerSummary "JWT HEADER" "Accent"
    Write-Host ""
    
    $payloadSummary = @(
        "TOKEN LIFETIME       : $statusText",
        "LIFETIME METER       : $(if ($timelineMeter) { $timelineMeter } else { 'N/A' })",
        "ISSUER (iss)         : $(if ($jwt.Payload.PSObject.Properties['iss']) { $jwt.Payload.iss } else { 'NOT SPECIFIED' })",
        "SUBJECT (sub)        : $(if ($jwt.Payload.PSObject.Properties['sub']) { $jwt.Payload.sub } else { 'NOT SPECIFIED' })",
        "AUDIENCE (aud)       : $(if ($jwt.Payload.PSObject.Properties['aud']) { $jwt.Payload.aud } else { 'NOT SPECIFIED' })"
    )
    Draw-Box $payloadSummary "SECURITY CONTEXT & CLAIMS" $statusColor
    Write-Host ""
    
    $b = Get-BoxStyle
    Write-Host (" " + $b.TL + ($b.H * 2) + " [ DECODED PAYLOAD CLAIMS (RAW JSON) ] " + ($b.H * 24)) -ForegroundColor $t.Accent
    try {
        $prettyJson = $jwt.PayloadRaw | ConvertFrom-Json | ConvertTo-Json -Depth 6
        Write-Host $prettyJson -ForegroundColor $t.Alert
    } catch {
        Write-Host $jwt.PayloadRaw -ForegroundColor $t.Alert
    }
    Write-Host (" " + $b.BL + ($b.H * 68)) -ForegroundColor $t.Accent
    Write-Host ""
    
    Write-Host " [ACTIONS]: [C] Copy Claims JSON to Clipboard | [ENTER] Return" -ForegroundColor $t.Accent
    Write-Host " >> ACTION: " -NoNewline -ForegroundColor $t.Alert
    $act = [Console]::ReadLine().ToUpper().Trim()
    if ($act -eq "C") {
        [System.Windows.Forms.Clipboard]::SetText($jwt.PayloadRaw)
        Play-Sound "blip"
        Write-Host "`n [OK] CLAIMS COPIED TO CLIPBOARD." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 2
    }
}

# ==============================================================================
# OPERATION 4: MULTI-TRANSCODER & HEURISTIC AUTO-SNIFFER
# ==============================================================================
function Invoke-MultiTranscoder {
    $t = Get-Theme
    Draw-Header "MULTI-TRANSCODER & HEURISTIC AUTO-SNIFFER"
    Play-Sound "blip"
    
    Write-Host " [SELECT TRANSMUTATION MODE]:" -ForegroundColor $t.Accent
    Write-Host "  [1] HEURISTIC AUTO-SNIFFER (Analyze, Identify & Crack Unknown String)" -ForegroundColor $t.Alert
    Write-Host "  [2] BASE64-URL (RFC 4648 §5) Encode / Decode" -ForegroundColor $t.Fg
    Write-Host "  [3] HEX / BASE16 (Bytes <-> Hexadecimal) Encode / Decode" -ForegroundColor $t.Fg
    Write-Host "  [4] URL / PERCENT-ENCODING (Web URI Strings)" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Main Menu" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> SELECTION: " -NoNewline -ForegroundColor $t.Alert
    $m = [Console]::ReadLine().ToUpper().Trim()
    
    switch ($m) {
        "1" { Invoke-HeuristicSniffer }
        "2" { Invoke-Base64UrlMenu }
        "3" { Invoke-HexMenu }
        "4" { Invoke-UrlEncodeMenu }
    }
}

function Invoke-HeuristicSniffer {
    $t = Get-Theme
    Draw-Header "CAMBRIANSYSTEMS HEURISTIC AUTO-SNIFFER"
    Play-Sound "alert"
    
    Write-Host " Paste or read any mystery payload (JWT, Base64, Base64URL, Hex, URL-Encoded, GZip):" -ForegroundColor $t.Dim
    Write-Host "  [1] Paste from Clipboard" -ForegroundColor $t.Alert
    Write-Host "  [2] Manual String Input" -ForegroundColor $t.Fg
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Accent
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    $str = ""
    if ($c -eq "1") {
        try { $str = [System.Windows.Forms.Clipboard]::GetText() } catch {}
    } else {
        Write-Host "`n Mystery String: " -NoNewline -ForegroundColor $t.Accent
        $str = [Console]::ReadLine()
    }
    
    if ([string]::IsNullOrEmpty($str)) { return }
    $str = $str.Trim()
    
    Draw-Header "HEURISTIC ANALYSIS REPORT"
    Play-Sound "success"
    
    # 1. JWT Check
    if ($str -match '^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$') {
        Write-Host " [*] DETECTED: JSON Web Token (JWT) Format!" -ForegroundColor $t.Alert
        try {
            $jwt = Parse-JwtToken $str
            Write-Host " [Header]  : $($jwt.HeaderRaw)" -ForegroundColor $t.Fg
            Write-Host " [Payload] : $($jwt.PayloadRaw)" -ForegroundColor $t.Alert
        } catch {}
    }
    # 2. Data URI Check
    elseif ($str -match '^data:([^;]+);base64,(.+)$') {
        $mime = $matches[1]
        Write-Host " [*] DETECTED: HTML/CSS Base64 Data URI (MIME: $mime)" -ForegroundColor $t.Alert
        $clean = $matches[2]
        $bytes = [System.Convert]::FromBase64String($clean)
        Write-Host " [Decoded Size]: $($bytes.Length) bytes" -ForegroundColor $t.Fg
    }
    # 3. URL-Encoded Check
    elseif ($str -match '%[0-9A-Fa-f]{2}') {
        Write-Host " [*] DETECTED: URL Percent-Encoded String!" -ForegroundColor $t.Alert
        $unescaped = [System.Uri]::UnescapeDataString($str)
        Write-Host " [Decoded URL]: $unescaped" -ForegroundColor $t.Fg
    }
    # 4. Hex Check
    elseif ($str -match '^[0-9A-Fa-f\s]{8,}$' -and ($str -replace '\s','').Length % 2 -eq 0) {
        Write-Host " [*] DETECTED: Hexadecimal (Base16) Stream!" -ForegroundColor $t.Alert
        try {
            $bytes = ConvertFrom-HexString $str
            $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
            Write-Host " [Decoded Text]: $txt" -ForegroundColor $t.Fg
        } catch {
            Write-Host " [Raw Bytes]: $($bytes.Length) bytes" -ForegroundColor $t.Dim
        }
    }
    # 5. Standard or URL Base64
    else {
        $clean = Clean-Base64Input $str
        $isUrl = $clean.Contains('-') -or $clean.Contains('_')
        try {
            $bytes = if ($isUrl) { ConvertFrom-Base64Url $clean } else { [System.Convert]::FromBase64String($clean) }
            
            # Check if GZip inside
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0x1F -and $bytes[1] -eq 0x8B) {
                Write-Host " [*] DETECTED: GZip-Compressed $(if ($isUrl) {'Base64URL'} else {'Base64'}) Payload!" -ForegroundColor $t.Alert
                $unpacked = Decompress-GZipBytes $bytes
                $txt = [System.Text.Encoding]::UTF8.GetString($unpacked)
                Write-Host " [Decompressed Text]: $txt" -ForegroundColor $t.Fg
            } else {
                $info = Get-MediaInfoFromBytes $bytes
                if ($info.IsImage) {
                    Write-Host " [*] DETECTED: Encoded $(if ($isUrl) {'Base64URL'} else {'Base64'}) IMAGE ($($info.Format))!" -ForegroundColor $t.Alert
                    Render-AsciiThumbnail $bytes
                } else {
                    Write-Host " [*] DETECTED: Standard $(if ($isUrl) {'Base64URL'} else {'Base64'}) Stream!" -ForegroundColor $t.Alert
                    $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
                    Write-Host " [Decoded Plaintext]: $txt" -ForegroundColor $t.Fg
                }
            }
        } catch {
            Write-Host " [!] HEURISTIC ENGINE: Unrecognized format or corrupted bits." -ForegroundColor $t.Error
            Write-Host " Error: $($_.Exception.Message)" -ForegroundColor $t.Dim
        }
    }
    
    Write-Host "`n Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}

function Invoke-Base64UrlMenu {
    $t = Get-Theme
    Draw-Header "BASE64-URL TRANSCODER (RFC 4648 §5)"
    Write-Host " [1] Encode Text -> Base64URL" -ForegroundColor $t.Fg
    Write-Host " [2] Decode Base64URL -> Text" -ForegroundColor $t.Fg
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().Trim()
    
    if ($c -eq "1") {
        Write-Host "`n Enter plaintext: " -NoNewline -ForegroundColor $t.Accent
        $txt = [Console]::ReadLine()
        $b = [System.Text.Encoding]::UTF8.GetBytes($txt)
        $res = ConvertTo-Base64Url $b
        Play-Sound "success"
        Write-Host "`n Base64URL: $res" -ForegroundColor $t.Alert
        [System.Windows.Forms.Clipboard]::SetText($res)
        Write-Host " [OK] Copied to Clipboard." -ForegroundColor $t.Dim
        Start-Sleep -Seconds 2
    } elseif ($c -eq "2") {
        Write-Host "`n Enter Base64URL string (or press Enter to read Clipboard): " -NoNewline -ForegroundColor $t.Accent
        $b64u = [Console]::ReadLine().Trim()
        if (-not $b64u) { $b64u = [System.Windows.Forms.Clipboard]::GetText() }
        try {
            $bytes = ConvertFrom-Base64Url $b64u
            $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
            Play-Sound "success"
            Write-Host "`n Decoded Text: $txt" -ForegroundColor $t.Alert
            [System.Windows.Forms.Clipboard]::SetText($txt)
            Write-Host " [OK] Copied to Clipboard." -ForegroundColor $t.Dim
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "`n [!] Decode failed: $_" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Seconds 2
        }
    }
}

function Invoke-HexMenu {
    $t = Get-Theme
    Draw-Header "HEXADECIMAL / BASE16 TRANSCODER"
    Write-Host " [1] Encode Text -> Hexadecimal Stream" -ForegroundColor $t.Fg
    Write-Host " [2] Decode Hexadecimal Stream -> Text" -ForegroundColor $t.Fg
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().Trim()
    
    if ($c -eq "1") {
        Write-Host "`n Enter text: " -NoNewline -ForegroundColor $t.Accent
        $txt = [Console]::ReadLine()
        $b = [System.Text.Encoding]::UTF8.GetBytes($txt)
        $hex = ConvertTo-HexString $b
        Play-Sound "success"
        Write-Host "`n Hex Output: $hex" -ForegroundColor $t.Alert
        [System.Windows.Forms.Clipboard]::SetText($hex)
        Write-Host " [OK] Copied to Clipboard." -ForegroundColor $t.Dim
        Start-Sleep -Seconds 2
    } elseif ($c -eq "2") {
        Write-Host "`n Enter Hex string (or press Enter to read Clipboard): " -NoNewline -ForegroundColor $t.Accent
        $hex = [Console]::ReadLine().Trim()
        if (-not $hex) { $hex = [System.Windows.Forms.Clipboard]::GetText() }
        try {
            $bytes = ConvertFrom-HexString $hex
            $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
            Play-Sound "success"
            Write-Host "`n Decoded Text: $txt" -ForegroundColor $t.Alert
            [System.Windows.Forms.Clipboard]::SetText($txt)
            Write-Host " [OK] Copied to Clipboard." -ForegroundColor $t.Dim
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "`n [!] Hex decode error: $_" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Seconds 2
        }
    }
}

function Invoke-UrlEncodeMenu {
    $t = Get-Theme
    Draw-Header "URL / PERCENT-ENCODING TRANSCODER"
    Write-Host " [1] URL Encode String (e.g. spaces -> %20)" -ForegroundColor $t.Fg
    Write-Host " [2] URL Decode String" -ForegroundColor $t.Fg
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().Trim()
    
    if ($c -eq "1") {
        Write-Host "`n Enter string to URL-encode: " -NoNewline -ForegroundColor $t.Accent
        $txt = [Console]::ReadLine()
        $res = [System.Uri]::EscapeDataString($txt)
        Play-Sound "success"
        Write-Host "`n Encoded: $res" -ForegroundColor $t.Alert
        [System.Windows.Forms.Clipboard]::SetText($res)
        Start-Sleep -Seconds 2
    } elseif ($c -eq "2") {
        Write-Host "`n Enter URL-encoded string: " -NoNewline -ForegroundColor $t.Accent
        $txt = [Console]::ReadLine()
        if (-not $txt) { $txt = [System.Windows.Forms.Clipboard]::GetText() }
        $res = [System.Uri]::UnescapeDataString($txt)
        Play-Sound "success"
        Write-Host "`n Decoded: $res" -ForegroundColor $t.Alert
        [System.Windows.Forms.Clipboard]::SetText($res)
        Start-Sleep -Seconds 2
    }
}

# ==============================================================================
# OPERATION 5: GZIP-COMPRESSED BASE64 STREAMER
# ==============================================================================
function Invoke-GzipMenu {
    $t = Get-Theme
    Draw-Header "GZIP-COMPRESSED BASE64 STREAMER"
    Play-Sound "blip"
    
    Write-Host " High-Ratio Compressed Base64 (Standard in SAML, Kube, Cloud Configs):" -ForegroundColor $t.Dim
    Write-Host "  [1] COMPRESS Plaintext/File -> GZip -> Base64" -ForegroundColor $t.Fg
    Write-Host "  [2] DECOMPRESS Base64 -> GUnzip -> Plaintext/File" -ForegroundColor $t.Fg
    Write-Host "  [B] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    if ($c -eq "1") {
        Write-Host "`n Ingest Method: [1] Text Prompt  [2] Read Clipboard  [3] File on Disk" -ForegroundColor $t.Accent
        Write-Host " >> METHOD: " -NoNewline -ForegroundColor $t.Alert
        $m = [Console]::ReadLine().Trim()
        
        $rawBytes = @()
        if ($m -eq "1") {
            Write-Host "`n Enter text: " -NoNewline -ForegroundColor $t.Accent
            $txt = [Console]::ReadLine()
            $rawBytes = [System.Text.Encoding]::UTF8.GetBytes($txt)
        } elseif ($m -eq "2") {
            $txt = [System.Windows.Forms.Clipboard]::GetText()
            $rawBytes = [System.Text.Encoding]::UTF8.GetBytes($txt)
        } elseif ($m -eq "3") {
            $f = Show-FileDialog -title "SELECT FILE TO GZIP-ENCODE"
            if ($f -and (Test-Path $f)) { $rawBytes = [System.IO.File]::ReadAllBytes($f) }
        }
        if (-not $rawBytes -or $rawBytes.Length -eq 0) { return }
        
        $compressed = Compress-GZipBytes $rawBytes
        $b64 = [System.Convert]::ToBase64String($compressed)
        Play-Sound "success"
        
        Draw-Header "GZIP COMPRESSION TELEMETRY"
        $ratio = [Math]::Round((1 - ($compressed.Length / [Math]::Max(1, $rawBytes.Length))) * 100, 1)
        $meter = Draw-MeterBar $ratio 16 "$ratio% SAVED"
        $stats = @(
            "ORIGINAL SIZE       : $($rawBytes.Length) bytes",
            "GZIP BINARY SIZE    : $($compressed.Length) bytes",
            "BASE64 STRING LEN   : $($b64.Length) characters",
            "COMPRESSION SAVINGS : $meter"
        )
        Draw-Box $stats "COMPRESSION METRICS" "Fg"
        Write-Host ""
        Write-Host " GZip Base64: $b64" -ForegroundColor $t.Alert
        [System.Windows.Forms.Clipboard]::SetText($b64)
        Write-Host "`n [OK] Copied to Clipboard." -ForegroundColor $t.Dim
        Start-Sleep -Seconds 2
    } elseif ($c -eq "2") {
        Write-Host "`n Enter GZip Base64 string (or press Enter for Clipboard): " -NoNewline -ForegroundColor $t.Accent
        $b64 = [Console]::ReadLine().Trim()
        if (-not $b64) { $b64 = [System.Windows.Forms.Clipboard]::GetText() }
        $clean = Clean-Base64Input $b64
        
        try {
            $gzBytes = [System.Convert]::FromBase64String($clean)
            $decompressed = Decompress-GZipBytes $gzBytes
            Play-Sound "success"
            
            $info = Get-MediaInfoFromBytes $decompressed
            Draw-Header "GZIP DECOMPRESSION COMPLETE"
            Write-Host " [Unpacked Size]: $($decompressed.Length) bytes (Payload Type: $($info.Format))`n" -ForegroundColor $t.Accent
            
            if ($info.IsImage) {
                Render-AsciiThumbnail $decompressed
            } else {
                $txt = [System.Text.Encoding]::UTF8.GetString($decompressed)
                Write-Host " [Decoded Plaintext]:" -ForegroundColor $t.Accent
                Write-Host $txt -ForegroundColor $t.Alert
                [System.Windows.Forms.Clipboard]::SetText($txt)
                Write-Host "`n [OK] Plaintext copied to clipboard." -ForegroundColor $t.Dim
            }
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "`n [!] Decompression failed: $_" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Seconds 2
        }
    }
}

# ==============================================================================
# OPERATION 6: POWERSHELL -EncodedCommand GENERATOR & DECODER
# ==============================================================================
function Invoke-PowerShellEncodedMenu {
    $t = Get-Theme
    Draw-Header "POWERSHELL -EncodedCommand WORKSTATION"
    Play-Sound "blip"
    
    Write-Host " PowerShell expects UTF-16LE Base64 strings for powershell.exe -EncodedCommand:" -ForegroundColor $t.Dim
    Write-Host "  [1] ENCODE PowerShell Script/One-Liner -> -EncodedCommand Payload" -ForegroundColor $t.Fg
    Write-Host "  [2] DECODE -EncodedCommand Payload -> Readable PowerShell Code" -ForegroundColor $t.Fg
    Write-Host "  [B] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    if ($c -eq "1") {
        Write-Host "`n Enter PowerShell code/command: " -NoNewline -ForegroundColor $t.Accent
        $cmd = [Console]::ReadLine()
        if (-not $cmd) { return }
        
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
        $b64 = [System.Convert]::ToBase64String($bytes)
        $launchCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $b64"
        
        Play-Sound "success"
        Draw-Header "ENCODED COMMAND GENERATED"
        Write-Host " [BASE64 STRING]:" -ForegroundColor $t.Accent
        Write-Host $b64 -ForegroundColor $t.Alert
        Write-Host "`n [FULL CLI COMMAND LINE]:" -ForegroundColor $t.Accent
        Write-Host $launchCmd -ForegroundColor $t.Fg
        
        [System.Windows.Forms.Clipboard]::SetText($launchCmd)
        Write-Host "`n [OK] Full command line copied to Windows Clipboard." -ForegroundColor $t.Alert
        Start-Sleep -Seconds 2
    } elseif ($c -eq "2") {
        Write-Host "`n Enter EncodedCommand Base64 (or press Enter for Clipboard): " -NoNewline -ForegroundColor $t.Accent
        $b64 = [Console]::ReadLine().Trim()
        if (-not $b64) { $b64 = [System.Windows.Forms.Clipboard]::GetText() }
        
        # Strip powershell.exe -EncodedCommand if user pasted entire command
        if ($b64 -match '-(?:EncodedCommand|e|enc)\s+([A-Za-z0-9+/=]+)') {
            $b64 = $matches[1]
        }
        
        $clean = Clean-Base64Input $b64
        try {
            $bytes = [System.Convert]::FromBase64String($clean)
            $decodedCmd = [System.Text.Encoding]::Unicode.GetString($bytes)
            Play-Sound "success"
            
            $b = Get-BoxStyle
            Draw-Header "POWERSHELL CODE RECOVERED"
            Write-Host (" " + $b.TL + ($b.H * 2) + " [ DECODED SCRIPT OUTPUT ] " + ($b.H * 24)) -ForegroundColor $t.Accent
            Write-Host $decodedCmd -ForegroundColor $t.Alert
            Write-Host (" " + $b.BL + ($b.H * 68)) -ForegroundColor $t.Accent
            Write-Host ""
            
            [System.Windows.Forms.Clipboard]::SetText($decodedCmd)
            Write-Host "`n [OK] Recovered code copied to Clipboard." -ForegroundColor $t.Alert
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "`n [!] Decode error: $_" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Seconds 2
        }
    }
}

# ==============================================================================
# OPERATION 7: NORTON-STYLE HEX DUMP MEMORY INSPECTOR
# ==============================================================================
function Format-HexDumpLine {
    param(
        [byte[]]$bytes,
        [int]$offset,
        [int]$length
    )
    $hexPart1 = ""
    $hexPart2 = ""
    $asciiPart = ""
    
    for ($i = 0; $i -lt 16; $i++) {
        if ($i -lt $length) {
            $b = $bytes[$offset + $i]
            $hexStr = "{0:X2} " -f $b
            if ($i -lt 8) { $hexPart1 += $hexStr } else { $hexPart2 += $hexStr }
            
            if ($b -ge 32 -and $b -le 126) {
                $asciiPart += [char]$b
            } else {
                $asciiPart += "."
            }
        } else {
            if ($i -lt 8) { $hexPart1 += "   " } else { $hexPart2 += "   " }
            $asciiPart += " "
        }
    }
    
    $offStr = "{0:X8}: " -f $offset
    return "$offStr$hexPart1- $hexPart2 |$asciiPart|"
}

function Invoke-HexDumpViewer {
    $t = Get-Theme
    Draw-Header "NORTON-STYLE HEX DUMP MEMORY INSPECTOR"
    Play-Sound "blip"
    
    Write-Host " Select payload to examine in Hex/ASCII memory mode:" -ForegroundColor $t.Accent
    Write-Host "  [1] Examine File on Disk" -ForegroundColor $t.Alert
    Write-Host "  [2] Decode Base64 from Clipboard into Hex Dump" -ForegroundColor $t.Fg
    Write-Host "  [B] Return" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $c = [Console]::ReadLine().ToUpper().Trim()
    
    $rawBytes = @()
    if ($c -eq "1") {
        $f = Show-FileDialog -title "SELECT FILE FOR HEX DUMP"
        if ($f -and (Test-Path $f)) { $rawBytes = [System.IO.File]::ReadAllBytes($f) }
    } elseif ($c -eq "2") {
        $b64 = [System.Windows.Forms.Clipboard]::GetText()
        $clean = Clean-Base64Input $b64
        if ($clean) { $rawBytes = [System.Convert]::FromBase64String($clean) }
    } else { return }
    
    if (-not $rawBytes -or $rawBytes.Length -eq 0) { return }
    
    # Interactive Pager (16 lines = 256 bytes per page)
    $pageSize = 256
    $curOffset = 0
    $total = $rawBytes.Length
    
    while ($true) {
        $b = Get-BoxStyle
        Draw-Header "HEX DUMP (BYTES $curOffset - $([Math]::Min($total, $curOffset + $pageSize)) OF $total)"
        Write-Host " OFFSET    00 01 02 03 04 05 06 07   08 09 0A 0B 0C 0D 0E 0F  ASCII DUMP" -ForegroundColor $t.Accent
        Write-Host ($b.H * 74) -ForegroundColor $t.Dim
        
        $end = [Math]::Min($total, $curOffset + $pageSize)
        for ($pos = $curOffset; $pos -lt $end; $pos += 16) {
            $len = [Math]::Min(16, $total - $pos)
            $line = Format-HexDumpLine $rawBytes $pos $len
            Write-Host $line -ForegroundColor $t.Fg
        }
        Write-Host ($b.H * 74) -ForegroundColor $t.Dim
        
        Write-Host " [NAV]: [N]ext Page | [P]rev Page | [G]oto Offset | [Q]uit Inspector" -ForegroundColor $t.Alert
        Write-Host " >> COMMAND: " -NoNewline -ForegroundColor $t.Accent
        $cmd = [Console]::ReadLine().ToUpper().Trim()
        
        if ($cmd -eq "N") {
            if ($curOffset + $pageSize -lt $total) { $curOffset += $pageSize; Play-Sound "blip" }
        } elseif ($cmd -eq "P") {
            if ($curOffset -ge $pageSize) { $curOffset -= $pageSize; Play-Sound "blip" }
        } elseif ($cmd -eq "G") {
            Write-Host " Enter Hex offset (e.g. 100): " -NoNewline -ForegroundColor $t.Accent
            $targetHex = [Console]::ReadLine()
            try {
                $target = [Convert]::ToInt32($targetHex, 16)
                if ($target -ge 0 -and $target -lt $total) {
                    $curOffset = [int]($target - ($target % 16))
                }
            } catch {}
        } elseif ($cmd -eq "Q" -or [string]::IsNullOrEmpty($cmd)) {
            break
        }
    }
}

# ==============================================================================
# OPERATION 8: BATCH TRANSMUTATION & OFFLINE HTML GALLERY GENERATOR
# ==============================================================================
function Invoke-BatchTransmuter {
    $t = Get-Theme
    Draw-Header "BULK TRANSMUTATION & OFFLINE HTML GALLERY"
    Play-Sound "blip"
    
    Write-Host " Select source folder containing photos/files to batch process:" -ForegroundColor $t.Accent
    Write-Host " >> Press Enter to open Folder Browser... " -NoNewline -ForegroundColor $t.Alert
    [void][Console]::ReadLine()
    
    $folder = Show-FolderDialog "SELECT FOLDER OF IMAGES/FILES FOR BULK CONVERSION"
    if (-not $folder -or -not (Test-Path $folder)) { return }
    
    $files = Get-ChildItem -Path $folder -File | Where-Object { $_.Extension -match '\.(png|jpg|jpeg|gif|bmp|webp|ico|svg)$' }
    if ($files.Count -eq 0) {
        Write-Host "`n [!] No supported image files found in directory." -ForegroundColor $t.Error
        Start-Sleep -Seconds 2
        return
    }
    
    Draw-Header "BATCH PROCESSING ($($files.Count) FILES)"
    Write-Host " Converting images into Data URIs and building offline retro gallery..." -ForegroundColor $t.Dim
    
    $htmlItems = @()
    $totalRaw = 0
    $totalB64 = 0
    
    foreach ($file in $files) {
        Write-Host " Processing: $($file.Name) ..." -ForegroundColor $t.Accent
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $totalRaw += $bytes.Length
        $mediaInfo = Get-MediaInfoFromBytes $bytes
        $b64 = [System.Convert]::ToBase64String($bytes)
        $totalB64 += $b64.Length
        $dataUri = "data:$($mediaInfo.Mime);base64,$b64"
        
        $dim = "N/A"
        try {
            $ms = New-Object System.IO.MemoryStream(,$bytes)
            $img = [System.Drawing.Image]::FromStream($ms)
            $dim = "$($img.Width)x$($img.Height)"
            $img.Dispose()
            $ms.Dispose()
        } catch {}
        
        $htmlItems += @"
        <div class="card">
            <div class="card-header">$($file.Name) ($dim - $([Math]::Round($bytes.Length/1024, 1)) KB)</div>
            <div class="img-wrap"><img src="$dataUri" alt="$($file.Name)" /></div>
            <div class="card-footer">
                <button onclick="navigator.clipboard.writeText('$dataUri')">Copy Data-URI</button>
                <button onclick="navigator.clipboard.writeText('$b64')">Copy Base64</button>
            </div>
        </div>
"@
    }
    
    # Generate Self-Contained Offline CambrianSystems HTML Gallery
    $outHtml = [System.IO.Path]::Combine($folder, "cambriansystems_offline_gallery.html")
    $allCards = $htmlItems -join "`n"
    
    $galleryHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CAMBRIANSYSTEMS // OFFLINE DATA-URI PHOTO VAULT</title>
<style>
    body { background: #050b14; color: #00ffcc; font-family: 'Consolas', 'Courier New', monospace; margin: 0; padding: 20px; }
    h1 { color: #ffff33; text-shadow: 0 0 8px #ffff33; border-bottom: 2px solid #00ffcc; padding-bottom: 8px; font-size: 20px; }
    .meta { color: #88a0b0; font-size: 13px; margin-bottom: 20px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
    .card { background: #0b1526; border: 1px solid #00aaff; border-radius: 4px; overflow: hidden; display: flex; flex-direction: column; }
    .card-header { background: #003366; color: #ffff33; padding: 8px 12px; font-size: 12px; font-weight: bold; border-bottom: 1px solid #00aaff; }
    .img-wrap { padding: 10px; display: flex; align-items: center; justify-content: center; height: 180px; background: #000; }
    img { max-width: 100%; max-height: 100%; object-fit: contain; }
    .card-footer { padding: 8px; background: #07101d; border-top: 1px solid #003366; display: flex; gap: 8px; }
    button { background: #002244; color: #00ffcc; border: 1px solid #00ffcc; padding: 4px 8px; font-family: inherit; font-size: 11px; cursor: pointer; border-radius: 2px; }
    button:hover { background: #00ffcc; color: #000; }
</style>
</head>
<body>
<h1>CAMBRIANSYSTEMS // OFFLINE DATA-URI PHOTO VAULT</h1>
<div class="meta">BATCH RECONSTRUCTION // RFC-4648 COMPLIANT // TOTAL FILES: $($files.Count) // RAW SIZE: $([Math]::Round($totalRaw/1024, 1)) KB</div>
<div class="grid">
$allCards
</div>
</body>
</html>
"@
    
    [System.IO.File]::WriteAllText($outHtml, $galleryHtml, [System.Text.Encoding]::UTF8)
    Play-Sound "success"
    
    Write-Host "`n [OK] BATCH COMPLETE!" -ForegroundColor $t.Alert
    Write-Host " Offline Gallery saved to: $outHtml" -ForegroundColor $t.Accent
    Write-Host " [O] Open Gallery in Web Browser immediately | [ENTER] Return" -ForegroundColor $t.Fg
    $o = [Console]::ReadLine().ToUpper().Trim()
    if ($o -eq "O") { Invoke-Item $outHtml }
}

# ==============================================================================
# OPERATION 9: INTEGRITY INSPECTOR
# ==============================================================================
function Invoke-Inspector {
    $t = Get-Theme
    Draw-Header "BASE64 VALIDATOR & INTEGRITY INSPECTOR"
    Play-Sound "blip"
    
    Write-Host " Ingest Base64 to inspect:" -ForegroundColor $t.Accent
    Write-Host "  [1] Inspect Windows Clipboard Contents" -ForegroundColor $t.Alert
    Write-Host "  [2] Inspect File (.b64 / .txt)" -ForegroundColor $t.Fg
    Write-Host "  [3] Manually Type / Paste String" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Main Menu" -ForegroundColor $t.Dim
    Write-Host ""
    Write-Host " >> CHOICE: " -NoNewline -ForegroundColor $t.Alert
    $choice = [Console]::ReadLine().ToUpper().Trim()
    
    $rawB64 = ""
    if ($choice -eq "1") {
        try { $rawB64 = [System.Windows.Forms.Clipboard]::GetText() } catch {}
    } elseif ($choice -eq "2") {
        $f = Show-FileDialog -title "INSPECT BASE64 FILE"
        if ($f -and (Test-Path $f)) { $rawB64 = [System.IO.File]::ReadAllText($f) }
    } elseif ($choice -eq "3") {
        Write-Host "`n Paste Base64: " -NoNewline -ForegroundColor $t.Accent
        $rawB64 = [Console]::ReadLine()
    } else { return }
    
    if (-not $rawB64) { return }
    
    $clean = Clean-Base64Input $rawB64
    $isValid = $true
    $errorReason = "NONE (PAYLOAD VALID)"
    $bytes = @()
    
    try {
        $bytes = [System.Convert]::FromBase64String($clean)
    } catch {
        $isValid = $false
        $errorReason = $_.Exception.Message
    }
    
    $sha256 = "N/A"
    $mediaInfo = @{ Format = "N/A"; Mime = "N/A" }
    if ($isValid) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash($bytes)
        $sha256 = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
        $mediaInfo = Get-MediaInfoFromBytes $bytes
        Play-Sound "success"
    } else {
        Play-Sound "error"
    }
    
    Draw-Header "DIAGNOSTIC TELEMETRY REPORT"
    $report = @(
        "RFC 4648 COMPLIANCE   : $(if ($isValid) { '[✓ PASSED] VALID BASE64 STREAM' } else { '[✗ FAILED] CORRUPTED OR INVALID' })",
        "ERROR DIAGNOSTIC      : $errorReason",
        "STRING LENGTH (RAW)   : $($rawB64.Length) characters",
        "CLEANED STRING LENGTH : $($clean.Length) characters",
        "DECODED BYTE COUNT    : $(if ($isValid) { "$($bytes.Length) bytes" } else { 'N/A' })",
        "MODULO 4 CHECK        : $(if ($clean.Length % 4 -eq 0) { '[✓ PASSED] (Remainder: 0)' } else { '[✗ FAILED] (Remainder: ' + ($clean.Length % 4) + ')' })",
        "IDENTIFIED DATA TYPE  : $($mediaInfo.Format) ($($mediaInfo.Mime))",
        "SHA-256 CHECKSUM      : $sha256"
    )
    Draw-Box $report "INTEGRITY REPORT" $(if ($isValid) { "Fg" } else { "Error" })
    Write-Host ""
    
    if ($isValid -and $mediaInfo.IsImage) {
        Render-AsciiThumbnail $bytes
        Write-Host ""
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}
# ==============================================================================
# HELPER FUNCTIONS: MEDIA TRANSCODING, PDF, MARKDOWN & CRYPTO
# ==============================================================================

function ConvertTo-IcoBytes {
    param(
        [byte[]]$pngOrImgBytes,
        [int]$width = 32,
        [int]$height = 32
    )
    $ms = New-Object System.IO.MemoryStream(,$pngOrImgBytes)
    $orig = [System.Drawing.Image]::FromStream($ms)
    $resized = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($resized)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($orig, 0, 0, $width, $height)
    
    $pngMs = New-Object System.IO.MemoryStream
    $resized.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
    $scaledPngBytes = $pngMs.ToArray()
    
    $orig.Dispose(); $resized.Dispose(); $g.Dispose(); $ms.Dispose(); $pngMs.Dispose()
    
    $icoMs = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter $icoMs
    
    # ICO Header (6 bytes)
    $bw.Write([uint16]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]1)
    
    # Directory entry (16 bytes)
    $wByte = if ($width -ge 256) { [byte]0 } else { [byte]$width }
    $hByte = if ($height -ge 256) { [byte]0 } else { [byte]$height }
    $bw.Write($wByte)
    $bw.Write($hByte)
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]$scaledPngBytes.Length)
    $bw.Write([uint32]22)
    
    $bw.Write($scaledPngBytes)
    $bw.Flush()
    
    $icoBytes = $icoMs.ToArray()
    $bw.Dispose(); $icoMs.Dispose()
    return $icoBytes
}

function Convert-ImageBytes {
    param(
        [byte[]]$inputBytes,
        [string]$targetFormat,
        [int]$targetWidth = 0,
        [int]$targetHeight = 0,
        [int]$jpegQuality = 85
    )
    $fmt = $targetFormat.ToUpper().Trim().Replace(".", "")
    if ($fmt -eq "ICO") {
        $w = if ($targetWidth -gt 0) { $targetWidth } else { 32 }
        $h = if ($targetHeight -gt 0) { $targetHeight } else { 32 }
        return ConvertTo-IcoBytes -pngOrImgBytes $inputBytes -width $w -height $h
    }
    
    $inMs = New-Object System.IO.MemoryStream(,$inputBytes)
    $orig = [System.Drawing.Image]::FromStream($inMs)
    
    $w = if ($targetWidth -gt 0) { $targetWidth } else { $orig.Width }
    $h = if ($targetHeight -gt 0) { $targetHeight } else { $orig.Height }
    
    $workImg = $orig
    $scaledBmp = $null
    if ($w -ne $orig.Width -or $h -ne $orig.Height) {
        $scaledBmp = New-Object System.Drawing.Bitmap $w, $h
        $g = [System.Drawing.Graphics]::FromImage($scaledBmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($orig, 0, 0, $w, $h)
        $g.Dispose()
        $workImg = $scaledBmp
    }
    
    $outMs = New-Object System.IO.MemoryStream
    
    if ($fmt -in @("JPG", "JPEG")) {
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters 1
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]$jpegQuality)
        $workImg.Save($outMs, $jpegCodec, $encoderParams)
    } else {
        $sysFmt = switch ($fmt) {
            "PNG"  { [System.Drawing.Imaging.ImageFormat]::Png }
            "BMP"  { [System.Drawing.Imaging.ImageFormat]::Bmp }
            "GIF"  { [System.Drawing.Imaging.ImageFormat]::Gif }
            "TIFF" { [System.Drawing.Imaging.ImageFormat]::Tiff }
            default { [System.Drawing.Imaging.ImageFormat]::Png }
        }
        $workImg.Save($outMs, $sysFmt)
    }
    
    $resultBytes = $outMs.ToArray()
    $orig.Dispose(); $inMs.Dispose(); $outMs.Dispose()
    if ($null -ne $scaledBmp) { $scaledBmp.Dispose() }
    
    return $resultBytes
}

function Parse-PdfTelemetry {
    param([byte[]]$pdfBytes)
    
    $info = @{
        Valid = $false
        Version = "Unknown"
        PageCount = 0
        Title = "N/A"
        Author = "N/A"
        Producer = "N/A"
        SizeBytes = $pdfBytes.Length
    }
    
    if ($pdfBytes.Length -lt 8) { return $info }
    
    if ($pdfBytes[0] -eq 0x25 -and $pdfBytes[1] -eq 0x50 -and $pdfBytes[2] -eq 0x44 -and $pdfBytes[3] -eq 0x46) {
        $info.Valid = $true
    } else {
        return $info
    }
    
    $headerStr = [System.Text.Encoding]::ASCII.GetString($pdfBytes, 0, [Math]::Min(32, $pdfBytes.Length))
    if ($headerStr -match '%PDF-(\d+\.\d+)') {
        $info.Version = $matches[1]
    }
    
    $textSample = [System.Text.Encoding]::ASCII.GetString($pdfBytes)
    if ($textSample -match '/Type\s*/Pages.*?/Count\s+(\d+)') {
        $info.PageCount = [int]$matches[1]
    } else {
        $m = [regex]::Matches($textSample, '/Type\s*/Page(?![sS])')
        $info.PageCount = $m.Count
    }
    
    if ($textSample -match '/Title\s*\((?<t>[^)]+)\)') { $info.Title = $matches['t'] }
    if ($textSample -match '/Author\s*\((?<a>[^)]+)\)') { $info.Author = $matches['a'] }
    if ($textSample -match '/Producer\s*\((?<p>[^)]+)\)') { $info.Producer = $matches['p'] }
    
    return $info
}

function Pack-MarkdownDocument {
    param(
        [string]$mdFilePath,
        [string]$outputPath = ""
    )
    if (-not (Test-Path $mdFilePath)) { throw "Markdown file not found: $mdFilePath" }
    
    $mdDir = Split-Path (Resolve-Path $mdFilePath) -Parent
    $content = [System.IO.File]::ReadAllText($mdFilePath, [System.Text.Encoding]::UTF8)
    
    $inlinedList = New-Object System.Collections.ArrayList
    $pattern = '!\[(?<alt>[^\]]*)\]\((?<path>(?!https?:\/\/|data:)[^)]+)\)'
    $packedContent = [regex]::Replace($content, $pattern, {
        param($m)
        $alt = $m.Groups['alt'].Value
        $relPath = $m.Groups['path'].Value.Trim()
        $imgPath = Join-Path $mdDir $relPath
        if (Test-Path $imgPath) {
            $bytes = [System.IO.File]::ReadAllBytes($imgPath)
            $ext = [System.IO.Path]::GetExtension($imgPath).ToLower()
            $mime = switch ($ext) {
                ".png" { "image/png" }
                ".jpg" { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".gif" { "image/gif" }
                ".svg" { "image/svg+xml" }
                ".webp" { "image/webp" }
                ".ico" { "image/x-icon" }
                ".bmp" { "image/bmp" }
                default { "application/octet-stream" }
            }
            $b64 = [System.Convert]::ToBase64String($bytes)
            [void]$inlinedList.Add($relPath)
            return "![$alt](data:$mime;base64,$b64)"
        } else {
            return $m.Value
        }
    })
    
    $target = if ($outputPath) { $outputPath } else {
        [System.IO.Path]::Combine($mdDir, [System.IO.Path]::GetFileNameWithoutExtension($mdFilePath) + ".standalone.md")
    }
    [System.IO.File]::WriteAllText($target, $packedContent, [System.Text.Encoding]::UTF8)
    return @{
        TargetFile = $target
        ImagesInlined = $inlinedList.Count
        InlinedFiles = $inlinedList
    }
}

function Unpack-MarkdownDocument {
    param(
        [string]$mdFilePath,
        [string]$outputDir = ""
    )
    if (-not (Test-Path $mdFilePath)) { throw "Markdown file not found: $mdFilePath" }
    
    $mdDir = Split-Path (Resolve-Path $mdFilePath) -Parent
    $content = [System.IO.File]::ReadAllText($mdFilePath, [System.Text.Encoding]::UTF8)
    
    $assetDir = if ($outputDir) { $outputDir } else { Join-Path $mdDir "assets" }
    if (-not (Test-Path $assetDir)) { [void](New-Item -ItemType Directory -Path $assetDir -Force) }
    
    $extractedList = New-Object System.Collections.ArrayList
    $pattern = '!\[(?<alt>[^\]]*)\]\(data:image\/(?<type>[a-zA-Z0-9\+\-]+);base64,(?<data>[A-Za-z0-9+/=]+)\)'
    
    $unpackedContent = [regex]::Replace($content, $pattern, {
        param($m)
        $alt = $m.Groups['alt'].Value
        $type = $m.Groups['type'].Value.ToLower().Replace("svg+xml", "svg").Replace("jpeg", "jpg")
        $b64 = $m.Groups['data'].Value
        
        $idx = $extractedList.Count + 1
        $filename = "img_asset_{0:d3}.$type" -f $idx
        $diskPath = Join-Path $assetDir $filename
        $rawBytes = [System.Convert]::FromBase64String($b64)
        [System.IO.File]::WriteAllBytes($diskPath, $rawBytes)
        [void]$extractedList.Add($filename)
        
        $relPath = "./assets/$filename"
        return "![$alt]($relPath)"
    })
    
    $target = [System.IO.Path]::Combine($mdDir, [System.IO.Path]::GetFileNameWithoutExtension($mdFilePath) + ".unpacked.md")
    [System.IO.File]::WriteAllText($target, $unpackedContent, [System.Text.Encoding]::UTF8)
    return @{
        TargetFile = $target
        ImagesExtracted = $extractedList.Count
        ExtractedFiles = $extractedList
        AssetDir = $assetDir
    }
}

function Inject-StegoCarrier {
    param(
        [string]$carrierFilePath,
        [byte[]]$payloadBytes,
        [string]$outputCarrierPath
    )
    if (-not (Test-Path $carrierFilePath)) { throw "Carrier file not found: $carrierFilePath" }
    $carrierBytes = [System.IO.File]::ReadAllBytes($carrierFilePath)
    $b64Payload = [System.Convert]::ToBase64String($payloadBytes)
    $marker = [System.Environment]::NewLine + "<!--CAMBRIAN_STEGO_BEGIN-->" + $b64Payload + "<!--CAMBRIAN_STEGO_END-->" + [System.Environment]::NewLine
    $markerBytes = [System.Text.Encoding]::UTF8.GetBytes($marker)
    
    $combined = New-Object byte[] ($carrierBytes.Length + $markerBytes.Length)
    [Array]::Copy($carrierBytes, 0, $combined, 0, $carrierBytes.Length)
    [Array]::Copy($markerBytes, 0, $combined, $carrierBytes.Length, $markerBytes.Length)
    [System.IO.File]::WriteAllBytes($outputCarrierPath, $combined)
    return @{
        CarrierSize = $carrierBytes.Length
        PayloadSize = $payloadBytes.Length
        TotalSize = $combined.Length
        OutputFile = $outputCarrierPath
    }
}

function Extract-StegoCarrier {
    param([string]$carrierFilePath)
    if (-not (Test-Path $carrierFilePath)) { throw "Carrier file not found: $carrierFilePath" }
    $carrierBytes = [System.IO.File]::ReadAllBytes($carrierFilePath)
    $rawStr = [System.Text.Encoding]::UTF8.GetString($carrierBytes)
    
    if ($rawStr -match '<!--CAMBRIAN_STEGO_BEGIN-->(?<payload>[A-Za-z0-9+/=]+)<!--CAMBRIAN_STEGO_END-->') {
        $b64 = $matches['payload']
        $decoded = [System.Convert]::FromBase64String($b64)
        $mediaInfo = Get-MediaInfoFromBytes $decoded
        return @{
            Found = $true
            Base64 = $b64
            Bytes = $decoded
            MediaInfo = $mediaInfo
        }
    } else {
        return @{ Found = $false }
    }
}

function Get-MultiHashTelemetry {
    param([byte[]]$bytes)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $sha384 = [System.Security.Cryptography.SHA384]::Create()
    $sha512 = [System.Security.Cryptography.SHA512]::Create()
    return @{
        Length = $bytes.Length
        MD5 = (-join ($md5.ComputeHash($bytes) | ForEach-Object { "{0:x2}" -f $_ }))
        SHA1 = (-join ($sha1.ComputeHash($bytes) | ForEach-Object { "{0:x2}" -f $_ }))
        SHA256 = (-join ($sha256.ComputeHash($bytes) | ForEach-Object { "{0:x2}" -f $_ }))
        SHA384 = (-join ($sha384.ComputeHash($bytes) | ForEach-Object { "{0:x2}" -f $_ }))
        SHA512 = (-join ($sha512.ComputeHash($bytes) | ForEach-Object { "{0:x2}" -f $_ }))
    }
}

# OPERATION 11: IMAGE FORMAT TRANSCODER & RESIZER
function Invoke-ImageConverter {
    Draw-Header "IMAGE FORMAT TRANSCODER & RESIZER"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [INGESTION SOURCE SELECTION]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Load Image File from Disk (PNG, JPG, BMP, GIF, ICO, TIFF)" -ForegroundColor $t.Fg
    Write-Host "  [2] Paste Base64 Stream or Data URI" -ForegroundColor $t.Fg
    Write-Host "  [3] Ingest Image from System Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $srcOpt = Read-MenuSelectionOrClick " >> SELECT SOURCE [1-3, B]: "
    if ($srcOpt -eq "B" -or [string]::IsNullOrEmpty($srcOpt)) { return }
    
    $rawBytes = $null
    $sourceDesc = ""
    
    if ($srcOpt -eq "1") {
        Write-Host " >> ENTER FULL IMAGE PATH: " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ FILE NOT FOUND]: $p" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        $rawBytes = [System.IO.File]::ReadAllBytes($p)
        $sourceDesc = (Split-Path $p -Leaf)
    } elseif ($srcOpt -eq "2") {
        Write-Host " >> PASTE BASE64 STREAM: " -NoNewline -ForegroundColor $t.Alert
        $pB64 = [Console]::ReadLine()
        $clean = Clean-Base64Input $pB64
        try {
            $rawBytes = [System.Convert]::FromBase64String($clean)
            $sourceDesc = "Pasted Base64 Stream"
        } catch {
            Write-Host " [✗ INVALID BASE64 PAYLOAD]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
    } elseif ($srcOpt -eq "3") {
        try {
            if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                $cImg = [System.Windows.Forms.Clipboard]::GetImage()
                $cMs = New-Object System.IO.MemoryStream
                $cImg.Save($cMs, [System.Drawing.Imaging.ImageFormat]::Png)
                $rawBytes = $cMs.ToArray()
                $cImg.Dispose(); $cMs.Dispose()
                $sourceDesc = "Clipboard Image"
            } else {
                Write-Host " [✗ NO IMAGE FOUND IN CLIPBOARD]" -ForegroundColor $t.Error
                Play-Sound "error"
                Start-Sleep -Milliseconds 800
                return
            }
        } catch {
            Write-Host " [✗ CLIPBOARD ACCESS ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
    }
    
    if ($null -eq $rawBytes -or $rawBytes.Length -eq 0) { return }
    
    $inInfo = Get-MediaInfoFromBytes $rawBytes
    $inMs = New-Object System.IO.MemoryStream(,$rawBytes)
    $origImg = $null
    try {
        $origImg = [System.Drawing.Image]::FromStream($inMs)
    } catch {
        Write-Host " [✗ UNABLE TO DECODE IMAGE STREAM]" -ForegroundColor $t.Error
        Play-Sound "error"
        $inMs.Dispose()
        Start-Sleep -Milliseconds 900
        return
    }
    
    $origW = $origImg.Width
    $origH = $origImg.Height
    $origImg.Dispose(); $inMs.Dispose()
    
    Draw-Header "IMAGE TRANSCODING METRICS"
    $srcSizeKb = [Math]::Round($rawBytes.Length / 1024, 2)
    $metaLines = @(
        "SOURCE STREAM   : $sourceDesc",
        "CURRENT FORMAT  : $($inInfo.Format) ($($inInfo.Mime))",
        "RESOLUTION      : ${origW} x ${origH} Pixels",
        "BYTE PAYLOAD    : $($rawBytes.Length) bytes ($srcSizeKb KB)"
    )
    Draw-Box $metaLines "SOURCE MEDIA TELEMETRY" "Accent"
    Write-Host ""
    
    Render-AsciiThumbnail $rawBytes 36 10
    Write-Host ""
    
    Write-Host " [TARGET CONVERSION FORMAT]:" -ForegroundColor $t.Accent
    Write-Host "  [1] PNG   · Lossless Portable Network Graphics" -ForegroundColor $t.Fg
    Write-Host "  [2] JPG   · High-Efficiency JPEG Photographic Compression" -ForegroundColor $t.Fg
    Write-Host "  [3] ICO   · Windows Application & Web Favicon Container" -ForegroundColor $t.Fg
    Write-Host "  [4] BMP   · Raw Device-Independent Bitmap" -ForegroundColor $t.Fg
    Write-Host "  [5] GIF   · Indexed Palette Graphics" -ForegroundColor $t.Fg
    Write-Host "  [6] TIFF  · Tagged Image File Format" -ForegroundColor $t.Fg
    Write-Host "  [B] Abort Conversion" -ForegroundColor $t.Dim
    Write-Host ""
    
    $fmtChoice = Read-MenuSelectionOrClick " >> SELECT TARGET FORMAT [1-6, B]: "
    if ($fmtChoice -eq "B" -or [string]::IsNullOrEmpty($fmtChoice)) { return }
    
    $targetFmt = switch ($fmtChoice) {
        "1" { "PNG" }
        "2" { "JPG" }
        "3" { "ICO" }
        "4" { "BMP" }
        "5" { "GIF" }
        "6" { "TIFF" }
        default { "PNG" }
    }
    
    $tW = 0; $tH = 0
    if ($targetFmt -eq "ICO") {
        Write-Host " >> SELECT ICO DIMENSION [1=16x16, 2=32x32, 3=48x48, 4=64x64, 5=128x128, 6=256x256, ENTER=32x32]: " -NoNewline -ForegroundColor $t.Alert
        $icoDim = [Console]::ReadLine().Trim()
        $tW = switch ($icoDim) {
            "1" { 16 }; "2" { 32 }; "3" { 48 }; "4" { 64 }; "5" { 128 }; "6" { 256 }; default { 32 }
        }
        $tH = $tW
    } else {
        Write-Host " >> RESIZE IMAGE WIDTH (PX, or press [ENTER] to retain $origW px): " -NoNewline -ForegroundColor $t.Alert
        $wIn = [Console]::ReadLine().Trim()
        if ($wIn -match '^\d+$') {
            $tW = [int]$wIn
            $autoH = [int][Math]::Round(($tW / $origW) * $origH)
            Write-Host " >> RESIZE IMAGE HEIGHT (PX, or press [ENTER] for aspect-ratio $autoH px): " -NoNewline -ForegroundColor $t.Alert
            $hIn = [Console]::ReadLine().Trim()
            $tH = if ($hIn -match '^\d+$') { [int]$hIn } else { $autoH }
        }
    }
    
    $jpegQual = 85
    if ($targetFmt -eq "JPG") {
        Write-Host " >> JPEG COMPRESSION QUALITY [1-100, default 85]: " -NoNewline -ForegroundColor $t.Alert
        $qIn = [Console]::ReadLine().Trim()
        if ($qIn -match '^\d+$') {
            $jpegQual = [Math]::Max(1, [Math]::Min(100, [int]$qIn))
        }
    }
    
    Play-Sound "blip"
    Write-Host " [*] EXECUTING HIGH-PRECISION TRANSMUTATION..." -ForegroundColor $t.Alert
    
    $convertedBytes = Convert-ImageBytes -inputBytes $rawBytes -targetFormat $targetFmt -targetWidth $tW -targetHeight $tH -jpegQuality $jpegQual
    $outInfo = Get-MediaInfoFromBytes $convertedBytes
    
    $ratio = [Math]::Round(($convertedBytes.Length / $rawBytes.Length) * 100, 1)
    $deltaMeter = Draw-MeterBar $ratio 18 "SIZE RATIO"
    
    Draw-Header "TRANSMUTATION RESULT TELEMETRY"
    $resW = if ($tW -gt 0) { $tW } else { $origW }
    $resH = if ($tH -gt 0) { $tH } else { $origH }
    $outKb = [Math]::Round($convertedBytes.Length / 1024, 2)
    
    $resLines = @(
        "CONVERTED FORMAT : $($outInfo.Format) ($targetFmt)",
        "OUTPUT EXTENSION : $($outInfo.Extension)",
        "TARGET RESOLUTION: ${resW} x ${resH} Pixels",
        "SOURCE SIZE      : $($rawBytes.Length) bytes ($srcSizeKb KB)",
        "TRANSMUTED SIZE  : $($convertedBytes.Length) bytes ($outKb KB)",
        "SIZE DELTA RATIO : $deltaMeter"
    )
    Draw-Box $resLines "OUTPUT TRANSMUTATION METRICS" "Fg"
    Write-Host ""
    Play-Sound "success"
    
    Write-Host " [EXPORT OPTIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Save Converted Media to Disk File" -ForegroundColor $t.Fg
    Write-Host "  [2] Copy Base64 String to Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [3] Copy HTML Data URI Tag to Clipboard" -ForegroundColor $t.Fg
    Write-Host "  [B] Done (Return to Operational Deck)" -ForegroundColor $t.Dim
    Write-Host ""
    
    $expOpt = Read-MenuSelectionOrClick " >> SELECT EXPORT OPTION [1-3, B]: "
    if ($expOpt -eq "1") {
        $stamp = [DateTime]::UtcNow.ToString("yyyyMMdd_HHmmss")
        $defName = "transmuted_" + $stamp + $outInfo.Extension
        Write-Host " >> ENTER OUTPUT PATH [Default: $defName]: " -NoNewline -ForegroundColor $t.Alert
        $saveP = [Console]::ReadLine().Trim()
        if (-not $saveP) { $saveP = $defName }
        [System.IO.File]::WriteAllBytes($saveP, $convertedBytes)
        Write-Host " [✓ FILE STORED]: $saveP ($($convertedBytes.Length) bytes)" -ForegroundColor $t.Fg
        Play-Sound "success"
        Start-Sleep -Milliseconds 800
    } elseif ($expOpt -eq "2") {
        $b64Out = [System.Convert]::ToBase64String($convertedBytes)
        try {
            [System.Windows.Forms.Clipboard]::SetText($b64Out)
            Write-Host " [✓ BASE64 COPIED TO SYSTEM CLIPBOARD]" -ForegroundColor $t.Fg
            Play-Sound "success"
        } catch {
            Write-Host " [✗ CLIPBOARD ERROR]" -ForegroundColor $t.Error
        }
        Start-Sleep -Milliseconds 800
    } elseif ($expOpt -eq "3") {
        $dataUri = "data:" + $outInfo.Mime + ";base64," + [System.Convert]::ToBase64String($convertedBytes)
        $htmlTag = '<img src="' + $dataUri + '" alt="Transmuted Media" />'
        try {
            [System.Windows.Forms.Clipboard]::SetText($htmlTag)
            Write-Host " [✓ HTML DATA-URI TAG COPIED TO CLIPBOARD]" -ForegroundColor $t.Fg
            Play-Sound "success"
        } catch {
            Write-Host " [✗ CLIPBOARD ERROR]" -ForegroundColor $t.Error
        }
        Start-Sleep -Milliseconds 800
    }
}

# OPERATION 12: PDF TRANSMUTATION HUB
function Invoke-PdfTransmuter {
    Draw-Header "PDF TRANSMUTATION HUB & VIEWER"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [OPERATION SUBSYSTEM]:" -ForegroundColor $t.Accent
    Write-Host "  [1] PDF -> Base64 Data URI & Standalone HTML Cyber Reader" -ForegroundColor $t.Fg
    Write-Host "  [2] Reconstitute Base64 Stream to PDF Document on Disk" -ForegroundColor $t.Fg
    Write-Host "  [3] PDF Binary Structural Telemetry & Page Inspector" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $opt = Read-MenuSelectionOrClick " >> SELECT OPERATION [1-3, B]: "
    if ($opt -eq "B" -or [string]::IsNullOrEmpty($opt)) { return }
    
    if ($opt -eq "1") {
        Write-Host " >> ENTER FULL PDF FILE PATH: " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine().Trim()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ PDF FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        
        $pdfBytes = [System.IO.File]::ReadAllBytes($p)
        $telemetry = Parse-PdfTelemetry $pdfBytes
        $b64 = [System.Convert]::ToBase64String($pdfBytes)
        $dataUri = "data:application/pdf;base64," + $b64
        $pdfKb = [Math]::Round($pdfBytes.Length / 1024, 2)
        
        Draw-Header "PDF TRANSMUTATION TELEMETRY"
        $lines = @(
            "PDF HEADER / VER  : %PDF-$($telemetry.Version)",
            "ESTIMATED PAGES   : $($telemetry.PageCount)",
            "DOCUMENT TITLE    : $($telemetry.Title)",
            "AUTHOR / PRODUCER : $($telemetry.Author) / $($telemetry.Producer)",
            "ORIGINAL SIZE     : $($pdfBytes.Length) bytes ($pdfKb KB)",
            "BASE64 STREAM LEN : $($b64.Length) characters"
        )
        Draw-Box $lines "PDF METRIC REPORT" "Fg"
        Write-Host ""
        
        try {
            [System.Windows.Forms.Clipboard]::SetText($dataUri)
            Write-Host " [✓ PDF DATA-URI COPIED TO SYSTEM CLIPBOARD]" -ForegroundColor $t.Fg
            Play-Sound "success"
        } catch {}
        
        Write-Host " >> GENERATE STANDALONE OFFLINE HTML CYBER READER? [Y/N, default Y]: " -NoNewline -ForegroundColor $t.Alert
        $genHtml = [Console]::ReadLine().Trim().ToUpper()
        if ($genHtml -ne "N") {
            $pdfFileName = [System.IO.Path]::GetFileName($p)
            $pdfBaseName = [System.IO.Path]::GetFileNameWithoutExtension($p)
            $htmlFile = [System.IO.Path]::Combine((Split-Path $p -Parent), $pdfBaseName + "_reader.html")
            
            $htmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CAMBRIANSYSTEMS // PDF READER: __FILENAME__</title>
    <style>
        body { margin: 0; background-color: #0b0f19; color: #00ff66; font-family: 'Consolas', monospace; display: flex; flex-direction: column; height: 100vh; }
        header { background: #001100; border-bottom: 2px solid #00ff66; padding: 10px 20px; display: flex; justify-content: space-between; align-items: center; }
        h1 { margin: 0; font-size: 16px; letter-spacing: 1px; }
        .meta { font-size: 12px; color: #88ff88; }
        iframe { flex: 1; border: none; width: 100%; height: calc(100vh - 50px); background: #222; }
    </style>
</head>
<body>
    <header>
        <div>
            <h1>CAMBRIANSYSTEMS CORP. // SECURE PDF WORKSTATION</h1>
            <div class="meta">FILE: __FILENAME__ | PAGES: __PAGES__ | SIZE: __SIZE__ BYTES</div>
        </div>
        <div>
            <a href="__DATAURI__" download="__FILENAME__" style="color:#00ff66; text-decoration:none; border:1px solid #00ff66; padding:4px 10px; font-size:12px;">DOWNLOAD RAW PDF</a>
        </div>
    </header>
    <iframe src="__DATAURI__"></iframe>
</body>
</html>
'@
            $finalHtml = $htmlTemplate.Replace('__FILENAME__', $pdfFileName).Replace('__PAGES__', [string]$telemetry.PageCount).Replace('__SIZE__', [string]$pdfBytes.Length).Replace('__DATAURI__', $dataUri)
            [System.IO.File]::WriteAllText($htmlFile, $finalHtml, [System.Text.Encoding]::UTF8)
            Write-Host " [✓ STANDALONE HTML READER GENERATED]: $htmlFile" -ForegroundColor $t.Fg
            Play-Sound "success"
        }
        
    } elseif ($opt -eq "2") {
        Write-Host " >> PASTE PDF BASE64 STREAM OR DATA-URI: " -NoNewline -ForegroundColor $t.Alert
        $raw = [Console]::ReadLine()
        $clean = Clean-Base64Input $raw
        try {
            $bytes = [System.Convert]::FromBase64String($clean)
            if ($bytes.Length -lt 4 -or $bytes[0] -ne 0x25 -or $bytes[1] -ne 0x50 -or $bytes[2] -ne 0x44 -or $bytes[3] -ne 0x46) {
                Write-Host " [!] WARNING: Magic bytes %PDF- not detected at stream start." -ForegroundColor $t.Alert
            }
            Write-Host " >> ENTER DESTINATION PDF PATH (e.g. document.pdf): " -NoNewline -ForegroundColor $t.Alert
            $outPath = [Console]::ReadLine().Trim()
            if (-not $outPath) { $outPath = "reconstituted_document.pdf" }
            [System.IO.File]::WriteAllBytes($outPath, $bytes)
            Write-Host " [✓ PDF RECONSTITUTED]: $outPath ($($bytes.Length) bytes)" -ForegroundColor $t.Fg
            Play-Sound "success"
        } catch {
            Write-Host " [✗ BASE64 DECODING ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
            Play-Sound "error"
        }
    } elseif ($opt -eq "3") {
        Write-Host " >> ENTER FULL PDF FILE PATH: " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine().Trim()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        $bytes = [System.IO.File]::ReadAllBytes($p)
        $tele = Parse-PdfTelemetry $bytes
        $pdfKb = [Math]::Round($bytes.Length / 1024, 2)
        Draw-Header "PDF STRUCTURAL INSPECTOR"
        $lines = @(
            "COMPLIANCE HEADER : $(if ($tele.Valid) { '[✓ PASSED] VALID PDF CONTAINER' } else { '[✗ FAILED] INVALID' })",
            "PDF SPEC VERSION  : %PDF-$($tele.Version)",
            "PAGE OBJECT COUNT : $($tele.PageCount) Pages Detected",
            "DOCUMENT TITLE    : $($tele.Title)",
            "AUTHOR ATTRIBUTE  : $($tele.Author)",
            "PRODUCER ENGINE   : $($tele.Producer)",
            "PHYSICAL PAYLOAD  : $($bytes.Length) bytes ($pdfKb KB)"
        )
        Draw-Box $lines "PDF TELEMETRY METRICS" $(if ($tele.Valid) { "Fg" } else { "Error" })
        Write-Host ""
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}

# OPERATION 13: MARKDOWN ASSET PACKAGER
function Invoke-MarkdownPackager {
    Draw-Header "MARKDOWN ASSET PACKAGER & UNPACKER"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [PACKAGING OPERATIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Pack Markdown Document · Inlines Local Images as Self-Contained Data URIs" -ForegroundColor $t.Fg
    Write-Host "  [2] Unpack Markdown Document · Extract Inline Data URIs to ./assets/ Directory" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $opt = Read-MenuSelectionOrClick " >> SELECT OPTION [1, 2, B]: "
    if ($opt -eq "B" -or [string]::IsNullOrEmpty($opt)) { return }
    
    if ($opt -eq "1") {
        Write-Host " >> ENTER MARKDOWN FILE PATH (e.g. README.md): " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine().Trim()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ MARKDOWN FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        
        Write-Host " [*] SCANNING FOR RELATIVE ASSET REFERENCES..." -ForegroundColor $t.Alert
        try {
            $packRes = Pack-MarkdownDocument -mdFilePath $p
            Play-Sound "success"
            Draw-Header "MARKDOWN PACKAGING SUMMARY"
            $lines = @(
                "SOURCE MARKDOWN   : $p",
                "IMAGES INLINED    : $($packRes.ImagesInlined) Media Assets Bundled",
                "TARGET STANDALONE : $($packRes.TargetFile)",
                "STATUS            : [✓ COMPLETED] 100% SELF-CONTAINED OFFLINE MARKDOWN"
            )
            Draw-Box $lines "PACKAGING TELEMETRY" "Fg"
            Write-Host ""
            if ($packRes.ImagesInlined -gt 0) {
                Write-Host " Inlined Assets:" -ForegroundColor $t.Accent
                foreach ($f in $packRes.InlinedFiles) {
                    Write-Host "   -> $f" -ForegroundColor $t.Fg
                }
                Write-Host ""
            }
        } catch {
            Write-Host " [✗ PACKAGING ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
            Play-Sound "error"
        }
        
    } elseif ($opt -eq "2") {
        Write-Host " >> ENTER MARKDOWN FILE PATH (containing data:image URIs): " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine().Trim()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ MARKDOWN FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        
        Write-Host " [*] PARSING INLINE DATA-URIS AND EXTRACTING ASSETS..." -ForegroundColor $t.Alert
        try {
            $unpackRes = Unpack-MarkdownDocument -mdFilePath $p
            Play-Sound "success"
            Draw-Header "MARKDOWN UNPACKING SUMMARY"
            $lines = @(
                "SOURCE MARKDOWN   : $p",
                "IMAGES EXTRACTED  : $($unpackRes.ImagesExtracted) Assets Extracted to Disk",
                "ASSET DIRECTORY   : $($unpackRes.AssetDir)",
                "NEW MARKDOWN FILE : $($unpackRes.TargetFile)",
                "STATUS            : [✓ COMPLETED] RELATIVE ASSET LINKS REBUILT"
            )
            Draw-Box $lines "UNPACKING TELEMETRY" "Fg"
            Write-Host ""
            if ($unpackRes.ImagesExtracted -gt 0) {
                Write-Host " Extracted Assets:" -ForegroundColor $t.Accent
                foreach ($f in $unpackRes.ExtractedFiles) {
                    Write-Host "   -> $f" -ForegroundColor $t.Fg
                }
                Write-Host ""
            }
        } catch {
            Write-Host " [✗ UNPACKING ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
            Play-Sound "error"
        }
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}

# OPERATION 14: PHOSPHOR QR-CODE GENERATOR
function Invoke-TerminalQrCode {
    Draw-Header "PHOSPHOR TERMINAL QR-CODE GENERATOR"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [INPUT DATA SELECTION]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Enter Custom String, URL or Token" -ForegroundColor $t.Fg
    Write-Host "  [2] Read Current Clipboard Payload" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $choice = Read-MenuSelectionOrClick " >> SELECT [1, 2, B]: "
    if ($choice -eq "B" -or [string]::IsNullOrEmpty($choice)) { return }
    
    $text = ""
    if ($choice -eq "1") {
        Write-Host " >> ENTER TEXT / URL (Up to 28 bytes for high-res matrix): " -NoNewline -ForegroundColor $t.Alert
        $text = [Console]::ReadLine()
    } elseif ($choice -eq "2") {
        try {
            $text = [System.Windows.Forms.Clipboard]::GetText()
            Write-Host " [✓ READ FROM CLIPBOARD]: $text" -ForegroundColor $t.Fg
        } catch {
            Write-Host " [✗ FAILED TO ACCESS CLIPBOARD]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($text)) { return }
    
    try {
        $matrix = [MiniQr]::Generate($text)
        $size = $matrix.GetLength(0)
        
        Draw-Header "TERMINAL PHOSPHOR QR SCANNER"
        Write-Host " [AIM MOBILE DEVICE OR SCANNER AT TERMINAL PHOSPHOR DISPLAY]" -ForegroundColor $t.Alert
        Write-Host " PAYLOAD: $text" -ForegroundColor $t.Dim
        Write-Host ""
        
        $quiet = 2
        for ($q = 0; $q -lt $quiet; $q++) {
            Write-Host (" " * 6) -NoNewline
            Write-Host ("  " * ($size + ($quiet * 2))) -ForegroundColor $t.Bg -BackgroundColor White
        }
        
        for ($r = 0; $r -lt $size; $r++) {
            Write-Host (" " * 6) -NoNewline
            Write-Host ("  " * $quiet) -NoNewline -ForegroundColor $t.Bg -BackgroundColor White
            for ($c = 0; $c -lt $size; $c++) {
                if ($matrix[$r, $c]) {
                    Write-Host ([char]0x2588 + [char]0x2588) -NoNewline -ForegroundColor Black -BackgroundColor Black
                } else {
                    Write-Host "  " -NoNewline -ForegroundColor White -BackgroundColor White
                }
            }
            Write-Host ("  " * $quiet) -ForegroundColor $t.Bg -BackgroundColor White
        }
        
        for ($q = 0; $q -lt $quiet; $q++) {
            Write-Host (" " * 6) -NoNewline
            Write-Host ("  " * ($size + ($quiet * 2))) -ForegroundColor $t.Bg -BackgroundColor White
        }
        
        Write-Host ""
        Play-Sound "success"
        
        $card = @(
            "QR MATRIX DIMENSIONS : ${size}x${size} Modules (Version 2)",
            "ERROR CORRECTION     : Level L (7 pct Recovery)",
            "PAYLOAD ENCODING     : 8-Bit Byte Mode (RFC-UTF8)",
            "CARRIER TELEMETRY    : In-Terminal Dual-Cell ASCII Blocks"
        )
        Draw-Box $card "QR TELEMETRY METRICS" "Accent"
        Write-Host ""
        
    } catch {
        Write-Host " [✗ QR GENERATION ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
        Play-Sound "error"
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}

# OPERATION 15: STEGANOGRAPHY CARRIER
function Invoke-StegoCarrier {
    Draw-Header "DIGITAL STEGANOGRAPHY MEDIA CARRIER"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [STEGANOGRAPHY OPERATIONS]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Infiltrate Secret Payload into Media Carrier (Stego Inject)" -ForegroundColor $t.Fg
    Write-Host "  [2] Extract & Recover Hidden Secret from Media Carrier (Stego Scan)" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $opt = Read-MenuSelectionOrClick " >> SELECT OPTION [1, 2, B]: "
    if ($opt -eq "B" -or [string]::IsNullOrEmpty($opt)) { return }
    
    if ($opt -eq "1") {
        Write-Host " >> ENTER CARRIER IMAGE OR FILE PATH: " -NoNewline -ForegroundColor $t.Alert
        $carrierP = [Console]::ReadLine().Trim()
        if (-not (Test-Path $carrierP)) {
            Write-Host " [✗ CARRIER FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        
        Write-Host " >> ENTER SECRET PAYLOAD (Plain Text, or [F] to load a file): " -NoNewline -ForegroundColor $t.Alert
        $secIn = [Console]::ReadLine()
        $secBytes = $null
        if ($secIn.Trim().ToUpper() -eq "F") {
            Write-Host " >> ENTER SECRET FILE PATH: " -NoNewline -ForegroundColor $t.Alert
            $secFilePath = [Console]::ReadLine().Trim()
            if (Test-Path $secFilePath) {
                $secBytes = [System.IO.File]::ReadAllBytes($secFilePath)
            } else {
                Write-Host " [✗ SECRET FILE NOT FOUND]" -ForegroundColor $t.Error
                Play-Sound "error"
                Start-Sleep -Milliseconds 800
                return
            }
        } else {
            $secBytes = [System.Text.Encoding]::UTF8.GetBytes($secIn)
        }
        
        $carrierDir = Split-Path $carrierP -Parent
        $carrierName = [System.IO.Path]::GetFileNameWithoutExtension($carrierP)
        $carrierExt = [System.IO.Path]::GetExtension($carrierP)
        $defOut = [System.IO.Path]::Combine($carrierDir, $carrierName + "_stego" + $carrierExt)
        
        Write-Host " >> ENTER OUTPUT FILE PATH [Default: $defOut]: " -NoNewline -ForegroundColor $t.Alert
        $outP = [Console]::ReadLine().Trim()
        if (-not $outP) { $outP = $defOut }
        
        try {
            $inj = Inject-StegoCarrier -carrierFilePath $carrierP -payloadBytes $secBytes -outputCarrierPath $outP
            Play-Sound "success"
            Draw-Header "STEGO INFILTRATION COMPLETE"
            $lines = @(
                "CARRIER INPUT  : $carrierP ($($inj.CarrierSize) bytes)",
                "PAYLOAD SIZE   : $($inj.PayloadSize) bytes secret payload injected",
                "STEGO OUTPUT   : $($inj.OutputFile) ($($inj.TotalSize) bytes)",
                "STEGO SECURITY : Marker Tagged Base64 Enclosed Stream"
            )
            Draw-Box $lines "INFILTRATION REPORT" "Fg"
            Write-Host ""
        } catch {
            Write-Host " [✗ INJECTION ERROR]: $($_.Exception.Message)" -ForegroundColor $t.Error
            Play-Sound "error"
        }
        
    } elseif ($opt -eq "2") {
        Write-Host " >> ENTER STEGO CARRIER FILE PATH: " -NoNewline -ForegroundColor $t.Alert
        $carrierP = [Console]::ReadLine().Trim()
        if (-not (Test-Path $carrierP)) {
            Write-Host " [✗ FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        
        Write-Host " [*] SCANNING CARRIER STREAM FOR HIDDEN BASE64 PAYLOAD..." -ForegroundColor $t.Alert
        $res = Extract-StegoCarrier -carrierFilePath $carrierP
        if ($res.Found) {
            Play-Sound "success"
            Draw-Header "STEGO RECOVERY SUCCESS"
            $preview = try { [System.Text.Encoding]::UTF8.GetString($res.Bytes) } catch { "Binary Payload" }
            if ($preview.Length -gt 50) { $preview = $preview.Substring(0, 47) + "..." }
            
            $lines = @(
                "STEGO STATUS    : [✓ DETECTED & EXTRACTED] HIDDEN PAYLOAD RECOVERED",
                "PAYLOAD BYTES   : $($res.Bytes.Length) bytes",
                "DATA FORMAT     : $($res.MediaInfo.Format) ($($res.MediaInfo.Mime))",
                "PREVIEW TEXT    : $preview"
            )
            Draw-Box $lines "RECOVERED SECRET TELEMETRY" "Fg"
            Write-Host ""
            
            Write-Host " [EXTRACTION ACTIONS]:" -ForegroundColor $t.Accent
            Write-Host "  [1] Save Extracted Payload to Disk" -ForegroundColor $t.Fg
            Write-Host "  [2] Copy Base64 / Text to Clipboard" -ForegroundColor $t.Fg
            Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
            Write-Host ""
            
            $act = Read-MenuSelectionOrClick " >> SELECT ACTION [1, 2, B]: "
            if ($act -eq "1") {
                $ext = if ($res.MediaInfo.Extension) { $res.MediaInfo.Extension } else { ".bin" }
                $saveP = "extracted_secret" + $ext
                Write-Host " >> ENTER OUTPUT PATH [Default: $saveP]: " -NoNewline -ForegroundColor $t.Alert
                $userP = [Console]::ReadLine().Trim()
                if ($userP) { $saveP = $userP }
                [System.IO.File]::WriteAllBytes($saveP, $res.Bytes)
                Write-Host " [✓ EXTRACTED PAYLOAD WRITTEN TO]: $saveP" -ForegroundColor $t.Fg
                Play-Sound "success"
            } elseif ($act -eq "2") {
                try {
                    $txtToCopy = if ($preview -ne "Binary Payload") { [System.Text.Encoding]::UTF8.GetString($res.Bytes) } else { $res.Base64 }
                    [System.Windows.Forms.Clipboard]::SetText($txtToCopy)
                    Write-Host " [✓ PAYLOAD COPIED TO SYSTEM CLIPBOARD]" -ForegroundColor $t.Fg
                    Play-Sound "success"
                } catch {
                    Write-Host " [✗ CLIPBOARD ERROR]" -ForegroundColor $t.Error
                }
            }
        } else {
            Write-Host " [✗ NO HIDDEN STEGO PAYLOAD DETECTED IN CARRIER]" -ForegroundColor $t.Alert
            Play-Sound "error"
        }
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}

# OPERATION 16: MULTI-HASH CRYPTOGRAPHIC TELEMETRY GRID
function Invoke-CryptoHashSuite {
    Draw-Header "CRYPTOGRAPHIC MULTI-HASH TELEMETRY GRID"
    $t = Get-Theme
    $b = Get-BoxStyle
    Play-Sound "blip"
    
    Write-Host " [DATA STREAM SOURCE]:" -ForegroundColor $t.Accent
    Write-Host "  [1] Compute Hashes for File on Disk" -ForegroundColor $t.Fg
    Write-Host "  [2] Compute Hashes for Base64 String" -ForegroundColor $t.Fg
    Write-Host "  [3] Compute Hashes for Raw Plaintext" -ForegroundColor $t.Fg
    Write-Host "  [B] Return to Operational Deck" -ForegroundColor $t.Dim
    Write-Host ""
    
    $srcOpt = Read-MenuSelectionOrClick " >> SELECT SOURCE [1-3, B]: "
    if ($srcOpt -eq "B" -or [string]::IsNullOrEmpty($srcOpt)) { return }
    
    $bytes = $null
    $desc = ""
    
    if ($srcOpt -eq "1") {
        Write-Host " >> ENTER FULL FILE PATH: " -NoNewline -ForegroundColor $t.Alert
        $p = [Console]::ReadLine().Trim()
        if (-not (Test-Path $p)) {
            Write-Host " [✗ FILE NOT FOUND]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
        $bytes = [System.IO.File]::ReadAllBytes($p)
        $desc = (Split-Path $p -Leaf)
    } elseif ($srcOpt -eq "2") {
        Write-Host " >> PASTE BASE64 PAYLOAD: " -NoNewline -ForegroundColor $t.Alert
        $b64 = [Console]::ReadLine()
        $clean = Clean-Base64Input $b64
        try {
            $bytes = [System.Convert]::FromBase64String($clean)
            $desc = "Decoded Base64 Stream ($($clean.Length) chars)"
        } catch {
            Write-Host " [✗ INVALID BASE64 STREAM]" -ForegroundColor $t.Error
            Play-Sound "error"
            Start-Sleep -Milliseconds 800
            return
        }
    } elseif ($srcOpt -eq "3") {
        Write-Host " >> ENTER PLAINTEXT STRING: " -NoNewline -ForegroundColor $t.Alert
        $str = [Console]::ReadLine()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($str)
        $desc = "UTF-8 String ('$str')"
    }
    
    if ($null -eq $bytes) { return }
    
    $hashes = Get-MultiHashTelemetry $bytes
    Play-Sound "success"
    
    $hashKb = [Math]::Round($hashes.Length / 1024, 2)
    Draw-Header "CRYPTOGRAPHIC DIGEST REPORT"
    $card = @(
        "STREAM IDENTITY  : $desc",
        "BYTE PAYLOAD     : $($hashes.Length) bytes ($hashKb KB)",
        "MD5 (RFC-1321)   : $($hashes.MD5)",
        "SHA-1 (FIPS-180) : $($hashes.SHA1)",
        "SHA-256 (SECURE) : $($hashes.SHA256)",
        "SHA-384          : $($hashes.SHA384)",
        "SHA-512 (HIGH)   : $($hashes.SHA512.Substring(0, 48))...",
        "                   $($hashes.SHA512.Substring(48))"
    )
    Draw-Box $card "INTEGRITY DIGEST TELEMETRY" "Fg"
    Write-Host ""
    
    Write-Host " >> COMPARE WITH KNOWN CHECKSUM? (Paste expected hash or press ENTER to skip): " -NoNewline -ForegroundColor $t.Alert
    $expected = [Console]::ReadLine().Trim().ToLower()
    if ($expected) {
        $matched = $false
        $algo = ""
        foreach ($k in @("MD5", "SHA1", "SHA256", "SHA384", "SHA512")) {
            if ($hashes[$k] -eq $expected) {
                $matched = $true
                $algo = $k
                break
            }
        }
        if ($matched) {
            Write-Host " [✓ MATCH VERIFIED] Exact match confirmed for algorithm: $algo" -ForegroundColor Green
            Play-Sound "success"
        } else {
            Write-Host " [✗ HASH MISMATCH] Provided checksum does NOT match any computed hash algorithms." -ForegroundColor Red
            Play-Sound "error"
        }
        Write-Host ""
    }
    
    Write-Host " Press [ENTER] to return..." -ForegroundColor $t.Dim
    [void][Console]::ReadLine()
}


# ==============================================================================
# OPERATION 10: CONFIGURATION & THEMES
# ==============================================================================
function Invoke-ConfigMenu {
    $borderOrder = @("Double", "Single", "Rounded", "Block", "Ascii")
    while ($true) {
        $t = Get-Theme
        $b = Get-BoxStyle
        Draw-Header "ENVIRONMENT & TERMINAL CONFIGURATION"
        Play-Sound "blip"
        
        Write-Host " [COLOR THEME PALETTES]:" -ForegroundColor $t.Accent
        for ($i = 0; $i -lt $script:Themes.Count; $i++) {
            $marker = if ($i -eq $script:Config.ThemeIndex) { "[* ACTIVE]" } else { "         " }
            $r = try { [Console]::CursorTop } catch { -1 }
            if ($r -ge 0) { Register-Hitbox -key "$($i+1)" -row $r -startCol 0 -endCol 85 }
            Write-Host "  [$($i+1)] $($script:Themes[$i].Name.PadRight(30)) $marker" -ForegroundColor $(if ($i -eq $script:Config.ThemeIndex) { $t.Alert } else { $t.Fg })
        }
        Write-Host ""
        Write-Host " [WINDOW FRAME & BORDER ENGINE]:" -ForegroundColor $t.Accent
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0) { Register-Hitbox -key "F" -row $r -startCol 0 -endCol 85 }
        Write-Host "  [F] Cycle Frame Style: $($b.Name) [PRESS 'F']" -ForegroundColor $t.Alert
        Write-Host ""
        Write-Host " [SYSTEM SOUND & TELEMETRY]:" -ForegroundColor $t.Accent
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0) { Register-Hitbox -key "S" -row $r -startCol 0 -endCol 85 }
        Write-Host "  [S] Acoustic CRT Beeps: $(if ($script:Config.SoundEnabled) { 'ENABLED [ON]' } else { 'MUTED [OFF]' })" -ForegroundColor $t.Fg
        Write-Host ""
        Write-Host " [CONSOLE MOUSE INPUT ENGINE]:" -ForegroundColor $t.Accent
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0) { Register-Hitbox -key "M" -row $r -startCol 0 -endCol 85 }
        Write-Host "  [M] Mouse VT Tracking:  $(if ($script:Config.MouseEnabled) { 'ENABLED [ON]' } else { 'DISABLED [OFF]' })" -ForegroundColor $t.Alert
        Write-Host ""
        Write-Host " [BASE64 LINE WRAP FORMATTING]:" -ForegroundColor $t.Accent
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0) { Register-Hitbox -key "W" -row $r -startCol 0 -endCol 85 }
        Write-Host "  [W] Output Wrap: $(if ($script:Config.WrapMode -eq 0) { 'Continuous Stream (No Wrap)' } else { "$($script:Config.WrapMode) Chars / Line" })" -ForegroundColor $t.Fg
        Write-Host ""
        
        # Live Preview Box
        $previewMeter = Draw-MeterBar 78.5 16 "SIGNAL OPTIMAL"
        $previewLines = @(
            "THEME PALETTE : $($t.Name)",
            "BORDER ENGINE : $($b.Name)",
            "MOUSE STATUS  : $(if ($script:Config.MouseEnabled) { 'Active Point-and-Click' } else { 'Keystroke Only' })",
            "TELEMETRY BAR : $previewMeter",
            "ACCENT COLOR  : 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        )
        Draw-Box $previewLines "LIVE WORKSTATION PREVIEW" "Fg"
        Write-Host ""
        
        $r = try { [Console]::CursorTop } catch { -1 }
        if ($r -ge 0) { Register-Hitbox -key "B" -row $r -startCol 0 -endCol 85 }
        Write-Host "  [B] Return to Main System Menu" -ForegroundColor $t.Dim
        Write-Host ""
        $choice = Read-MenuSelectionOrClick " >> SELECT SETTING [1-7, F, S, M, W, B]: "
        
        if ($choice -match '^[1-7]$') {
            $script:Config.ThemeIndex = [int]$choice - 1
            Play-Sound "blip"
        } elseif ($choice -eq "F") {
            $currIdx = $borderOrder.IndexOf($script:Config.BorderStyle)
            if ($currIdx -lt 0) { $currIdx = 0 }
            $nextIdx = ($currIdx + 1) % $borderOrder.Count
            $script:Config.BorderStyle = $borderOrder[$nextIdx]
            Play-Sound "blip"
        } elseif ($choice -eq "S") {
            $script:Config.SoundEnabled = -not $script:Config.SoundEnabled
            Play-Sound "blip"
        } elseif ($choice -eq "M") {
            $script:Config.MouseEnabled = -not $script:Config.MouseEnabled
            Play-Sound "blip"
        } elseif ($choice -eq "W") {
            switch ($script:Config.WrapMode) {
                0  { $script:Config.WrapMode = 76 }
                76 { $script:Config.WrapMode = 64 }
                64 { $script:Config.WrapMode = 0 }
            }
            Play-Sound "blip"
        } elseif ($choice -eq "B" -or [string]::IsNullOrEmpty($choice)) {
            break
        }
    }
}

# ==============================================================================
# MAIN TERMINAL LOOP
# ==============================================================================
function Start-CambrianSystemsTUI {
    [Console]::Title = "CAMBRIANSYSTEMS // DATA TRANSMUTATION WORKSTATION v5.2"
    
    try {
        if ([Console]::WindowWidth -lt 85) { [Console]::WindowWidth = 85 }
        if ([Console]::WindowHeight -lt 40) { [Console]::WindowHeight = 40 }
    } catch {}
    
    Play-Sound "alert"
    
    while ($true) {
        $t = Get-Theme
        Draw-Header -IsMainMenu
        
        $menuItems = @(
            " --- [ DIVISION 01: CORE DATA TRANSMUTATION ] ---------------------------------",
            "  [1] TEXT TRANSMUTATION          -> Base64 Encode / Decode Plaintext (RFC-4648)",
            "  [2] PHOTO & MEDIA VAULT         -> Image Ingestion, Rebuild & Phosphor Scan",
            "  [4] MULTI-TRANSCODER & SNIFFER  -> Base64URL, Hex/Base16, URI & Auto-Crack",
            " ",
            " --- [ DIVISION 02: DOCUMENT & MEDIA CONVERSION ] ------------------------------",
            "  [A] IMAGE FORMAT TRANSCODER     -> PNG, JPG, ICO, BMP, GIF, TIFF Resizer",
            "  [C] PDF TRANSMUTATION HUB       -> PDF Data URI Packing, Rebuild & Reader",
            "  [D] MARKDOWN ASSET PACKAGER     -> Inline Local Media to Data URIs/Extract",
            " ",
            " --- [ DIVISION 03: SECURITY TOKENS & CRYPTO PROBES ] --------------------------",
            "  [3] JWT CORPORATE INSPECTOR     -> Header & Claims Decoder with Lifetime Meter",
            "  [9] BASE64 INTEGRITY INSPECTOR  -> RFC-4648 Modulo-4 Checker & SHA-256 Check",
            "  [H] MULTI-HASH TELEMETRY GRID   -> MD5, SHA-1, SHA-256, SHA-384, SHA-512",
            "  [E] STEGANOGRAPHY CARRIER       -> Hide & Extract Base64 Payloads in Media",
            " ",
            " --- [ DIVISION 04: BINARY, COMPRESSION & QR PIPELINES ] -----------------------",
            "  [5] GZIP COMPRESSION LAB        -> High-Ratio Compressed Streams (RFC-1952)",
            "  [6] POWERSHELL ENCODED COMMAND  -> Generate & Reverse UTF-16LE -EncodedCommand",
            "  [7] NORTON HEX DUMP INSPECTOR   -> Byte Memory Grid with Offset & ASCII Gutter",
            "  [8] OFFLINE BATCH HTML VAULT    -> Bulk Directory Scanner & Cyber Gallery",
            "  [R] PHOSPHOR QR GENERATOR       -> Render In-Terminal Dual-Cell QR Code",
            " ",
            " --- [ DIVISION 05: TERMINAL ENVIRONMENT & SYSTEM EXIT ] -----------------------",
            "  [0] TERMINAL ENVIRONMENT        -> CRT Themes, Sound & Line Formatting",
            "  [Q] TERMINATE WORKSTATION       -> Flush Cache Buffers & Disconnect Session"
        )
        Draw-Box $menuItems "DATA TRANSMUTATION OPERATIONS" "Fg"
        Write-Host ""
        
        Draw-StatusBar "READY // WORKSTATION ONLINE // CAMBRIANSYSTEMS v5.2"
        Write-Host ""
        
        $opt = Read-MenuSelectionOrClick " >> COMMAND SELECTION [0-9, A, C, D, H, E, R, Q] OR CLICK: "
        
        switch ($opt) {
            "1" { Invoke-TextMenu }
            "2" { Invoke-PhotoMenu }
            "3" { Invoke-JwtInspector }
            "4" { Invoke-MultiTranscoder }
            "5" { Invoke-GzipMenu }
            "6" { Invoke-PowerShellEncodedMenu }
            "7" { Invoke-HexDumpViewer }
            "8" { Invoke-BatchTransmuter }
            "9" { Invoke-Inspector }
            "0" { Invoke-ConfigMenu }
            "A" { Invoke-ImageConverter }
            "C" { Invoke-PdfTransmuter }
            "D" { Invoke-MarkdownPackager }
            "H" { Invoke-CryptoHashSuite }
            "E" { Invoke-StegoCarrier }
            "R" { Invoke-TerminalQrCode }
            "Q" {
                Draw-Header "TERMINATING SESSION"
                Write-Host " [!] COMMENCING SYSTEM BUFFER FLUSH AND LOGOFF..." -ForegroundColor $t.Alert
                Play-Sound "blip"
                try { [Console]::ResetColor() } catch {}
                try { [Console]::Clear() } catch {}
                Write-Host "CAMBRIANSYSTEMS WORKSTATION DISCONNECTED.`n"
                return
            }
            default {
                if ($opt) { Play-Sound "error" }
            }
        }
    }
}

function Start-Base64TUI { Start-CambrianSystemsTUI @args }
Set-Alias -Name cambriansystems-tui -Value Start-CambrianSystemsTUI -ErrorAction SilentlyContinue
Set-Alias -Name base64-tui -Value Start-CambrianSystemsTUI -ErrorAction SilentlyContinue

# Entrypoint Execution
Start-CambrianSystemsTUI