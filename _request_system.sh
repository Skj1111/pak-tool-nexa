#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  NEXA CHEAT - REQUEST SYSTEM"
echo "════════════════════════════════════════════════"
echo ""

python3 << 'PYEOF'
import re

with open('telegram_bot.py', 'r', encoding='utf-8') as f:
    content = f.read()

# ═══ 1. Permission helpers ═══
perm_code = '''
# ═══════════════════════════════════════════════════════════════════════════
#  REQUEST / PERMISSION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════

PERMISSION_FILE = Path.home() / ".nexa_allowed_users"
PENDING_FILE = Path.home() / ".nexa_pending_users"


def _load_allowed():
    allowed = set()
    try:
        if PERMISSION_FILE.exists():
            for line in PERMISSION_FILE.read_text(encoding='utf-8').splitlines():
                line = line.strip()
                if line and not line.startswith('#'):
                    try:
                        allowed.add(int(line))
                    except ValueError:
                        pass
    except Exception:
        pass
    return allowed


def _save_allowed(allowed):
    try:
        out = "# NEXA CHEAT - Allowed Users\\n"
        out += "\\n".join(str(x) for x in sorted(allowed))
        out += "\\n"
        PERMISSION_FILE.write_text(out, encoding='utf-8')
    except Exception as e:
        logger.error("Save allowed error: %s", e)


def _load_pending():
    """Load pending requests: {user_id: {name, username}}"""
    pending = {}
    try:
        if PENDING_FILE.exists():
            for line in PENDING_FILE.read_text(encoding='utf-8').splitlines():
                line = line.strip()
                if line and not line.startswith('#') and '|' in line:
                    parts = line.split('|', 2)
                    uid = int(parts[0])
                    name = parts[1] if len(parts) > 1 else ''
                    uname = parts[2] if len(parts) > 2 else ''
                    pending[uid] = {'name': name, 'username': uname}
    except Exception:
        pass
    return pending


def _save_pending(pending):
    try:
        out = "# Pending Requests\\n"
        for uid, info in pending.items():
            out += "{}|{}|{}\\n".format(uid, info.get('name', ''), info.get('username', ''))
        PENDING_FILE.write_text(out, encoding='utf-8')
    except Exception as e:
        logger.error("Save pending error: %s", e)


def add_allowed(user_id):
    allowed = _load_allowed()
    allowed.add(int(user_id))
    _save_allowed(allowed)


def remove_allowed(user_id):
    allowed = _load_allowed()
    allowed.discard(int(user_id))
    _save_allowed(allowed)


def add_pending(user_id, name='', username=''):
    pending = _load_pending()
    pending[int(user_id)] = {'name': name, 'username': username}
    _save_pending(pending)


def remove_pending(user_id):
    pending = _load_pending()
    pending.pop(int(user_id), None)
    _save_pending(pending)


def is_owner(user_id):
    return user_id == OWNER_ID


def is_allowed(user_id):
    if user_id == OWNER_ID:
        return True
    return user_id in _load_allowed()

'''

# Insert after logger
if 'REQUEST / PERMISSION SYSTEM' not in content:
    marker = 'logger = logging.getLogger(__name__)'
    content = content.replace(marker, marker + "\n" + perm_code, 1)
    print("✓ Permission system added")

# ═══ 2. OWNER_ID set ═══
content = content.replace('ADMIN_ID = 123456789', 'OWNER_ID = 5289093650')
content = content.replace('ADMIN_ID = 5289093650', 'OWNER_ID = 5289093650')
print("✓ OWNER_ID = 5289093650")

# ═══ 3. Remove old is_admin ═══
content = re.sub(
    r'def is_admin\(user_id\):\s*\n\s*return user_id == ADMIN_ID',
    '',
    content
)
print("✓ Old is_admin removed")

# ═══ 4. Replace is_admin calls ═══
content = content.replace(
    'if not is_admin(update.effective_user.id):',
    'if not is_allowed(update.effective_user.id):'
)
content = content.replace(
    'if not is_admin(update.callback_query.from_user.id):',
    'if not is_allowed(update.callback_query.from_user.id):'
)
content = content.replace(
    'if not is_admin(query.from_user.id):',
    'if not is_allowed(query.from_user.id):'
)
print("✓ is_admin → is_allowed")

# ═══ 5. /start — auto request system ═══
old_start = '''async def cmd_start(update, context):
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text(
            "ACCESS DENIED\\n"
            "--------------------\\n"
            "Tera ID: " + str(update.effective_user.id) + "\\n\\n"
            "Owner se permission maango."
        )
        return
    await update.message.reply_text(
        "NEXA CHEAT BOT\\n"
        "--------------------\\n\\n"
        "Welcome! Use buttons below.",
        reply_markup=main_keyboard()
    )'''

new_start = '''async def cmd_start(update, context):
    user = update.effective_user
    uid = user.id

    # Owner — full access
    if is_owner(uid):
        await update.message.reply_text(
            "NEXA CHEAT BOT\\n"
            "--------------------\\n\\n"
            "Welcome, Owner!\\n\\n"
            "Use buttons below.",
            reply_markup=main_keyboard()
        )
        return

    # Already allowed
    if is_allowed(uid):
        await update.message.reply_text(
            "NEXA CHEAT BOT\\n"
            "--------------------\\n\\n"
            "Welcome back!\\n\\n"
            "Use buttons below.",
            reply_markup=main_keyboard()
        )
        return

    # NEW USER — send request to owner
    name = user.full_name or 'Unknown'
    uname = user.username or ''

    add_pending(uid, name, uname)

    # Notify owner
    try:
        notify = (
            "NEW ACCESS REQUEST\\n"
            "--------------------\\n\\n"
            "Name: " + name + "\\n"
            "Username: @" + (uname if uname else "(none)") + "\\n"
            "ID: " + str(uid) + "\\n\\n"
            "Allow karne ke liye /allow " + str(uid) + "\\n"
            "Deny karne ke liye /deny " + str(uid)
        )
        await context.bot.send_message(chat_id=OWNER_ID, text=notify)
    except Exception as e:
        logger.error("Notify owner error: %s", e)

    await update.message.reply_text(
        "ACCESS REQUEST SENT\\n"
        "--------------------\\n\\n"
        "Tera ID: " + str(uid) + "\\n\\n"
        "Owner ko request bhej di gayi.\\n"
        "Approval ka intezaar karo."
    )'''

