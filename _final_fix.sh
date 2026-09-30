#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

# Manual clean — abhi
rm -f "PAK TOOL/PAK/game_patch_4.6.0.21550.pak"
rm -f "PAK TOOL/PAK/game_patch_4.6.0.21552.pak"
rm -f "PAK TOOL/PAK/game_patch_4.6.0.21550.pak"

echo "✓ Purani PAK delete"
ls "PAK TOOL/PAK/"

# Bot restart
pkill -f telegram_bot.py 2>/dev/null
sleep 2

echo ""
echo "✓ Bot band — ab restart karo"
echo ""
echo "Next time:"
echo "  1. Nayi PAK bhejo"
echo "  2. Purani manually delete karo (ya bot se)"
echo "  3. REPACK TO PATH dabao"
echo "  4. Sirf nayi dikhegi"

