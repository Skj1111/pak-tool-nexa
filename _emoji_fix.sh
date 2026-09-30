#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  EMOJI UPDATE"
echo "════════════════════════════════════════════════"
echo ""

python3 << 'PYEOF'
with open('telegram_bot.py', 'r', encoding='utf-8') as f:
    content = f.read()

# ═══ 1. Update main keyboard with emojis ═══
old_kb = '''def main_keyboard():
    kb = [
        [KeyboardButton("UNPACK"), KeyboardButton("INJECT")],
        [KeyboardButton("REPACK FULL"), KeyboardButton("REPACK TO PATH")],
        [KeyboardButton("PROTECT SM4"), KeyboardButton("DELETE")],
        [KeyboardButton("COMPILE LUA"), KeyboardButton("DECOMPILE LUA")],
        [KeyboardButton("THEME"), KeyboardButton("FAST MODE")],
        [KeyboardButton("STATUS"), KeyboardButton("HELP")],
    ]
    return ReplyKeyboardMarkup(kb, resize_keyboard=True)'''

new_kb = '''def main_keyboard():
    kb = [
        [KeyboardButton("📦 UNPACK"), KeyboardButton("💉 INJECT")],
        [KeyboardButton("🔨 REPACK FULL"), KeyboardButton("📁 REPACK TO PATH")],
        [KeyboardButton("🔐 PROTECT SM4"), KeyboardButton("🗑️ DELETE")],
        [KeyboardButton("🧪 COMPILE LUA"), KeyboardButton("🔬 DECOMPILE LUA")],
        [KeyboardButton("🎨 THEME"), KeyboardButton("⚡ FAST MODE")],
        [KeyboardButton("📊 STATUS"), KeyboardButton("📋 HELP")],
    ]
    return ReplyKeyboardMarkup(kb, resize_keyboard=True)'''

if old_kb in content:
    content = content.replace(old_kb, new_kb, 1)
    print("✓ Keyboard emojis added")
else:
    print("⚠ Keyboard pattern not found")

# ═══ 2. Update cmd_start messages ═══
content = content.replace(
    '"NEXA CHEAT BOT\\n--------------------\\n\\nWelcome, Owner!\\n\\nUse buttons below."',
    '"⚡ NEXA CHEAT BOT ⚡\\n━━━━━━━━━━━━━━━━━━━━\\n\\n🎩 Welcome, Owner!\\n\\n👇 Use buttons below"'
)
content = content.replace(
    '"NEXA CHEAT BOT\\n--------------------\\n\\nWelcome back!\\n\\nUse buttons below."',
    '"⚡ NEXA CHEAT BOT ⚡\\n━━━━━━━━━━━━━━━━━━━━\\n\\n🎩 Welcome back!\\n\\n👇 Use buttons below"'
)

# ═══ 3. Update help message ═══
old_help = '''"NEXA CHEAT BOT\\n--------------------\\n\\n"
        "/start - Menu\\n/status - Status\\n/paks - PAK list\\n/help - Help\\n\\n"
        "OWNER:\\n/pending\\n/allow <id>\\n/deny <id>\\n/allowed"'''
new_help = '''"⚡ NEXA CHEAT BOT ⚡\\n━━━━━━━━━━━━━━━━━━━━\\n\\n"
        "📋 COMMANDS:\\n"
        "▶️ /start  — Menu\\n"
        "📊 /status — Status\\n"
        "📦 /paks   — PAK list\\n"
        "📋 /help   — Help\\n\\n"
        "👑 OWNER:\\n"
        "📥 /pending       — New requests\\n"
        "✅ /allow <id>    — Allow user\\n"
        "❌ /deny <id>     — Deny user\\n"
        "📋 /allowed       — List users"'''
if old_help in content:
    content = content.replace(old_help, new_help, 1)
    print("✓ Help message emojis added")

# ═══ 4. Update status message ═══
old_status = '''msg = "STATUS\\n--------------------\\nPAK: {}\\nResults: {}\\nTime: {}".format(
        pak_count, result_count, datetime.now().strftime('%H:%M:%S'))'''
