import sys
import re

file_path = r'D:\tools\cambriansystems-tui\cambriansystems-tui.ps1'
with open(file_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

# 1. Disable clickability
content = content.replace('[ConsoleMouseHelper]::EnableMouse()', '# disabled')
content = content.replace('Write-Host "$ESC[?1000h$ESC[?1006h" -NoNewline', '# disabled')
content = content.replace('Write-Host "$ESC[?1000l$ESC[?1006l" -NoNewline', '# disabled')
content = content.replace('[ConsoleMouseHelper]::DisableMouse()', '# disabled')

# 2. Fix dynamic width
# For Draw-Box
box_search = r'''    \ = 84
    try \{
        \ = \[Math\]::Min\(84, \[Console\]::WindowWidth - 2\)
    \} catch \{\}'''
box_replace = '''    try {
         = [Console]::WindowWidth - 2
    } catch {  = 84 }'''
content = re.sub(box_search, box_replace, content)

# For Draw-Header
head_search = r'''    \ = 84
    try \{
        if \(\[Console\]::WindowWidth -gt 84\) \{ \ = \[Console\]::WindowWidth \}
    \} catch \{\}'''
head_replace = '''    try {
         = [Console]::WindowWidth
    } catch {  = 84 }'''
content = re.sub(head_search, head_replace, content)

# For Draw-StatusBar
stat_search = r'''    \ = 84
    try \{
        if \(\[Console\]::WindowWidth -gt 84\) \{ \ = \[Console\]::WindowWidth \}
    \} catch \{\}'''
stat_replace = '''    try {
         = [Console]::WindowWidth
    } catch {  = 84 }'''
content = re.sub(stat_search, stat_replace, content)

# 3. Fix QR Code block drawing
qr_search = r'''Write-Host \(\[char\]0x2588 \+ \[char\]0x2588\) -NoNewline -ForegroundColor Black -BackgroundColor Black'''
qr_replace = '''Write-Host "  " -NoNewline -BackgroundColor Black'''
content = re.sub(qr_search, qr_replace, content)

with open(file_path, 'w', encoding='utf-8-sig') as f:
    f.write(content)
print("Updated successfully")
