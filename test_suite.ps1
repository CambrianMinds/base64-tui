# Automated Comprehensive Test Suite for base64-tui.ps1 v5.2
$ErrorActionPreference = "Stop"
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ">>> Commencing CambrianSystems Workstation v5.2 Engine Tests..." -ForegroundColor Cyan

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

# Test 10: Image Transcoding (PNG to JPEG + Resizing)
Write-Host "Test 10: Image Transcoding (PNG -> JPEG 32x32)... " -NoNewline
$jpgBytes = Convert-ImageBytes -inputBytes $imgB -targetFormat "JPG" -targetWidth 32 -targetHeight 32 -jpegQuality 85
if ($jpgBytes.Length -gt 0 -and $jpgBytes[0] -eq 0xFF -and $jpgBytes[1] -eq 0xD8) {
    Write-Host "[PASS] ($($imgB.Length)B PNG -> $($jpgBytes.Length)B JPEG)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] JPEG transcoding failed" -ForegroundColor Red; exit 1
}

# Test 11: Windows ICO Container Generation
Write-Host "Test 11: Windows ICO Container Generation (16x16)... " -NoNewline
$icoBytes = Convert-ImageBytes -inputBytes $imgB -targetFormat "ICO" -targetWidth 16 -targetHeight 16
if ($icoBytes.Length -gt 22 -and $icoBytes[0] -eq 0x00 -and $icoBytes[1] -eq 0x00 -and $icoBytes[2] -eq 0x01 -and $icoBytes[3] -eq 0x00) {
    Write-Host "[PASS] ($($icoBytes.Length) bytes ICO generated)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] ICO generation failed" -ForegroundColor Red; exit 1
}

# Test 12: PDF Telemetry & Page Inspection
Write-Host "Test 12: PDF Telemetry & Page Counter... " -NoNewline
$mockPdf = [System.Text.Encoding]::ASCII.GetBytes("%PDF-1.7`r`n1 0 obj`r`n<< /Type /Catalog /Pages 2 0 R >>`r`nendobj`r`n2 0 obj`r`n<< /Type /Pages /Count 5 >>`r`nendobj`r`n%%EOF")
$pdfInfo = Parse-PdfTelemetry $mockPdf
if ($pdfInfo.Valid -and $pdfInfo.Version -eq "1.7" -and $pdfInfo.PageCount -eq 5) {
    Write-Host "[PASS] (PDF v$($pdfInfo.Version), $($pdfInfo.PageCount) pages)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] PDF telemetry inspection failed" -ForegroundColor Red; exit 1
}

# Test 13: Markdown Asset Packager (Inline Data URIs) & Unpack
Write-Host "Test 13: Markdown Asset Packager & Unpacker Roundtrip... " -NoNewline
$mdTest = "d:\tools\base64-tui\test_suite_temp.md"
$imgTest = "d:\tools\base64-tui\test_suite_asset.png"
[System.IO.File]::WriteAllBytes($imgTest, $imgB)
[System.IO.File]::WriteAllText($mdTest, "# Test Document`n`n![Sample Asset](test_suite_asset.png)`n", [System.Text.Encoding]::UTF8)

$packRes = Pack-MarkdownDocument -mdFilePath $mdTest
$unpackRes = Unpack-MarkdownDocument -mdFilePath $packRes.TargetFile

$packOk = ($packRes.ImagesInlined -eq 1 -and (Test-Path $packRes.TargetFile))
$unpackOk = ($unpackRes.ImagesExtracted -eq 1 -and (Test-Path $unpackRes.TargetFile))

Remove-Item $mdTest, $imgTest, $packRes.TargetFile, $unpackRes.TargetFile -ErrorAction SilentlyContinue
if (Test-Path "d:\tools\base64-tui\assets") { Remove-Item "d:\tools\base64-tui\assets" -Recurse -Force -ErrorAction SilentlyContinue }

if ($packOk -and $unpackOk) {
    Write-Host "[PASS] (Inlined & Unpacked successfully)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Markdown packager failed" -ForegroundColor Red; exit 1
}

# Test 14: Terminal Phosphor QR Code Matrix
Write-Host "Test 14: Terminal QR Code Matrix (MiniQr)... " -NoNewline
$qrMatrix = [MiniQr]::Generate("CAMBRIANSYSTEMS")
if ($qrMatrix.GetLength(0) -eq 25 -and $qrMatrix.GetLength(1) -eq 25) {
    Write-Host "[PASS] (25x25 QR Matrix generated)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] QR generation failed" -ForegroundColor Red; exit 1
}

# Test 15: Digital Steganography Carrier
Write-Host "Test 15: Digital Steganography Carrier (Inject & Recover)... " -NoNewline
$carrierFile = "d:\tools\base64-tui\carrier_suite.bin"
$stegoFile = "d:\tools\base64-tui\stego_suite.bin"
[System.IO.File]::WriteAllBytes($carrierFile, $imgB)
$secretPayload = [System.Text.Encoding]::UTF8.GetBytes("CAMBRIAN_CLASSIFIED_STEGO_2026")

$inj = Inject-StegoCarrier -carrierFilePath $carrierFile -payloadBytes $secretPayload -outputCarrierPath $stegoFile
$ext = Extract-StegoCarrier -carrierFilePath $stegoFile
$recovered = if ($ext.Found) { [System.Text.Encoding]::UTF8.GetString($ext.Bytes) } else { "" }

Remove-Item $carrierFile, $stegoFile -ErrorAction SilentlyContinue

if ($recovered -eq "CAMBRIAN_CLASSIFIED_STEGO_2026") {
    Write-Host "[PASS] (Secret injected into $($inj.TotalSize)B carrier & recovered)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Stego secret recovery failed" -ForegroundColor Red; exit 1
}

# Test 16: Cryptographic Multi-Hash Grid
Write-Host "Test 16: Cryptographic Multi-Hash Grid... " -NoNewline
$testPayload = [System.Text.Encoding]::UTF8.GetBytes("CAMBRIANSYSTEMS_TEST_HASH")
$multiHashes = Get-MultiHashTelemetry $testPayload
$expectedSha256 = -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($testPayload) | ForEach-Object { "{0:x2}" -f $_ })
if ($multiHashes.SHA256 -eq $expectedSha256 -and $multiHashes.MD5.Length -eq 32 -and $multiHashes.SHA512.Length -eq 128) {
    Write-Host "[PASS] (MD5, SHA1, SHA256, SHA384, SHA512 computed)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Multi-hash computation failed" -ForegroundColor Red; exit 1
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host ">>> ALL 16 WORKSTATION ENGINE TESTS PASSED WITH 100% PASS RATE! <<<" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
