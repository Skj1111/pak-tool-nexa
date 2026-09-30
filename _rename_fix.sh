#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  FILENAME AUTO-CLEAN FIX"
echo "════════════════════════════════════════════════"
echo ""

cp telegram_bot.py telegram_bot.py.before_rename

python3 << 'PYEOF'
import re

with open('telegram_bot.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Add auto-clean filename in document_handler
if '# AUTO-CLEAN FILENAME' not in content:
    pattern = r'(    file_name = doc\.file_name or "unknown"\n    file_size = doc\.file_size or 0)'
    replacement = (
        r'\1\n'
        '\n'
        '    # ═══ AUTO-CLEAN FILENAME ═══\n'
        '    import re as _re\n'
        '    file_name = _re.sub(r\' \\(\\d+\\)\', \'\', file_name)\n'
        '    # ═════════════════════════════'
    )
    content = re.sub(pattern, replacement, content, count=1)
    print("✓ Auto-clean filename added")
else:
    print("⚠ Already present")

with open('telegram_bot.py', 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

# Syntax check
python -m py_compile telegram_bot.py && echo "✓ Bot compiles" || echo "✗ ERROR"

echo ""
echo "════════════════════════════════════════════════"
echo "✓ DONE"
echo "════════════════════════════════════════════════"

