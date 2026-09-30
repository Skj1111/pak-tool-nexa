#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  NEXA CHEAT — CLEAN + RESTART"
echo "════════════════════════════════════════════════"
echo ""

# 1. Bot band karo
echo "🛑 Stopping bot..."
pkill -f telegram_bot.py 2>/dev/null
sleep 2
echo "✓ Bot stopped"
echo ""

# 2. PAK TOOL/PAK clean
echo "🧹 Cleaning PAK TOOL/PAK..."
rm -f "PAK TOOL/PAK/"*.pak 2>/dev/null
echo "✓ PAK TOOL/PAK: $(ls 'PAK TOOL/PAK/' 2>/dev/null | wc -l) files"
echo ""

# 3. PAK TOOL/EDIT clean
echo "🧹 Cleaning PAK TOOL/EDIT..."
rm -rf "PAK TOOL/EDIT"/* 2>/dev/null
mkdir -p "PAK TOOL/EDIT"
echo "✓ PAK TOOL/EDIT: $(ls 'PAK TOOL/EDIT/' 2>/dev/null | wc -l) files"
echo ""

# 4. PAK TOOL/RESULT clean
echo "🧹 Cleaning PAK TOOL/RESULT..."
rm -rf "PAK TOOL/RESULT"/* 2>/dev/null
mkdir -p "PAK TOOL/RESULT"
echo "✓ PAK TOOL/RESULT: $(ls 'PAK TOOL/RESULT/' 2>/dev/null | wc -l) files"
echo ""

# 5. PAK folder clean
echo "🧹 Cleaning PAK..."
rm -f PAK/*.pak 2>/dev/null
echo "✓ PAK: $(ls PAK/ 2>/dev/null | wc -l) files"
echo ""

# 6. UNPACK folder clean
echo "🧹 Cleaning UNPACK..."
rm -rf UNPACK/* 2>/dev/null
echo "✓ UNPACK: $(ls UNPACK/ 2>/dev/null | wc -l) folders"
echo ""

# 7. REPACK folder clean
echo "🧹 Cleaning REPACK..."
rm -rf REPACK/* 2>/dev/null
echo "✓ REPACK: $(ls REPACK/ 2>/dev/null | wc -l) folders"
echo ""

# 8. RESULT folder clean
echo "🧹 Cleaning RESULT..."
rm -rf RESULT/* 2>/dev/null
echo "✓ RESULT: $(ls RESULT/ 2>/dev/null | wc -l) files"
echo ""

# 9. LUA TOOL clean
echo "🧹 Cleaning LUA TOOL..."
rm -rf "LUA TOOL/INPUT"/* 2>/dev/null
rm -rf "LUA TOOL/COMPILE"/* 2>/dev/null
rm -rf "LUA TOOL/DECOMPILE"/* 2>/dev/null
echo "✓ LUA TOOL/INPUT: $(ls 'LUA TOOL/INPUT/' 2>/dev/null | wc -l) files"
echo "✓ LUA TOOL/COMPILE: $(ls 'LUA TOOL/COMPILE/' 2>/dev/null | wc -l) files"
echo "✓ LUA TOOL/DECOMPILE: $(ls 'LUA TOOL/DECOMPILE/' 2>/dev/null | wc -l) files"
echo ""

# 10. LUA TOOL/TOOLS check (SAFE — delete nahi)
echo "🔍 LUA TOOL/TOOLS (safe):"
ls "LUA TOOL/TOOLS/" 2>/dev/null
echo ""

# 11. Final status
echo "════════════════════════════════════════════════"
echo "  FINAL STATUS"
echo "════════════════════════════════════════════════"
echo ""
echo "📁 PAK:              $(ls PAK/ 2>/dev/null | wc -l) files"
echo "📁 UNPACK:           $(ls UNPACK/ 2>/dev/null | wc -l) folders"
echo "📁 REPACK:           $(ls REPACK/ 2>/dev/null | wc -l) folders"
echo "📁 RESULT:           $(ls RESULT/ 2>/dev/null | wc -l) files"
echo "📁 PAK TOOL/PAK:     $(ls 'PAK TOOL/PAK/' 2>/dev/null | wc -l) files"
echo "📁 PAK TOOL/EDIT:    $(ls 'PAK TOOL/EDIT/' 2>/dev/null | wc -l) files"
echo "📁 PAK TOOL/RESULT:  $(ls 'PAK TOOL/RESULT/' 2>/dev/null | wc -l) files"
echo "📁 LUA TOOL/INPUT:   $(ls 'LUA TOOL/INPUT/' 2>/dev/null | wc -l) files"
echo "📁 LUA TOOL/COMPILE: $(ls 'LUA TOOL/COMPILE/' 2>/dev/null | wc -l) files"
echo "📁 LUA TOOL/TOOLS:   $(ls 'LUA TOOL/TOOLS/' 2>/dev/null | wc -l) files (safe)"
echo ""
echo "════════════════════════════════════════════════"
echo "✓ ALL CLEANED"
echo ""
echo "🚀 Ab bot chalao:"
echo "   python telegram_bot.py"
echo "════════════════════════════════════════════════"

