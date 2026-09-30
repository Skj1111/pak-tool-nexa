#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  FORCE CLEAN + RESTART"
echo "════════════════════════════════════════════════"
echo ""

# 1. Bot band karo
pkill -f telegram_bot.py 2>/dev/null
sleep 2
echo "✓ Bot stopped"

# 2. PAK TOOL/PAK clean
echo ""
echo "Before:"
ls "PAK TOOL/PAK/" 2>/dev/null
echo ""

# Backup first
mkdir -p ~/pak_backup
cp "PAK TOOL/PAK/"*.pak ~/pak_backup/ 2>/dev/null
echo "✓ Backup: ~/pak_backup/"

# Delete all PAK in PAK TOOL/PAK
rm -f "PAK TOOL/PAK/"*.pak
echo "✓ PAK TOOL/PAK cleaned"

# 3. PAK TOOL/EDIT clean
rm -rf "PAK TOOL/EDIT"/*
mkdir -p "PAK TOOL/EDIT"
echo "✓ PAK TOOL/EDIT cleaned"

# 4. PAK TOOL/RESULT clean
rm -rf "PAK TOOL/RESULT"/*
mkdir -p "PAK TOOL/RESULT"
echo "✓ PAK TOOL/RESULT cleaned"

# 5. PAK folder clean
rm -f PAK/*.pak
echo "✓ PAK cleaned"

# 6. UNPACK clean
rm -rf UNPACK/*
echo "✓ UNPACK cleaned"

# 7. LUA INPUT clean
rm -rf "LUA TOOL/INPUT"/*
echo "✓ LUA INPUT cleaned"

# 8. Verify code
echo ""
echo "=== Code check ==="
COUNT=$(grep -c "clean_pak_folder(keep_name" telegram_bot.py)
echo "clean_pak_folder calls: $COUNT"
echo "Expected: 4+ (INJECT, REPACK FULL, REPACK TO PATH, PROTECT)"

# 9. Syntax check
echo ""
python -m py_compile telegram_bot.py && echo "✓ Bot OK" || echo "✗ ERROR"

echo ""
echo "After:"
echo "  PAK TOOL/PAK: $(ls 'PAK TOOL/PAK/' 2>/dev/null | wc -l) files"
echo "  PAK TOOL/EDIT: $(ls 'PAK TOOL/EDIT/' 2>/dev/null | wc -l) files"
echo "  PAK: $(ls PAK/ 2>/dev/null | wc -l) files"
echo "  UNPACK: $(ls UNPACK/ 2>/dev/null | wc -l) folders"
echo ""
echo "════════════════════════════════════════════════"
echo "✓ ALL CLEANED — Bot restart karo"
echo "════════════════════════════════════════════════"