if old_start in content:
    content = content.replace(old_start, new_start, 1)
    print("✓ cmd_start — auto request added")

# ═══ 6. Owner commands ═══
owner_cmds = '''
# ═══════════════════════════════════════════════════════════════════════════
#  OWNER COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

async def cmd_allow(update, context):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("Owner only")
        return

    if not context.args:
        await update.message.reply_text("Usage: /allow <user_id>")
        return

    try:
        uid = int(context.args[0])
    except ValueError:
        await update.message.reply_text("Invalid ID")
        return

    add_allowed(uid)
    remove_pending(uid)

    await update.message.reply_text(
        "User ALLOWED\\n"
        "ID: " + str(uid) + "\\n\\n"
        "Ab wo bot use kar sakta hai."
    )

    # Notify user
    try:
        await context.bot.send_message(
            chat_id=uid,
            text="ACCESS GRANTED\\n--------------------\\n\\nAb tum bot use kar sakte ho.\\n/start bhejo"
        )
    except Exception:
        pass


async def cmd_deny(update, context):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("Owner only")
        return

    if not context.args:
        await update.message.reply_text("Usage: /deny <user_id>")
        return

    try:
        uid = int(context.args[0])
    except ValueError:
        await update.message.reply_text("Invalid ID")
        return

    if uid == OWNER_ID:
        await update.message.reply_text("Owner ko deny nahi kar sakte")
        return

    remove_allowed(uid)
    remove_pending(uid)

    await update.message.reply_text(
        "User DENIED\\n"
        "ID: " + str(uid)
    )

    try:
        await context.bot.send_message(
            chat_id=uid,
            text="ACCESS DENIED\\n--------------------\\n\\nOwner ne permission nahi di."
        )
    except Exception:
        pass


async def cmd_allowed(update, context):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("Owner only")
        return

    allowed = _load_allowed()
    pending = _load_pending()

    msg = "USERS\\n--------------------\\n\\n"
    msg += "Owner: " + str(OWNER_ID) + "\\n\\n"

    if allowed:
        msg += "ALLOWED ({}):\\n".format(len(allowed))
        for uid in sorted(allowed):
            msg += "  " + str(uid) + "\\n"
    else:
        msg += "ALLOWED: none\\n"

    msg += "\\n"

    if pending:
        msg += "PENDING ({}):\\n".format(len(pending))
        for uid, info in pending.items():
            msg += "  " + str(uid) + " - " + info.get('name', '?') + "\\n"
    else:
        msg += "PENDING: none\\n"

    await update.message.reply_text(msg)


async def cmd_pending(update, context):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("Owner only")
        return

    pending = _load_pending()
    if not pending:
        await update.message.reply_text("No pending requests")
        return

    msg = "PENDING REQUESTS:\\n--------------------\\n"
    for uid, info in pending.items():
        msg += "\\nID: " + str(uid)
        msg += "\\nName: " + info.get('name', '?')
        msg += "\\nUser: @" + (info.get('username', '') or '(none)')
        msg += "\\n/allow " + str(uid) + "  OR  /deny " + str(uid)
        msg += "\\n"
    await update.message.reply_text(msg)

'''

# Insert before cmd_start
if 'async def cmd_allow' not in content:
    marker = 'async def cmd_start(update, context):'
    if marker in content:
        content = content.replace(marker, owner_cmds + "\n" + marker, 1)
        print("✓ Owner commands added")

# ═══ 7. Register handlers ═══
old_reg = 'app.add_handler(CommandHandler("start", cmd_start))'
new_reg = '''    app.add_handler(CommandHandler("allow", cmd_allow))
    app.add_handler(CommandHandler("deny", cmd_deny))
    app.add_handler(CommandHandler("allowed", cmd_allowed))
    app.add_handler(CommandHandler("pending", cmd_pending))
    app.add_handler(CommandHandler("start", cmd_start))'''

if 'cmd_allow' in content and 'CommandHandler("allow"' not in content:
    content = content.replace(old_reg, new_reg, 1)
    print("✓ Handlers registered")

# ═══ 8. Help text ═══
old_help = '''"/help - Help"'''
new_help = '''"/help - Help\\n\\n"
        "OWNER:\\n"
        "/pending - New requests\\n"
        "/allow <id> - Allow\\n"
        "/deny <id> - Deny\\n"
        "/allowed - List"'''

if old_help in content and 'OWNER:' not in content:
    content = content.replace(old_help, new_help, 1)
    print("✓ Help updated")

# ═══ 9. Update main() print ═══
content = content.replace('print("Admin: {}".format(ADMIN_ID))',
                          'print("Owner: {}".format(OWNER_ID))')

with open('telegram_bot.py', 'w', encoding='utf-8') as f:
    f.write(content)

print()
print("=" * 60)
print("✓ REQUEST SYSTEM ADDED")
print("=" * 60)
PYEOF

echo ""
echo "════════════════════════════════════════════════"
echo "Syntax check:"
python -m py_compile telegram_bot.py && echo "✓ Bot compiles!" || echo "✗ ERROR"
echo "════════════════════════════════════════════════"