new_status = '''msg = "📊 STATUS\\n━━━━━━━━━━━━━━━━━━━━\\n\\n📦 PAK: {}\\n✅ Results: {}\\n⏰ Time: {}".format(
        pak_count, result_count, datetime.now().strftime('%H:%M:%S'))'''
if old_status in content:
    content = content.replace(old_status, new_status, 1)
    print("✓ Status message emojis added")

# ═══ 5. Update pak list message ═══
old_paks = '''msg = "PAK FILES:\\n--------------------\\n"
    for i, p in enumerate(paks, 1):
        msg += "{}. {} ({})\\n".format(i, p.name, human_size(p.stat().st_size))'''
new_paks = '''msg = "📦 PAK FILES:\\n━━━━━━━━━━━━━━━━━━━━\\n\\n"
    for i, p in enumerate(paks, 1):
        msg += "▶️ {}. {} ({})\\n".format(i, p.name, human_size(p.stat().st_size))'''
if old_paks in content:
    content = content.replace(old_paks, new_paks, 1)
    print("✓ PAK list emojis added")

# ═══ 6. Update all feature "Select PAK" messages ═══
content = content.replace(
    '"Select PAK to UNPACK:"',
    '"📦 Select PAK to UNPACK:"'
)
content = content.replace(
    '"Select PAK to INJECT:"',
    '"💉 Select PAK to INJECT:"'
)
content = content.replace(
    '"Select PAK for REPACK:"',
    '"🔨 Select PAK for REPACK:"'
)
content = content.replace(
    '"Select PAK:"',
    '"📁 Select PAK:"'
)
content = content.replace(
    '"Select PAK to PROTECT:"',
    '"🔐 Select PAK to PROTECT:"'
)
content = content.replace(
    '"Select folder:"',
    '"🗑️ Select folder:"'
)
content = content.replace(
    '"Select THEME:"',
    '"🎨 Select THEME:"'
)

# ═══ 7. Update FAST MODE message ═══
content = content.replace(
    '"FAST MODE\\n--------------------\\nCurrent: "',
    '"⚡ FAST MODE\\n━━━━━━━━━━━━━━━━━━━━\\n\\n📊 Current: "'
)

# ═══ 8. Update "No PAK files" messages ═══
content = content.replace(
    '"PAK folder khaali"',
    '"📭 PAK folder khaali"'
)
content = content.replace(
    '"PAK TOOL/PAK khaali"',
    '"📭 PAK TOOL/PAK khaali"'
)
content = content.replace(
    '"No PAK files"',
    '"📭 No PAK files"'
)
content = content.replace(
    '"LUA TOOL/INPUT khaali"',
    '"📭 LUA TOOL/INPUT khaali"'
)

# ═══ 9. Update error/success messages ═══
content = content.replace(
    '"Access Denied"',
    '"❌ Access Denied"'
)
content = content.replace(
    '"Not found"',
    '"❌ Not found"'
)
content = content.replace(
    '"Cancelled"',
    '"❌ Cancelled"'
)
content = content.replace(
    '"Access denied"',
    '"❌ Access denied"'
)

# ═══ 10. Update "User ALLOWED/DENIED" messages ═══
content = content.replace(
    '"User ALLOWED\\nID: " + str(uid)',
    '"✅ User ALLOWED\\n🆔 ID: " + str(uid)'
)
content = content.replace(
    '"User DENIED\\nID: " + str(uid)',
    '"❌ User DENIED\\n🆔 ID: " + str(uid)'
)

# ═══ 11. Update ACCESS REQUEST messages ═══
content = content.replace(
    '"NEW ACCESS REQUEST\\n--------------------\\n\\n"',
    '"🔔 NEW ACCESS REQUEST\\n━━━━━━━━━━━━━━━━━━━━\\n\\n"'
)
content = content.replace(
    '"ACCESS REQUEST SENT\\n--------------------\\n\\n"',
    '"📩 ACCESS REQUEST SENT\\n━━━━━━━━━━━━━━━━━━━━\\n\\n"'
)

