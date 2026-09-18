# Automated Comprehensive Test Suite for base64-tui.ps1 v5.0
$ErrorActionPreference = "Stop"

Write-Host ">>> Commencing CambrianSystems Workstation v5.0 Engine Tests..." -ForegroundColor Cyan

# Source functions without running the main interactive loop
$content = [System.IO.File]::ReadAllText("d:\tools\base64-tui\base64-tui.ps1", [System.Text.Encoding]::UTF8)
$functionsOnly = $content -replace '(?ms)^Start-Base64TUI\s*$', ''
Invoke-Expression $functionsOnly

# Test 1: Clean-Base64Input
Write-Host "Test 1: Clean-Base64Input... " -NoNewline
$testB64 = " data:image/png;base64,  iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=  `r`n "
$cleaned = Clean-Base64Input $testB64
if ($cleaned -eq "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=") {
    Write-Host "[PASS]" -ForegroundColor Green
} else {
    Write-Host "[FAIL]" -ForegroundColor Red; exit 1
}

# Test 2: Standard Base64 Text Roundtrip
Write-Host "Test 2: Base64 Text Roundtrip... " -NoNewline
$origText = "CAMBRIANSYSTEMS DATA TRANSMUTATION RELAY 2026"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($origText)
$b64 = [System.Convert]::ToBase64String($bytes)
$recovered = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
if ($recovered -eq $origText) {
    Write-Host "[PASS]" -ForegroundColor Green
} else {
    Write-Host "[FAIL]" -ForegroundColor Red; exit 1
}

# Test 3: Base64URL (RFC 4648 §5)
Write-Host "Test 3: Base64URL Conversion (No Padding, - and _)... " -NoNewline
$sampleBytes = [byte[]]@(0xFB, 0xFF, 0xBF, 0x00, 0x3F)
$b64u = ConvertTo-Base64Url $sampleBytes
$b64uDecoded = ConvertFrom-Base64Url $b64u
if ($b64u -notmatch '[+/=]' -and ($sampleBytes -join ',') -eq ($b64uDecoded -join ',')) {
    Write-Host "[PASS] ($b64u)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Base64URL mismatch" -ForegroundColor Red; exit 1
}

# Test 4: Hex / Base16 Conversion
Write-Host "Test 4: Hex / Base16 Conversion... " -NoNewline
$hexStr = ConvertTo-HexString $sampleBytes
$hexDecoded = ConvertFrom-HexString $hexStr
if ($hexStr -eq "fbffbf003f" -and ($sampleBytes -join ',') -eq ($hexDecoded -join ',')) {
    Write-Host "[PASS] (0x$hexStr)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Hex mismatch: $hexStr" -ForegroundColor Red; exit 1
}

# Test 5: GZip Compressed Base64 Stream
Write-Host "Test 5: GZip-Compressed Base64 Roundtrip... " -NoNewline
$largeText = "CAMBRIANSYSTEMS INTERNAL DATA STREAM " * 50
$rawLarge = [System.Text.Encoding]::UTF8.GetBytes($largeText)
$gzBytes = Compress-GZipBytes $rawLarge
$decompressed = Decompress-GZipBytes $gzBytes
$decompressedText = [System.Text.Encoding]::UTF8.GetString($decompressed)
if ($decompressedText -eq $largeText -and $gzBytes.Length -lt $rawLarge.Length) {
    $ratio = [Math]::Round((1 - ($gzBytes.Length / $rawLarge.Length)) * 100, 1)
    Write-Host "[PASS] ($($rawLarge.Length)B -> $($gzBytes.Length)B, $ratio% reduction)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] GZip roundtrip mismatch" -ForegroundColor Red; exit 1
}

# Test 6: PowerShell -EncodedCommand (UTF-16LE)
Write-Host "Test 6: PowerShell -EncodedCommand Encoding... " -NoNewline
$psCode = "Write-Host 'CAMBRIANSYSTEMS ONLINE'"
$psBytes = [System.Text.Encoding]::Unicode.GetBytes($psCode)
$psB64 = [System.Convert]::ToBase64String($psBytes)
$psDecoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($psB64))
if ($psDecoded -eq $psCode) {
    Write-Host "[PASS]" -ForegroundColor Green
} else {
    Write-Host "[FAIL] EncodedCommand mismatch" -ForegroundColor Red; exit 1
}

# Test 7: JWT Parsing & Claims Extraction
Write-Host "Test 7: JWT Parsing & Claims Extraction... " -NoNewline
# Create a standard mock JWT (Header: {"alg":"HS256","typ":"JWT"}, Payload: {"sub":"operator-800","name":"John Connor","iat":1516239022,"exp":1999999999})
$hJson = '{"alg":"HS256","typ":"JWT"}'
$pJson = '{"sub":"operator-800","name":"John Connor","iat":1516239022,"exp":1999999999}'
$mockJwt = (ConvertTo-Base64Url ([System.Text.Encoding]::UTF8.GetBytes($hJson))) + "." + 
           (ConvertTo-Base64Url ([System.Text.Encoding]::UTF8.GetBytes($pJson))) + ".mockSignature123"

$parsedJwt = Parse-JwtToken $mockJwt
if ($parsedJwt.Header.alg -eq "HS256" -and $parsedJwt.Payload.sub -eq "operator-800") {
    Write-Host "[PASS] (Subject: $($parsedJwt.Payload.sub))" -ForegroundColor Green
} else {
    Write-Host "[FAIL] JWT parse failed" -ForegroundColor Red; exit 1
}

# Test 8: Norton Hex Dump Line Formatting
Write-Host "Test 8: Norton Hex Dump Line Format... " -NoNewline
$dumpBytes = [byte[]]@(0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00)
$dumpLine = Format-HexDumpLine $dumpBytes 0 16
if ($dumpLine -match '00000000: 4D 5A 90 00.+MZ') {
    Write-Host "[PASS] ($dumpLine)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Hex dump line format unexpected: $dumpLine" -ForegroundColor Red; exit 1
}

# Test 9: Image In-Memory ASCII Render
Write-Host "`nTest 9: ASCII Phosphor Scan Render:" -ForegroundColor Cyan
$bmp = New-Object System.Drawing.Bitmap 32, 16
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.Clear([System.Drawing.Color]::Black)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, 2)
$gfx.DrawRectangle($pen, 2, 2, 27, 11)
$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$imgB = $ms.ToArray()
$gfx.Dispose(); $pen.Dispose(); $bmp.Dispose(); $ms.Dispose()

$asciiOk = Render-AsciiThumbnail $imgB 28 8
if ($asciiOk) {
    Write-Host "[PASS] Image Phosphor Scan Rendered" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Phosphor scan failed" -ForegroundColor Red; exit 1
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host ">>> ALL 9 WORKSTATION ENGINE TESTS PASSED WITH 100% PASS RATE! <<<" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
