import sys
import re

file_path = r'D:\tools\cambriansystems-tui\cambriansystems-tui.ps1'
with open(file_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

search_func = r'function Read-MenuSelectionOrClick \{.*?^\}'
replace_func = '''function Read-MenuSelectionOrClick {
    param([string]$prompt = " >> SELECTION: ")
    $t = Get-Theme
    Write-Host $prompt -NoNewline -ForegroundColor $t.Alert
    
    $lastW = [Console]::WindowWidth
    $lastH = [Console]::WindowHeight
    
    $inputBuffer = ""
    while ($true) {
        try {
            if ($lastW -ne [Console]::WindowWidth -or $lastH -ne [Console]::WindowHeight) {
                return "RESIZE"
            }
            if ([Console]::KeyAvailable) {
                $keyInfo = [Console]::ReadKey($true)
                if ($keyInfo.Key -eq [ConsoleKey]::Enter) {
                    Write-Host ""
                    return $inputBuffer.ToUpper().Trim()
                } elseif ($keyInfo.Key -eq [ConsoleKey]::Backspace) {
                    if ($inputBuffer.Length -gt 0) {
                        $inputBuffer = $inputBuffer.Substring(0, $inputBuffer.Length - 1)
                        try { [Console]::CursorLeft = [Console]::CursorLeft - 1; Write-Host " " -NoNewline; [Console]::CursorLeft = [Console]::CursorLeft - 1 } catch {}
                    }
                } else {
                    $char = $keyInfo.KeyChar
                    if ([char]::IsControl($char) -eq $false) {
                        $inputBuffer += $char
                        Write-Host $char -NoNewline -ForegroundColor $t.Alert
                    }
                }
            }
        } catch {
            $in = [Console]::ReadLine()
            if ($null -eq $in) { return "" } else { return $in.ToUpper().Trim() }
        }
        Start-Sleep -Milliseconds 15
    }
}'''

content = re.sub(search_func, replace_func, content, flags=re.MULTILINE | re.DOTALL)

with open(file_path, 'w', encoding='utf-8-sig') as f:
    f.write(content)
print("Updated successfully")