# ═══ 12. Update USERS list ═══
content = content.replace(
    'msg = "USERS\\n--------------------\\n\\nOwner: " + str(OWNER_ID) + "\\n\\n"',
    'msg = "👥 USERS\\n━━━━━━━━━━━━━━━━━━━━\\n\\n👑 Owner: " + str(OWNER_ID) + "\\n\\n"'
)
content = content.replace(
    '"ALLOWED ({}):\\n"',
    '"✅ ALLOWED ({}):\\n"'
)
content = content.replace(
    '"ALLOWED: none\\n"',
    '"✅ ALLOWED: none\\n"'
)
content = content.replace(
    '"PENDING ({}):\\n"',
    '"⏳ PENDING ({}):\\n"'
)
content = content.replace(
    '"PENDING: none\\n"',
    '"⏳ PENDING: none\\n"'
)

# ═══ 13. Update PENDING REQUESTS ═══
content = content.replace(
    'msg = "PENDING REQUESTS:\\n--------------------\\n"',
    'msg = "⏳ PENDING REQUESTS:\\n━━━━━━━━━━━━━━━━━━━━\\n"'
)
content = content.replace(
    'msg += "\\nID: " + str(uid)',
    'msg += "\\n🆔 ID: " + str(uid)'
)
content = content.replace(
    'msg += "\\nName: " + info.get',
    'msg += "\\n👤 Name: " + info.get'
)

# ═══ 14. Update UPLOADED message ═══
content = content.replace(
    '"UPLOADED\\n--------------------\\n"\n            "File: "',
    '"✅ UPLOADED\\n━━━━━━━━━━━━━━━━━━━━\\n\\n📄 File: "'
)
content = content.replace(
    '"Size: " + human_size(file_size) + "\\n"\n            "Path: "',
    '"📊 Size: " + human_size(file_size) + "\\n"\n            "📁 Path: "'
)

# ═══ 15. Update all "Downloading" messages ═══
content = content.replace(
    '"Downloading " + file_name + "..."',
    '"📥 Downloading " + file_name + "..."'
)

# ═══ 16. Update all "Starting" messages ═══
content = content.replace(
    '"Starting: " + title + "..."',
    '"⏳ Starting: " + title + "..."'
)

# ═══ 17. Update "IN PROGRESS" ═══
content = content.replace(
    '"IN PROGRESS: " + title + "\\n"',
    '"⏳ IN PROGRESS: " + title + "\\n"'
)
content = content.replace(
    '"Progress: [" + bar + "]\\n"',
    '"📊 Progress: [" + bar + "]\\n"'
)
content = content.replace(
    '"Files: " + str(cur) + "/" + str(tot) + "\\n"',
    '"📁 Files: " + str(cur) + "/" + str(tot) + "\\n"'
)
content = content.replace(
    '"Elapsed: " + str(elapsed // 60) + "m " + str(elapsed % 60) + "s"',
    '"⏱️ Elapsed: " + str(elapsed // 60) + "m " + str(elapsed % 60) + "s"'
)
content = content.replace(
    'msg += "\\nItem: " + item[:50]',
    'msg += "\\n📄 Item: " + item[:50]'
)

# ═══ 18. Update COMPLETE messages ═══
content = content.replace(
    '"UNPACK COMPLETE\\nZIP upar bheji"',
    '"✅ UNPACK COMPLETE\\n📥 ZIP upar bheji"'
)
content = content.replace(
    '"REPACK COMPLETE\\nPAK upar bheji"',
    '"✅ REPACK COMPLETE\\n📥 PAK upar bheji"'
)
content = content.replace(
    '"INJECT COMPLETE\\nPAK upar bheji"',
    '"✅ INJECT COMPLETE\\n📥 PAK upar bheji"'
)
content = content.replace(
    '"PROTECTED\\nPAK upar bheji"',
    '"✅ PROTECTED\\n📥 PAK upar bheji"'
)
content = content.replace(
    '"COMPILE COMPLETE\\nFiles upar bheji"',
    '"✅ COMPILE COMPLETE\\n📥 Files upar bheji"'
)
content = content.replace(
    '"DECOMPILE COMPLETE\\nFiles upar bheji"',
    '"✅ DECOMPILE COMPLETE\\n📥 Files upar bheji"'
)

