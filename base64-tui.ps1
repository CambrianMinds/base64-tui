<#
.SYNOPSIS
    CAMBRIANSYSTEMS // DATA TRANSMUTATION RELAY CONSOLE (BASE64-TUI v5.0)
    Retro-Corporate Terminal & Security Workstation
    RFC 4648 / MIME Base64 / JWT / Base64URL / Hex / GZip / PS-EncodedCommand / HexDump
#>

# Ensure required assemblies are loaded
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression

# Global Configuration & State
$script:Config = @{
    ThemeIndex = 0
    SoundEnabled = $true
    LineWidth = 85
    WrapMode = 76 # 0 = None, 64 = RFC1421, 76 = RFC2045
    DefaultEncoding = "UTF8"
}

# Retro Themes Palette
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

# Drawing & Layout Utilities
function Draw-Header {
    param([string]$subTitle = "")
    $t = Get-Theme
    $w = [Math]::Max(82, [Console]::WindowWidth)
    
    [Console]::BackgroundColor = [ConsoleColor]::$($t.Bg)
    [Console]::Clear()
    
    # Corporate Top Warning
    Write-Host ("+" + ("=" * ($w - 2)) + "+") -ForegroundColor $t.Dim -BackgroundColor $t.Bg
    
    $bannerText = "CAMBRIANSYSTEMS CORP. // DATA INTEGRITY & BASE64 TRANSMUTATION WORKSTATION"
    $spaces = [Math]::Max(0, ($w - 2 - $bannerText.Length) / 2)
    $bannerLine = "|" + (" " * [Math]::Floor($spaces)) + $bannerText + (" " * [Math]::Ceiling($spaces)) + "|"
    if ($bannerLine.Length -gt $w) { $bannerLine = $bannerLine.Substring(0, $w) }
    Write-Host $bannerLine -ForegroundColor $t.HeaderFg -BackgroundColor $t.HeaderBg
    
    $secText = "[ SYS: ONLINE ] [ PROTOCOL: ACTIVE ] [ RFC-4648 / JWT / GZIP / HEX-DUMP ]"
    $secSpaces = [Math]::Max(0, ($w - 2 - $secText.Length) / 2)
    $secLine = "|" + (" " * [Math]::Floor($secSpaces)) + $secText + (" " * [Math]::Ceiling($secSpaces)) + "|"
    if ($secLine.Length -gt $w) { $secLine = $secLine.Substring(0, $w) }
    Write-Host $secLine -ForegroundColor $t.Accent -BackgroundColor $t.Bg
    
    if ($subTitle) {
        $sub = ">> WORKSTATION SUB-SYSTEM: $subTitle <<"
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
    $w = [Math]::Max(82, [Console]::WindowWidth)
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
    $w = [Math]::Min(80, [Console]::WindowWidth - 2)
    if ($w -lt 30) { $w = 80 }
    
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
        $padded = "| " + $str.PadRight($w - 4) + " |"
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
        $headerTag = "+-- [ IMAGE PHOSPHOR SCAN: ${w}x${h} ] "
        $fillLen = [Math]::Max(2, $scaledW + 4 - $headerTag.Length)
        Write-Host $headerTag -NoNewline -ForegroundColor $t.Accent
        Write-Host ("-" * $fillLen + "+") -ForegroundColor $t.Dim
        
        for ($y = 0; $y -lt $scaledH; $y++) {
            Write-Host "| " -NoNewline -ForegroundColor $t.Accent
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
            Write-Host " |" -ForegroundColor $t.Accent
        }
        $footer = "+" + ("-" * ($scaledW + 2)) + "+"
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
    
    $stats = @(
        "SOURCE FORMAT        : UTF-8 PLAINTEXT",
        "BYTE SIZE            : $($rawBytes.Length) bytes ($($inputText.Length) characters)",
        "BASE64 STRING LENGTH : $($b64Result.Length) characters",
        "BANDWIDTH EXPANSION  : +$([Math]::Round((($b64Result.Length - $rawBytes.Length) / [Math]::Max(1, $rawBytes.Length)) * 100, 1))%",
        "PADDING              : $(if ($b64Result.EndsWith('==')) { '2 (==)' } elseif ($b64Result.EndsWith('=')) { '1 (=)' } else { '0' })"
    )
    Draw-Box $stats "TELEMETRY METRICS" "Fg"
    Write-Host ""
    
    Write-Host " +-- [ BASE64 STREAM PREVIEW (FIRST 400 CHARS) ] " -ForegroundColor $t.Accent
    $previewLen = [Math]::Min(400, $formattedB64.Length)
    Write-Host $formattedB64.Substring(0, $previewLen) -ForegroundColor $t.Alert
    if ($formattedB64.Length -gt 400) {
        Write-Host " ... [$(($formattedB64.Length - 400)) CHARACTERS TRUNCATED] ..." -ForegroundColor $t.Dim
    }
    Write-Host " +--" -ForegroundColor $t.Accent
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
        "CLEANED BASE64 LENGTH: $($cleanB64.Length) chars",
        "RECOVERED BYTE COUNT : $($decodedBytes.Length) bytes",
        "ENCODING             : UTF-8 PLAINTEXT",
        "LINES DETECTED       : $(($decodedText -split "`r`n|`n").Length)"
    )
    Draw-Box $stats "PAYLOAD TELEMETRY" "Fg"
    Write-Host ""
    
    Write-Host " +-- [ DECODED PLAINTEXT PREVIEW (FIRST 500 CHARS) ] " -ForegroundColor $t.Accent
    $textPreview = if ($decodedText.Length -gt 500) { $decodedText.Substring(0, 500) + "`n... [TRUNCATED] ..." } else { $decodedText }
    Write-Host $textPreview -ForegroundColor $t.Alert
    Write-Host " +--" -ForegroundColor $t.Accent
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
    
    $stats = @(
        "SOURCE FILE          : $([System.IO.Path]::GetFileName($filePath))",
        "FORMAT               : $($mediaInfo.Format) ($($mediaInfo.Mime))",
        "DIMENSIONS           : $dimInfo",
        "RAW SIZE             : $([Math]::Round($fileBytes.Length / 1024, 2)) KB ($($fileBytes.Length) bytes)",
        "BASE64 STRING LENGTH : $($rawB64.Length) characters",
        "EXPANSION RATIO      : +$([Math]::Round((($rawB64.Length - $fileBytes.Length) / $fileBytes.Length) * 100, 1))%"
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
        "RECOVERED FILE SIZE  : $([Math]::Round($bytes.Length / 1024, 2)) KB ($($bytes.Length) bytes)"
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
    
    if ($jwt.Payload.PSObject.Properties['exp']) {
        $expVal = [long]$jwt.Payload.exp
        $expTime = ([DateTimeOffset]::FromUnixTimeSeconds($expVal)).UtcDateTime
        if ($expTime -lt $now) {
            $diff = $now - $expTime
            $statusText = "EXPIRED ($([Math]::Round($diff.TotalMinutes, 1)) minutes ago at $(($expTime.ToLocalTime()).ToString('yyyy-MM-dd HH:mm:ss')))"
            $statusColor = "Error"
        } else {
            $diff = $expTime - $now
            $statusText = "ACTIVE (Valid for $([Math]::Round($diff.TotalMinutes, 1)) minutes until $(($expTime.ToLocalTime()).ToString('yyyy-MM-dd HH:mm:ss')))"
            $statusColor = "Fg"
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
        "ISSUER (iss)         : $(if ($jwt.Payload.PSObject.Properties['iss']) { $jwt.Payload.iss } else { 'NOT SPECIFIED' })",
        "SUBJECT (sub)        : $(if ($jwt.Payload.PSObject.Properties['sub']) { $jwt.Payload.sub } else { 'NOT SPECIFIED' })",
        "AUDIENCE (aud)       : $(if ($jwt.Payload.PSObject.Properties['aud']) { $jwt.Payload.aud } else { 'NOT SPECIFIED' })"
    )
    Draw-Box $payloadSummary "SECURITY CONTEXT & CLAIMS" $statusColor
    Write-Host ""
    
    Write-Host " +-- [ DECODED PAYLOAD CLAIMS (RAW JSON) ] " -ForegroundColor $t.Accent
    try {
        $prettyJson = $jwt.PayloadRaw | ConvertFrom-Json | ConvertTo-Json -Depth 6
        Write-Host $prettyJson -ForegroundColor $t.Alert
    } catch {
        Write-Host $jwt.PayloadRaw -ForegroundColor $t.Alert
    }
    Write-Host " +--" -ForegroundColor $t.Accent
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
        $stats = @(
            "ORIGINAL SIZE       : $($rawBytes.Length) bytes",
            "GZIP BINARY SIZE    : $($compressed.Length) bytes",
            "BASE64 STRING LEN   : $($b64.Length) characters",
            "COMPRESSION RATIO   : $([Math]::Round((1 - ($compressed.Length / [Math]::Max(1, $rawBytes.Length))) * 100, 1))% SPACE SAVED"
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
            
            Draw-Header "POWERSHELL CODE RECOVERED"
            Write-Host " +-- [ DECODED SCRIPT OUTPUT ] " -ForegroundColor $t.Accent
            Write-Host $decodedCmd -ForegroundColor $t.Alert
            Write-Host " +--" -ForegroundColor $t.Accent
            
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
        Draw-Header "HEX DUMP (BYTES $curOffset - $([Math]::Min($total, $curOffset + $pageSize)) OF $total)"
        Write-Host " OFFSET    00 01 02 03 04 05 06 07   08 09 0A 0B 0C 0D 0E 0F  ASCII DUMP" -ForegroundColor $t.Accent
        Write-Host ("-" * 74) -ForegroundColor $t.Dim
        
        $end = [Math]::Min($total, $curOffset + $pageSize)
        for ($pos = $curOffset; $pos -lt $end; $pos += 16) {
            $len = [Math]::Min(16, $total - $pos)
            $line = Format-HexDumpLine $rawBytes $pos $len
            Write-Host $line -ForegroundColor $t.Fg
        }
        Write-Host ("-" * 74) -ForegroundColor $t.Dim
        
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
        "RFC 4648 COMPLIANCE   : $(if ($isValid) { 'PASSED [VALID]' } else { 'FAILED [CORRUPTED]' })",
        "ERROR DIAGNOSTIC      : $errorReason",
        "STRING LENGTH (RAW)   : $($rawB64.Length) characters",
        "CLEANED STRING LENGTH : $($clean.Length) characters",
        "DECODED BYTE COUNT    : $(if ($isValid) { "$($bytes.Length) bytes" } else { 'N/A' })",
        "MODULO 4 CHECK        : $(if ($clean.Length % 4 -eq 0) { 'PASSED' } else { 'FAILED (mod 4 = ' + ($clean.Length % 4) + ')' })",
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
# OPERATION 10: CONFIGURATION & THEMES
# ==============================================================================
function Invoke-ConfigMenu {
    while ($true) {
        $t = Get-Theme
        Draw-Header "ENVIRONMENT & TERMINAL CONFIGURATION"
        Play-Sound "blip"
        
        Write-Host " [COLOR THEME SELECTION]:" -ForegroundColor $t.Accent
        for ($i = 0; $i -lt $script:Themes.Count; $i++) {
            $marker = if ($i -eq $script:Config.ThemeIndex) { "[* ACTIVE]" } else { "         " }
            Write-Host "  [$($i+1)] $($script:Themes[$i].Name) $marker" -ForegroundColor $(if ($i -eq $script:Config.ThemeIndex) { $t.Alert } else { $t.Fg })
        }
        Write-Host ""
        Write-Host " [SYSTEM SOUND]:" -ForegroundColor $t.Accent
        Write-Host "  [S] Terminal Audio Acoustic Beeps: $(if ($script:Config.SoundEnabled) { 'ENABLED [ON]' } else { 'MUTED [OFF]' })" -ForegroundColor $t.Fg
        Write-Host ""
        Write-Host " [BASE64 LINE WRAP FORMATTING]:" -ForegroundColor $t.Accent
        Write-Host "  [W] Current Wrap: $(if ($script:Config.WrapMode -eq 0) { 'Continuous Stream (No Wrap)' } else { "$($script:Config.WrapMode) Chars / Line" })" -ForegroundColor $t.Fg
        Write-Host ""
        Write-Host " [B] Return to Main System Menu" -ForegroundColor $t.Dim
        Write-Host ""
        Write-Host " >> SELECT SETTING: " -NoNewline -ForegroundColor $t.Alert
        $choice = [Console]::ReadLine().ToUpper().Trim()
        
        if ($choice -match '^[1-4]$') {
            $script:Config.ThemeIndex = [int]$choice - 1
            Play-Sound "blip"
        } elseif ($choice -eq "S") {
            $script:Config.SoundEnabled = -not $script:Config.SoundEnabled
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
function Start-Base64TUI {
    [Console]::Title = "CAMBRIANSYSTEMS // DATA TRANSMUTATION WORKSTATION v5.0"
    
    try {
        if ([Console]::WindowWidth -lt 85) { [Console]::WindowWidth = 85 }
        if ([Console]::WindowHeight -lt 34) { [Console]::WindowHeight = 34 }
    } catch {}
    
    Play-Sound "alert"
    
    while ($true) {
        $t = Get-Theme
        Draw-Header "CAMBRIANSYSTEMS MAIN COMMAND CONSOLE v5.0"
        
        $menuItems = @(
            " [1] TEXT TRANSMUTATION          -> Base64 Encode / Decode Plaintext",
            " [2] PHOTO & IMAGE TRANSMUTATION  -> Encode Image / Rebuild & ASCII Scan",
            " [3] JWT CORPORATE INSPECTOR     -> Decode Claims, Header & Expiration",
            " [4] MULTI-TRANSCODER / SNIFFER  -> Base64URL, Hex, URL-Encode & Auto-Crack",
            " [5] GZIP COMPRESSION LAB        -> High-Ratio Compressed Base64 Streams",
            " [6] POWERSHELL ENCODED COMMAND  -> Generate & Decode -EncodedCommand",
            " [7] NORTON HEX DUMP INSPECTOR   -> Byte Memory Inspector with Offset & ASCII",
            " [8] BATCH & OFFLINE HTML VAULT  -> Folder Bulk Convert to Self-Contained HTML",
            " [9] BASE64 INTEGRITY INSPECTOR  -> RFC-4648 Validator & SHA-256 Telemetry",
            " [0] TERMINAL ENVIRONMENT        -> CRT Themes, Sound & Line Formatting",
            " [Q] LOGOUT / TERMINATE          -> Flush Cache & Disconnect Workstation"
        )
        Draw-Box $menuItems "DATA TRANSMUTATION OPERATIONS" "Fg"
        Write-Host ""
        
        Draw-StatusBar "READY // WORKSTATION ONLINE // CAMBRIANSYSTEMS v5.0"
        Write-Host ""
        Write-Host " >> COMMAND SELECTION [0-9, Q]: " -NoNewline -ForegroundColor $t.Alert
        
        $key = [Console]::ReadLine()
        if ($null -eq $key) { continue }
        $opt = $key.ToUpper().Trim()
        
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
            "Q" {
                Draw-Header "TERMINATING SESSION"
                Write-Host " [!] COMMENCING SYSTEM BUFFER FLUSH AND LOGOFF..." -ForegroundColor $t.Alert
                Play-Sound "blip"
                Start-Sleep -Milliseconds 500
                [Console]::ResetColor()
                [Console]::Clear()
                Write-Host "CAMBRIANSYSTEMS WORKSTATION DISCONNECTED.`n"
                return
            }
            default {
                Play-Sound "error"
            }
        }
    }
}

# Entrypoint Execution
Start-Base64TUI
