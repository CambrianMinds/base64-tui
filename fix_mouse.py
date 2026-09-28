import sys

file_path = r'D:\tools\cambriansystems-tui\cambriansystems-tui.ps1'
with open(file_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

import re

# Find the ConsoleMouseHelper class block
pattern = re.compile(r'(public class ConsoleMouseHelper \{.*?\n\})', re.DOTALL)

new_class = '''public class ConsoleMouseHelper {
    private const int STD_INPUT_HANDLE = -10;
    private const int STD_OUTPUT_HANDLE = -11;
    private const uint ENABLE_MOUSE_INPUT = 0x0010;
    private const uint ENABLE_EXTENDED_FLAGS = 0x0080;
    private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
    private const uint ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;
    private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

    private static uint _origInMode;
    private static uint _origOutMode;
    private static bool _initialized = false;

    public static bool EnableMouse() {
        try {
            IntPtr hIn = GetStdHandle(STD_INPUT_HANDLE);
            IntPtr hOut = GetStdHandle(STD_OUTPUT_HANDLE);
            if (!GetConsoleMode(hIn, out _origInMode)) return false;
            if (!GetConsoleMode(hOut, out _origOutMode)) return false;
            
            uint newInMode = (_origInMode | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS) & ~(ENABLE_QUICK_EDIT_MODE | ENABLE_VIRTUAL_TERMINAL_INPUT);
            uint newOutMode = _origOutMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            
            bool ok1 = SetConsoleMode(hIn, newInMode);
            bool ok2 = SetConsoleMode(hOut, newOutMode);
            
            _initialized = ok1 && ok2;
            return _initialized;
        } catch {
            return false;
        }
    }

    public static void DisableMouse() {
        if (_initialized) {
            try {
                SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), _origInMode);
                SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), _origOutMode);
                _initialized = false;
            } catch {}
        }
    }
}'''

content = pattern.sub(new_class, content, count=1)

with open(file_path, 'w', encoding='utf-8-sig') as f:
    f.write(content)
print("Updated successfully")