# ═══ 19. Update "Creating ZIP" ═══
content = content.replace(
    '"Creating ZIP..."',
    '"🗜️ Creating ZIP..."'
)

# ═══ 20. Update "Uploading PAK" ═══
content = content.replace(
    '"Uploading PAK..."',
    '"📤 Uploading PAK..."'
)
content = content.replace(
    '"Uploading PAK (" + pak_size + ")..."',
    '"📤 Uploading PAK (" + pak_size + ")..."'
)

# ═══ 21. Update "Repacking..." messages ═══
content = content.replace(
    '"Repacking..."',
    '"⏳ Repacking..."'
)
content = content.replace(
    '"Injecting..."',
    '"⏳ Injecting..."'
)

# ═══ 22. Update "files received" ═══
content = content.replace(
    '"{} files received\\n\\nAb target path bhejo:\\n"',
    '"📁 {} files received\\n\\n🎯 Ab target path bhejo:\\n"'
)

# ═══ 23. Update "File {}: {}" ═══
content = content.replace(
    '"File {}: {}\\nAur bhejo ya /done bhejo"',
    '"📎 File {}: {}\\n▶️ Aur bhejo ya /done bhejo"'
)

# ═══ 24. Update "Files bhejo" ═══
content = content.replace(
    '"Files bhejo (lua, uasset, uexp)\\n\\nDone hone pe /done bhejo"',
    '"📎 Files bhejo (lua, uasset, uexp)\\n\\n✅ Done hone pe /done bhejo"'
)

# ═══ 25. Update REPACK TO PATH welcome ═══
content = content.replace(
    '"REPACK TO PATH\\n--------------------\\n\\n"',
    '"📁 REPACK TO PATH\\n━━━━━━━━━━━━━━━━━━━━\\n\\n"'
)

# ═══ 26. Update DELETE message ═══
content = content.replace(
    '"Deleted: " + folder_name',
    '"✅ Deleted: " + folder_name'
)
content = content.replace(
    '"THEME: " + theme',
    '"🎨 THEME: " + theme'
)
content = content.replace(
    '"FAST MODE: " + ("ON" if new == "1" else "OFF")',
    '"⚡ FAST MODE: " + ("ON 🔥" if new == "1" else "OFF 🐢")'
)

# ═══ 27. Update FAILED messages ═══
content = content.replace(
    '"FAILED\\n\\n"',
    '"❌ FAILED\\n\\n"'
)
content = content.replace(
    '"COMPILE FAILED\\n"',
    '"❌ COMPILE FAILED\\n"'
)
content = content.replace(
    '"DECOMPILE FAILED\\n"',
    '"❌ DECOMPILE FAILED\\n"'
)
content = content.replace(
    '"ZIP too large"',
    '"⚠️ ZIP too large"'
)
content = content.replace(
    '"Send failed\\nPAK TOOL/RESULT/"',
    '"❌ Send failed\\n📁 PAK TOOL/RESULT/"'
)

# ═══ 28. Update "Result nahi mila" ═══
content = content.replace(
    '"Result nahi mila"',
    '"❌ Result nahi mila"'
)
content = content.replace(
    '"Result PAK nahi mila"',
    '"❌ Result PAK nahi mila"'
)
content = content.replace(
    '"Output folder nahi mila"',
    '"❌ Output folder nahi mila"'
)
content = content.replace(
    '"Koi file nahi bheji"',
    '"❌ Koi file nahi bheji"'
)
content = content.replace(
    '"Path khaali hai"',
    '"❌ Path khaali hai"'
)

with open('telegram_bot.py', 'w', encoding='utf-8') as f:
    f.write(content)

print()
print("=" * 60)
print("✓ EMOJI UPDATE DONE")
print("=" * 60)
PYEOF

# Syntax check
python -m py_compile telegram_bot.py && echo "✓ Bot compiles!" || echo "✗ ERROR"

echo ""
echo "════════════════════════════════════════════════"
echo "✓ DONE"
echo "════════════════════════════════════════════════"

