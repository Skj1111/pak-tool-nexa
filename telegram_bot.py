#!/usr/bin/env python3
"""
⚡ NEXA CHEAT — TELEGRAM BOT ⚡
Complete: Auto-clean + Permission + All features + Progress + ZIP
"""
import os
import sys
import re
import time
import shutil
import zipfile
import logging
import asyncio
import subprocess
from pathlib import Path
from datetime import datetime

from progress_helper import progress_read
from telegram import (
    Update, InlineKeyboardButton, InlineKeyboardMarkup,
    ReplyKeyboardMarkup, KeyboardButton
)
from telegram.ext import (
    Application, CommandHandler, CallbackQueryHandler,
    MessageHandler, filters, ContextTypes
)

# ═══════════════════════════════════════════════════════════════════════════
#  CONFIG — APNI VALUES DAALO
# ═══════════════════════════════════════════════════════════════════════════

BOT_TOKEN = "8473659483:AAE5NOPOuz3iN0dQifBh4IvNfyuDCqaJOcw"
OWNER_ID = 6261701933

BASE_DIR = Path.home() / "pak-tool-nexa"
PAK_DIR = BASE_DIR / "PAK"
UNPACK_DIR = BASE_DIR / "UNPACK"
REPACK_DIR = BASE_DIR / "REPACK"
RESULT_DIR = BASE_DIR / "RESULT"
PAK_TOOL_DIR = BASE_DIR / "PAK TOOL"
LUA_DIR = BASE_DIR / "LUA TOOL"

for d in [PAK_DIR, UNPACK_DIR, REPACK_DIR, RESULT_DIR,
          PAK_TOOL_DIR / "PAK", PAK_TOOL_DIR / "EDIT", PAK_TOOL_DIR / "RESULT",
          LUA_DIR / "TOOLS", LUA_DIR / "INPUT",
          LUA_DIR / "COMPILE", LUA_DIR / "DECOMPILE"]:
    d.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.WARNING
)
logger = logging.getLogger(__name__)
logging.getLogger('httpx').setLevel(logging.WARNING)
logging.getLogger('telegram').setLevel(logging.WARNING)


# ═══════════════════════════════════════════════════════════════════════════
#  AUTO-CLEAN HELPERS
# ═══════════════════════════════════════════════════════════════════════════

def clean_folder(folder_path):
    try:
        if folder_path.exists():
            shutil.rmtree(folder_path)
    except Exception:
        pass
    folder_path.mkdir(parents=True, exist_ok=True)


def clean_edit_folder():
    clean_folder(PAK_TOOL_DIR / "EDIT")


def clean_lua_input():
    clean_folder(LUA_DIR / "INPUT")


def clean_unpack_folder(pak_name):
    clean_folder(UNPACK_DIR / Path(pak_name).stem)


def clean_result_pak(pak_name):
    try:
        old = PAK_TOOL_DIR / "RESULT" / pak_name
        if old.exists():
            old.unlink()
    except Exception:
        pass


def clean_pak_folder(keep_name=None):
    """Clean PAK TOOL/PAK folder — keep only selected."""
    try:
        for f in (PAK_TOOL_DIR / "PAK").glob("*.pak"):
            if keep_name and f.name == keep_name:
                continue
            try:
                f.unlink()
            except Exception:
                pass
    except Exception:
        pass


def clean_pak_dir(keep_name=None):
    """Clean PAK/ folder — keep only selected."""
    try:
        for f in PAK_DIR.glob("*.pak"):
            if keep_name and f.name == keep_name:
                continue
            try:
                f.unlink()
            except Exception:
                pass
    except Exception:
        pass


# ═══════════════════════════════════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════════════════════════════════

def clean_filename(name):
    if not name:
        return name
    return re.sub(r' \(\d+\)', '', name)


def human_size(size):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024.0:
            return "{:.2f} {}".format(size, unit)
        size /= 1024.0
    return "{:.2f} PB".format(size)


def run_script(script_name, args, timeout=7200):
    try:
        result = subprocess.run(
            [sys.executable, str(BASE_DIR / script_name)] + [str(a) for a in args],
            capture_output=True, text=True, timeout=timeout,
            cwd=str(BASE_DIR)
        )
        return result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired:
        return "", "TIMEOUT", -1
    except Exception as e:
        return "", str(e), -1


def parse_output(stdout):
    info = {}
    for line in stdout.splitlines():
        if ':' in line and not line.startswith(' ') and not line.startswith('Traceback'):
            key, _, val = line.partition(':')
            info[key.strip()] = val.strip()
    return info


def list_paks(folder):
    if not folder.exists():
        return []
    return sorted(folder.glob("*.pak"))


def zip_folder(folder_path, zip_path, max_size_mb=2000):
    try:
        zip_path.parent.mkdir(parents=True, exist_ok=True)
        if zip_path.exists():
            zip_path.unlink()
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for file in folder_path.rglob('*'):
                if file.is_file():
                    zf.write(file, file.relative_to(folder_path))
        return (zip_path.stat().st_size / (1024 * 1024)) <= max_size_mb
    except Exception as e:
        logger.error("Zip error: %s", e)
        return False


async def send_file(target, file_path, caption):
    try:
        with open(file_path, 'rb') as f:
            if hasattr(target, 'message') and target.message:
                await target.message.reply_document(
                    document=f, filename=file_path.name, caption=caption[:1000],
                    read_timeout=600, write_timeout=600, connect_timeout=60,
                )
            else:
                await target.reply_document(
                    document=f, filename=file_path.name, caption=caption[:1000],
                    read_timeout=600, write_timeout=600, connect_timeout=60,
                )
        return True
    except Exception as e:
        logger.error("Send error: %s", e)
        return False


def build_bar(current, total, width=20):
    if total <= 0:
        return "*" * width + " 0%"
    pct = min(100, int(100 * current / total))
    filled = int(width * current / total)
    return "#" * filled + "." * (width - filled) + " " + str(pct) + "%"


async def run_with_progress(query, script, args, title, timeout=7200):
    try:
        pf = Path.home() / ".nexa_progress"
        if pf.exists():
            pf.unlink()
    except Exception:
        pass

    await query.edit_message_text("⏳ Starting: " + title + "...")

    process = await asyncio.create_subprocess_exec(
        sys.executable, str(BASE_DIR / script),
        *[str(a) for a in args],
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        cwd=str(BASE_DIR)
    )

    last_text = ""
    start_time = int(time.time())

    while process.returncode is None:
        await asyncio.sleep(0.7)

        if time.time() - start_time > timeout:
            try:
                process.kill()
            except Exception:
                pass
            await query.edit_message_text("❌ TIMEOUT: " + title)
            return {}, "", "TIMEOUT", False

        data = progress_read()
        if data and data.get('STATUS') == 'running':
            cur = int(data.get('CURRENT', 0) or 0)
            tot = int(data.get('TOTAL', 0) or 0)
            item = data.get('CURRENT_ITEM', '')
            started = int(data.get('STARTED', start_time) or start_time)
            elapsed = int(time.time()) - started
            bar = build_bar(cur, tot)
            msg = (
                "⏳ IN PROGRESS: " + title + "\n"
                "------------------------------\n"
                "📊 Progress: [" + bar + "]\n"
                "📁 Files: " + str(cur) + "/" + str(tot) + "\n"
                "⏱️ Elapsed: " + str(elapsed // 60) + "m " + str(elapsed % 60) + "s"
            )
            if item:
                msg += "\n📄 Item: " + item[:50]
            if msg != last_text:
                last_text = msg
                try:
                    await query.edit_message_text(msg)
                except Exception:
                    pass

        try:
            await asyncio.wait_for(process.wait(), timeout=1)
        except asyncio.TimeoutError:
            pass

    stdout_b, stderr_b = await process.communicate()
    stdout = stdout_b.decode('utf-8', 'ignore')
    stderr = stderr_b.decode('utf-8', 'ignore')
    info = parse_output(stdout)
    return info, stdout, stderr, ('SUCCESS' in stdout)


# ═══════════════════════════════════════════════════════════════════════════
#  PERMISSION SYSTEM
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
        out = "# NEXA CHEAT - Allowed Users\n"
        out += "\n".join(str(x) for x in sorted(allowed)) + "\n"
        PERMISSION_FILE.write_text(out, encoding='utf-8')
    except Exception as e:
        logger.error("Save error: %s", e)


def _load_pending():
    pending = {}
    try:
        if PENDING_FILE.exists():
            for line in PENDING_FILE.read_text(encoding='utf-8').splitlines():
                line = line.strip()
                if line and not line.startswith('#') and '|' in line:
                    parts = line.split('|', 2)
                    try:
                        uid = int(parts[0])
                        pending[uid] = {
                            'name': parts[1] if len(parts) > 1 else '',
                            'username': parts[2] if len(parts) > 2 else ''
                        }
                    except ValueError:
                        pass
    except Exception:
        pass
    return pending


def _save_pending(pending):
    try:
        out = "# Pending\n"
        for uid, info in pending.items():
            out += "{}|{}|{}\n".format(uid, info.get('name', ''), info.get('username', ''))
        PENDING_FILE.write_text(out, encoding='utf-8')
    except Exception:
        pass


def add_allowed(uid):
    a = _load_allowed(); a.add(int(uid)); _save_allowed(a)


def remove_allowed(uid):
    a = _load_allowed(); a.discard(int(uid)); _save_allowed(a)


def add_pending(uid, name='', username=''):
    p = _load_pending()
    p[int(uid)] = {'name': name, 'username': username}
    _save_pending(p)


def remove_pending(uid):
    p = _load_pending()
    p.pop(int(uid), None)
    _save_pending(p)


def is_owner(uid):
    return uid == OWNER_ID


def is_allowed(uid):
    if uid == OWNER_ID:
        return True
    return uid in _load_allowed()


# ═══════════════════════════════════════════════════════════════════════════
#  KEYBOARDS
# ═══════════════════════════════════════════════════════════════════════════

def main_keyboard():
    kb = [
        [KeyboardButton("📦 UNPACK"), KeyboardButton("💉 INJECT")],
        [KeyboardButton("🔨 REPACK FULL"), KeyboardButton("📁 REPACK TO PATH")],
        [KeyboardButton("🔐 PROTECT SM4"), KeyboardButton("🗑️ DELETE")],
        [KeyboardButton("🧪 COMPILE LUA"), KeyboardButton("🔬 DECOMPILE LUA")],
        [KeyboardButton("🎨 THEME"), KeyboardButton("⚡ FAST MODE")],
        [KeyboardButton("📊 STATUS"), KeyboardButton("📋 HELP")],
    ]
    return ReplyKeyboardMarkup(kb, resize_keyboard=True)


def pak_selector(paks, prefix):
    kb = []
    for p in paks:
        kb.append([InlineKeyboardButton(
            "📦 {} ({})".format(p.name, human_size(p.stat().st_size)),
            callback_data="{}:{}".format(prefix, p.name)
        )])
    kb.append([InlineKeyboardButton("❌ Cancel", callback_data="cancel")])
    return InlineKeyboardMarkup(kb)


# ═══════════════════════════════════════════════════════════════════════════
#  OWNER COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

async def cmd_allow(update, context):
    if not is_owner(update.effective_user.id):
        await update.message.reply_text("👑 Owner only")
        return
    if not context.args:
        await update.message.reply_text("Usage: /allow <user_id>")
        return
    try:
        uid = int(context.args[0])
    except ValueError:
        await update.message.reply_text("❌ Invalid ID")
        return
    add_allowed(uid)
    remove_pending(uid)
    await update.message.reply_text("✅ User ALLOWED\n🆔 ID: " + str(uid))
    try:
        await context.bot.send_message(chat_id=uid,
            text="✅ ACCESS GRANTED\n\nAb tum bot use kar sakte ho. /start bhejo")
    except Exception:
        pass


async def cmd_deny(update, context):
    if not is_owner(update.effective_user.id):
        await update.message.reply_text("👑 Owner only")
        return
    if not context.args:
        await update.message.reply_text("Usage: /deny <user_id>")
        return
    try:
        uid = int(context.args[0])
    except ValueError:
        await update.message.reply_text("❌ Invalid ID")
        return
    if uid == OWNER_ID:
        await update.message.reply_text("❌ Owner ko deny nahi kar sakte")
        return
    remove_allowed(uid)
    remove_pending(uid)
    await update.message.reply_text("❌ User DENIED\n🆔 ID: " + str(uid))
    try:
        await context.bot.send_message(chat_id=uid,
            text="❌ ACCESS DENIED\n\nOwner ne permission nahi di.")
    except Exception:
        pass


async def cmd_allowed(update, context):
    if not is_owner(update.effective_user.id):
        await update.message.reply_text("👑 Owner only")
        return
    allowed = _load_allowed()
    pending = _load_pending()
    msg = "👥 USERS\n━━━━━━━━━━━━━━━━━━━━\n\n👑 Owner: " + str(OWNER_ID) + "\n\n"
    if allowed:
        msg += "✅ ALLOWED ({}):\n".format(len(allowed))
        for uid in sorted(allowed):
            msg += "  🆔 " + str(uid) + "\n"
    else:
        msg += "✅ ALLOWED: none\n"
    msg += "\n"
    if pending:
        msg += "⏳ PENDING ({}):\n".format(len(pending))
        for uid, info in pending.items():
            msg += "  🆔 " + str(uid) + " - " + info.get('name', '?') + "\n"
    else:
        msg += "⏳ PENDING: none\n"
    await update.message.reply_text(msg)


async def cmd_pending(update, context):
    if not is_owner(update.effective_user.id):
        await update.message.reply_text("👑 Owner only")
        return
    pending = _load_pending()
    if not pending:
        await update.message.reply_text("📭 No pending requests")
        return
    msg = "⏳ PENDING REQUESTS:\n━━━━━━━━━━━━━━━━━━━━\n"
    for uid, info in pending.items():
        msg += "\n🆔 ID: " + str(uid)
        msg += "\n👤 Name: " + info.get('name', '?')
        msg += "\n/allow " + str(uid) + "  OR  /deny " + str(uid)
        msg += "\n"
    await update.message.reply_text(msg)


# ═══════════════════════════════════════════════════════════════════════════
#  USER COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

async def cmd_start(update, context):
    user = update.effective_user
    uid = user.id

    if is_owner(uid):
        await update.message.reply_text(
            "⚡ NEXA CHEAT BOT ⚡\n━━━━━━━━━━━━━━━━━━━━\n\n🎩 Welcome, Owner!\n\n👇 Use buttons below",
            reply_markup=main_keyboard()
        )
        return

    if is_allowed(uid):
        await update.message.reply_text(
            "⚡ NEXA CHEAT BOT ⚡\n━━━━━━━━━━━━━━━━━━━━\n\n🎩 Welcome back!\n\n👇 Use buttons below",
            reply_markup=main_keyboard()
        )
        return

    name = user.full_name or 'Unknown'
    uname = user.username or ''
    add_pending(uid, name, uname)

    try:
        notify = (
            "🔔 NEW ACCESS REQUEST\n━━━━━━━━━━━━━━━━━━━━\n\n"
            "👤 Name: " + name + "\n"
            "🆔 ID: " + str(uid) + "\n\n"
            "/allow " + str(uid) + "  OR  /deny " + str(uid)
        )
        await context.bot.send_message(chat_id=OWNER_ID, text=notify)
    except Exception as e:
        logger.error("Notify error: %s", e)

    await update.message.reply_text(
        "📩 ACCESS REQUEST SENT\n━━━━━━━━━━━━━━━━━━━━\n\n"
        "🆔 Tera ID: " + str(uid) + "\n\n"
        "👑 Owner ko request bhej di. Approval ka wait karo."
    )


async def cmd_help(update, context):
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ Access denied")
        return
    await update.message.reply_text(
        "⚡ NEXA CHEAT BOT ⚡\n━━━━━━━━━━━━━━━━━━━━\n\n"
        "📋 COMMANDS:\n"
        "▶️ /start  — Menu\n"
        "📊 /status — Status\n"
        "📦 /paks   — PAK list\n"
        "📋 /help   — Help\n\n"
        "👑 OWNER:\n"
        "📥 /pending       — New requests\n"
        "✅ /allow <id>    — Allow user\n"
        "❌ /deny <id>     — Deny user\n"
        "📋 /allowed       — List users"
    )


async def cmd_status(update, context):
    if not is_allowed(update.effective_user.id):
        return
    pak_count = len(list(PAK_DIR.glob("*.pak")))
    result_count = len(list(RESULT_DIR.glob("*.pak")))
    msg = "📊 STATUS\n━━━━━━━━━━━━━━━━━━━━\n\n📦 PAK: {}\n✅ Results: {}\n⏰ Time: {}".format(
        pak_count, result_count, datetime.now().strftime('%H:%M:%S'))
    await update.message.reply_text(msg)


async def cmd_paks(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_DIR)
    if not paks:
        await update.message.reply_text("📭 No PAK files")
        return
    msg = "📦 PAK FILES:\n━━━━━━━━━━━━━━━━━━━━\n\n"
    for i, p in enumerate(paks, 1):
        msg += "▶️ {}. {} ({})\n".format(i, p.name, human_size(p.stat().st_size))
    await update.message.reply_text(msg)


# ═══════════════════════════════════════════════════════════════════════════
#  FEATURE HANDLERS
# ═══════════════════════════════════════════════════════════════════════════

async def feature_unpack(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_DIR)
    if not paks:
        context.user_data['awaiting'] = 'pak_for_unpack'
        await update.message.reply_text(
            "📭 PAK folder khaali\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📎 Ab .pak file bhejo\n"
            "✅ Complete hone pe bot UNPACK karega"
        )
        return
    await update.message.reply_text("📦 Select PAK to UNPACK:", reply_markup=pak_selector(paks, "unpack"))


async def feature_inject(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_TOOL_DIR / "PAK")
    if not paks:
        context.user_data['awaiting'] = 'pak_for_inject'
        await update.message.reply_text(
            "📭 PAK TOOL/PAK khaali\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📎 Ab .pak file bhejo\n"
            "✅ Complete hone pe bot INJECT flow chalu karega"
        )
        return
    await update.message.reply_text("💉 Select PAK to INJECT:", reply_markup=pak_selector(paks, "inject"))


async def feature_repack_full(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_TOOL_DIR / "PAK")
    if not paks:
        context.user_data['awaiting'] = 'pak_for_repack_full'
        await update.message.reply_text(
            "📭 PAK TOOL/PAK khaali\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📎 Ab .pak file bhejo\n"
            "✅ Complete hone pe bot REPACK flow chalu karega"
        )
        return
    await update.message.reply_text("🔨 Select PAK for REPACK:", reply_markup=pak_selector(paks, "repack_full"))


async def feature_repack_path(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_TOOL_DIR / "PAK")
    if not paks:
        context.user_data['awaiting'] = 'pak_for_repack_path'
        await update.message.reply_text(
            "📭 PAK TOOL/PAK khaali\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📎 Ab .pak file bhejo\n"
            "✅ Complete hone pe bot REPACK TO PATH flow chalu karega"
        )
        return
    await update.message.reply_text("📁 Select PAK:", reply_markup=pak_selector(paks, "repack_path"))


async def feature_protect(update, context):
    if not is_allowed(update.effective_user.id):
        return
    paks = list_paks(PAK_TOOL_DIR / "PAK")
    if not paks:
        context.user_data['awaiting'] = 'pak_for_protect'
        await update.message.reply_text(
            "📭 PAK TOOL/PAK khaali\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📎 Ab .pak file bhejo\n"
            "✅ Complete hone pe bot PROTECT flow chalu karega"
        )
        return
    await update.message.reply_text("🔐 Select PAK to PROTECT:", reply_markup=pak_selector(paks, "protect"))


async def feature_delete(update, context):
    if not is_allowed(update.effective_user.id):
        return
    folders = []
    for item in BASE_DIR.iterdir():
        if item.is_dir() and item.name not in ['PAK', 'UNPACK', 'REPACK', 'RESULT', 'PAK TOOL', 'LUA TOOL']:
            folders.append(item)
    if not folders:
        await update.message.reply_text("📭 No folders to delete")
        return
    kb = [[InlineKeyboardButton("🗑️ " + f.name, callback_data="delete:" + f.name)] for f in folders]
    kb.append([InlineKeyboardButton("❌ Cancel", callback_data="cancel")])
    await update.message.reply_text("🗑️ Select folder:", reply_markup=InlineKeyboardMarkup(kb))


async def feature_theme(update, context):
    if not is_allowed(update.effective_user.id):
        return
    themes = [("nexa", "🎨 NEXA CYBER"), ("godfather", "👑 GODFATHER GOLD"),
              ("matrix", "🟢 MATRIX GREEN"), ("minimal", "⚪ MINIMAL DARK")]
    kb = [[InlineKeyboardButton(name, callback_data="theme:" + key)] for key, name in themes]
    kb.append([InlineKeyboardButton("❌ Cancel", callback_data="cancel")])
    await update.message.reply_text("🎨 Select THEME:", reply_markup=InlineKeyboardMarkup(kb))


async def feature_fastmode(update, context):
    if not is_allowed(update.effective_user.id):
        return
    fm_file = Path.home() / ".nexa_fastmode"
    current = "OFF"
    try:
        if fm_file.exists() and fm_file.read_text().strip() == "1":
            current = "ON 🔥"
    except Exception:
        pass
    kb = [[InlineKeyboardButton("⚡ Toggle", callback_data="fastmode:toggle")],
          [InlineKeyboardButton("❌ Cancel", callback_data="cancel")]]
    await update.message.reply_text(
        "⚡ FAST MODE\n━━━━━━━━━━━━━━━━━━━━\n\n📊 Current: " + current,
        reply_markup=InlineKeyboardMarkup(kb))


# ═══════════════════════════════════════════════════════════════════════════
#  COMPILE / DECOMPILE
# ═══════════════════════════════════════════════════════════════════════════

async def feature_compile(update, context):
    if not is_allowed(update.effective_user.id):
        return
    clean_lua_input()
    context.user_data['awaiting'] = 'compile_files'
    context.user_data['compile_files'] = []
    await update.message.reply_text(
        "🧪 COMPILE LUA\n"
        "━━━━━━━━━━━━━━━━━━━━\n\n"
        "📭 LUA TOOL/INPUT auto-clean ho gaya\n\n"
        "📎 Ab readable .lua source file bhejo\n"
        "✅ Complete hone pe /done bhejo"
    )


async def feature_decompile(update, context):
    if not is_allowed(update.effective_user.id):
        return
    clean_lua_input()
    context.user_data['awaiting'] = 'decompile_files'
    context.user_data['decompile_files'] = []
    await update.message.reply_text(
        "🔬 DECOMPILE LUA\n"
        "━━━━━━━━━━━━━━━━━━━━\n\n"
        "📭 LUA TOOL/INPUT auto-clean ho gaya\n\n"
        "📎 Ab bytecode .lua file bhejo\n"
        "✅ Complete hone pe /done bhejo\n\n"
        "⚠️ Note: Sirf standard Lua decompile hoga\n"
        "   LuaJIT ke liye: luadec.metaworm.site"
    )


# ═══════════════════════════════════════════════════════════════════════════
#  CALLBACK HANDLER — AUTO-CLEAN ON EVERY FEATURE
# ═══════════════════════════════════════════════════════════════════════════

async def callback_handler(update, context):
    query = update.callback_query
    await query.answer()

    if not is_allowed(update.effective_user.id):
        await query.edit_message_text("❌ Access Denied")
        return

    data = query.data

    if data == "cancel":
        await query.edit_message_text("❌ Cancelled")
        return

    # ═══ UNPACK ═══
    if data.startswith("unpack:"):
        pak_name = data.split(":", 1)[1]
        pak_path = PAK_DIR / pak_name
        if not pak_path.exists():
            await query.edit_message_text("❌ Not found")
            return

        # AUTO-CLEAN: UNPACK folder + other PAK
        clean_unpack_folder(pak_name)
        clean_pak_dir(keep_name=pak_name)

        info, stdout, stderr, ok = await run_with_progress(
            query, "bot_unpack.py", [pak_path], "UNPACK " + pak_name)

        if not ok:
            err = info.get('ERROR', '') or stderr[:300]
            await query.edit_message_text("❌ FAILED\n\n" + err[:400])
            return

        unpack_folder = UNPACK_DIR / Path(pak_name).stem
        if not unpack_folder.exists():
            await query.edit_message_text("❌ Output folder nahi mila")
            return

        await query.edit_message_text("🗜️ Creating ZIP...")
        zip_path = RESULT_DIR / (Path(pak_name).stem + ".zip")
        if not zip_folder(unpack_folder, zip_path):
            await query.edit_message_text("⚠️ ZIP too large")
            return

        zip_size = human_size(zip_path.stat().st_size)
        caption = "✅ UNPACK COMPLETE\n📦 PAK: {}\n📁 Files: {}\n📊 ZIP: {}".format(
            pak_name, info.get('FILES', '?'), zip_size)

        if await send_file(query, zip_path, caption):
            await query.edit_message_text("✅ UNPACK COMPLETE\n📥 ZIP upar bheji")
            # POST-CLEAN
            try:
                zip_path.unlink()
            except Exception:
                pass
        return

    # ═══ INJECT ═══
    if data.startswith("inject:"):
        pak_name = data.split(":", 1)[1]
        # AUTO-CLEAN
        clean_edit_folder()
        clean_result_pak(pak_name)
        clean_pak_folder(keep_name=pak_name)
        context.user_data['pending_inject'] = pak_name
        context.user_data['awaiting'] = 'inject_encrypt'
        await query.edit_message_text("💉 INJECT - " + pak_name + "\n\n🔐 SM4 encrypt? Reply yes/no")
        return

    # ═══ REPACK FULL ═══
    if data.startswith("repack_full:"):
        pak_name = data.split(":", 1)[1]
        pak_path = PAK_TOOL_DIR / "PAK" / pak_name
        if not pak_path.exists():
            await query.edit_message_text("❌ Not found")
            return

        # AUTO-CLEAN
        clean_result_pak(pak_name)
        clean_pak_folder(keep_name=pak_name)

        info, stdout, stderr, ok = await run_with_progress(
            query, "bot_repack.py", [pak_path], "REPACK " + pak_name)

        if not ok:
            err = info.get('ERROR', '') or stderr[:300]
            await query.edit_message_text("❌ FAILED\n\n" + err[:300])
            return

        result_pak = PAK_TOOL_DIR / "RESULT" / pak_name
        if not result_pak.exists():
            await query.edit_message_text("❌ Result nahi mila")
            return

        pak_size = human_size(result_pak.stat().st_size)
        await query.edit_message_text("📤 Uploading PAK...")
        caption = "✅ REPACK COMPLETE\n📦 PAK: {}\n📝 Files: {}\n📊 Size: {}".format(
            pak_name, info.get('COUNT', '?'), pak_size)

        if await send_file(query, result_pak, caption):
            await query.edit_message_text("✅ REPACK COMPLETE\n📥 PAK upar bheji")
            # POST-CLEAN
            clean_edit_folder()
            clean_result_pak(pak_name)
        return

    # ═══ REPACK TO PATH ═══
    if data.startswith("repack_path:"):
        pak_name = data.split(":", 1)[1]
        pak_path = PAK_TOOL_DIR / "PAK" / pak_name
        if not pak_path.exists():
            await query.edit_message_text("❌ Not found")
            return

        # AUTO-CLEAN
        clean_edit_folder()
        clean_result_pak(pak_name)
        clean_pak_folder(keep_name=pak_name)

        context.user_data['pending_repack_path'] = pak_name
        context.user_data['repack_files'] = []
        context.user_data['awaiting'] = 'repack_files'

        await query.edit_message_text(
            "📁 REPACK TO PATH\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📦 PAK: " + pak_name + "\n\n"
            "📎 Ab files bhejo:\n"
            "   • .lua\n"
            "   • .uasset\n"
            "   • .uexp\n"
            "   • .umap\n\n"
            "✅ Complete hone pe /done bhejo"
        )
        return

    # ═══ PROTECT ═══
    if data.startswith("protect:"):
        pak_name = data.split(":", 1)[1]
        pak_path = PAK_TOOL_DIR / "PAK" / pak_name
        if not pak_path.exists():
            await query.edit_message_text("❌ Not found")
            return

        # AUTO-CLEAN
        clean_result_pak(pak_name)
        clean_pak_folder(keep_name=pak_name)

        info, stdout, stderr, ok = await run_with_progress(
            query, "bot_protect.py", [pak_path], "PROTECT " + pak_name)

        if not ok:
            err = info.get('ERROR', '') or stderr[:300]
            await query.edit_message_text("❌ FAILED\n\n" + err[:300])
            return

        result_pak = PAK_TOOL_DIR / "RESULT" / pak_name
        if not result_pak.exists():
            await query.edit_message_text("❌ Result nahi mila")
            return

        pak_size = human_size(result_pak.stat().st_size)
        await query.edit_message_text("📤 Uploading PAK...")
        caption = "✅ PROTECTED\n📦 PAK: {}\n🔐 Files: {}\n📊 Size: {}".format(
            pak_name, info.get('PROTECTED', '?'), pak_size)

        if await send_file(query, result_pak, caption):
            await query.edit_message_text("✅ PROTECTED\n📥 PAK upar bheji")
            # POST-CLEAN
            clean_result_pak(pak_name)
        return

    # ═══ DELETE ═══
    if data.startswith("delete:"):
        folder_name = data.split(":", 1)[1]
        stdout, stderr, rc = run_script("bot_delete.py", [folder_name], timeout=300)
        if 'SUCCESS' in stdout:
            await query.edit_message_text("✅ Deleted: " + folder_name)
        else:
            info = parse_output(stdout)
            err = info.get('ERROR', '') or stderr[:200]
            await query.edit_message_text("❌ " + err[:200])
        return

    # ═══ THEME ═══
    if data.startswith("theme:"):
        theme = data.split(":", 1)[1]
        (Path.home() / ".nexa_theme").write_text(theme, encoding='utf-8')
        await query.edit_message_text("🎨 THEME: " + theme)
        return

    # ═══ FAST MODE ═══
    if data == "fastmode:toggle":
        fm = Path.home() / ".nexa_fastmode"
        cur = "0"
        try:
            if fm.exists():
                cur = fm.read_text().strip()
        except Exception:
            pass
        new = "0" if cur == "1" else "1"
        fm.write_text(new, encoding='utf-8')
        await query.edit_message_text("⚡ FAST MODE: " + ("ON 🔥" if new == "1" else "OFF 🐢"))
        return


# ═══════════════════════════════════════════════════════════════════════════
#  TEXT HANDLER
# ═══════════════════════════════════════════════════════════════════════════

async def text_handler(update, context):
    if not is_allowed(update.effective_user.id):
        return

    text = update.message.text.strip()
    awaiting = context.user_data.get('awaiting')

    # ═══ COMPILE FILES — /done ═══
    if awaiting == 'compile_files':
        if text.lower() in ('/done', 'done', '/finish', 'finish'):
            files = context.user_data.get('compile_files', [])
            if not files:
                await update.message.reply_text("❌ Koi file nahi bheji\n\n📎 .lua source file bhejo pehle")
                return
            context.user_data['awaiting'] = None
            msg = await update.message.reply_text(
                "📁 {} files received\n\n⏳ Compiling...".format(len(files))
            )
            process = await asyncio.create_subprocess_exec(
                sys.executable, str(BASE_DIR / "bot_compile.py"),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(BASE_DIR)
            )
            stdout_b, stderr_b = await process.communicate()
            stdout = stdout_b.decode('utf-8', 'ignore')
            stderr = stderr_b.decode('utf-8', 'ignore')
            info = parse_output(stdout)
            if 'SUCCESS' not in stdout:
                err = info.get('ERROR', '') or stderr[:300] or stdout[:300]
                await msg.edit_text("❌ COMPILE FAILED\n\n" + err[:400])
                return
            output_dir = LUA_DIR / "COMPILE"
            zip_path = RESULT_DIR / ("compiled_" + str(int(time.time())) + ".zip")
            if not zip_folder(output_dir, zip_path):
                await msg.edit_text("⚠️ ZIP too large")
                return
            zip_size = human_size(zip_path.stat().st_size)
            caption = "✅ COMPILE COMPLETE\n✓ OK: {}\n✗ FAIL: {}\n📦 ZIP: {}".format(
                info.get('OK', '?'), info.get('FAIL', '?'), zip_size)
            if await send_file(update, zip_path, caption):
                await msg.edit_text(
                    "✅ COMPILE COMPLETE\n━━━━━━━━━━━━━━━━━━━━\n\n"
                    "✓ OK: {}\n✗ FAIL: {}\n📊 ZIP: {}\n\n📥 ZIP upar bheji".format(
                        info.get('OK', '?'), info.get('FAIL', '?'), zip_size
                    )
                )
                try:
                    zip_path.unlink()
                except Exception:
                    pass
                clean_lua_input()
            return
        else:
            await update.message.reply_text(
                "📎 .lua source file bhejo\n\n✅ Complete hone pe /done bhejo"
            )
        return

    # ═══ DECOMPILE FILES — /done ═══
    if awaiting == 'decompile_files':
        if text.lower() in ('/done', 'done', '/finish', 'finish'):
            files = context.user_data.get('decompile_files', [])
            if not files:
                await update.message.reply_text("❌ Koi file nahi bheji")
                return
            context.user_data['awaiting'] = None
            msg = await update.message.reply_text(
                "📁 {} files received\n\n⏳ Decompiling...".format(len(files))
            )
            process = await asyncio.create_subprocess_exec(
                sys.executable, str(BASE_DIR / "bot_decompile.py"),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(BASE_DIR)
            )
            stdout_b, stderr_b = await process.communicate()
            stdout = stdout_b.decode('utf-8', 'ignore')
            stderr = stderr_b.decode('utf-8', 'ignore')
            info = parse_output(stdout)
            if 'SUCCESS' not in stdout:
                err = info.get('ERROR', '') or stderr[:300] or stdout[:300]
                await msg.edit_text("❌ DECOMPILE FAILED\n\n" + err[:400])
                return
            output_dir = LUA_DIR / "DECOMPILE"
            zip_path = RESULT_DIR / ("decompiled_" + str(int(time.time())) + ".zip")
            if not zip_folder(output_dir, zip_path):
                await msg.edit_text("⚠️ ZIP too large")
                return
            zip_size = human_size(zip_path.stat().st_size)
            caption = "✅ DECOMPILE COMPLETE\n✓ OK: {}\n✗ FAIL: {}\n📦 ZIP: {}".format(
                info.get('OK', '?'), info.get('FAIL', '?'), zip_size)
            if await send_file(update, zip_path, caption):
                await msg.edit_text(
                    "✅ DECOMPILE COMPLETE\n━━━━━━━━━━━━━━━━━━━━\n\n"
                    "✓ OK: {}\n✗ FAIL: {}\n📊 ZIP: {}\n\n📥 ZIP upar bheji".format(
                        info.get('OK', '?'), info.get('FAIL', '?'), zip_size
                    )
                )
                try:
                    zip_path.unlink()
                except Exception:
                    pass
                clean_lua_input()
            return
        else:
            await update.message.reply_text(
                "📎 .lua bytecode file bhejo\n\n✅ Complete hone pe /done bhejo"
            )
        return

    # ═══ REPACK FILES — /done ═══
    if awaiting == 'repack_files':
        if text.lower() in ('/done', 'done', '/finish', 'finish'):
            files = context.user_data.get('repack_files', [])
            if not files:
                await update.message.reply_text("❌ Koi file nahi bheji")
                return
            context.user_data['awaiting'] = 'target_path'
            await update.message.reply_text(
                "📁 {} files received\n\n🎯 Ab target path bhejo:\n"
                "e.g. Content/Lua/GameLua/Mod/BRMod/Gameplay/Core".format(len(files))
            )
        else:
            await update.message.reply_text(
                "📎 Files bhejo (lua, uasset, uexp)\n\n✅ Done hone pe /done bhejo"
            )
        return

    # ═══ TARGET PATH ═══
    if awaiting == 'target_path':
        pak_name = context.user_data.get('pending_repack_path')
        files = context.user_data.get('repack_files', [])
        context.user_data['awaiting'] = None
        target = text.strip().strip('/')
        if not target:
            await update.message.reply_text("❌ Path khaali hai")
            return
        edit_dir = PAK_TOOL_DIR / "EDIT"
        target_dir = edit_dir / target
        target_dir.mkdir(parents=True, exist_ok=True)
        msg = await update.message.reply_text("📥 Moving " + str(len(files)) + " files to target...")
        saved = 0
        for root_file in edit_dir.iterdir():
            if root_file.is_file():
                try:
                    dest = target_dir / root_file.name
                    shutil.move(str(root_file), str(dest))
                    saved += 1
                except Exception as e:
                    logger.error("Move error: %s", e)
        await msg.edit_text("✅ {} files moved\n\n⏳ Repacking PAK...".format(saved))
        pak_path = PAK_TOOL_DIR / "PAK" / pak_name
        stdout, stderr, rc = run_script(
            "bot_repack_path.py", [pak_path, target], timeout=7200
        )
        info = parse_output(stdout)
        if 'SUCCESS' not in stdout:
            err = info.get('ERROR', '') or stderr[:300]
            await msg.edit_text("❌ FAILED\n\n" + err[:300])
            return
        result_pak = PAK_TOOL_DIR / "RESULT" / pak_name
        if not result_pak.exists():
            await msg.edit_text("❌ Result PAK nahi mila")
            return
        pak_size = human_size(result_pak.stat().st_size)
        await msg.edit_text("📤 Uploading PAK (" + pak_size + ")...")
        caption = "✅ REPACK COMPLETE\n📦 PAK: {}\n🎯 Target: {}\n📊 Size: {}".format(
            pak_name, target, pak_size)
        if await send_file(update, result_pak, caption):
            await msg.edit_text(
                "✅ REPACK COMPLETE\n"
                "━━━━━━━━━━━━━━━━━━━━\n\n"
                "📦 PAK: " + pak_name + "\n"
                "🎯 Target: " + target + "\n"
                "📊 Size: " + pak_size
            )
            clean_edit_folder()
            clean_result_pak(pak_name)
        else:
            await msg.edit_text("❌ Send failed\n📁 PAK TOOL/RESULT/" + pak_name)
        return

    # ═══ INJECT ENCRYPT ═══
    if awaiting == 'inject_encrypt':
        pak_name = context.user_data.get('pending_inject')
        context.user_data['awaiting'] = None
        encrypt = "yes" if text.lower() in ('y', 'yes', 'haan', 'ha') else "no"
        pak_path = PAK_TOOL_DIR / "PAK" / pak_name
        msg = await update.message.reply_text("⏳ Injecting...")
        stdout, stderr, rc = run_script("bot_inject.py", [pak_path, encrypt], timeout=7200)
        info = parse_output(stdout)
        if 'SUCCESS' not in stdout:
            err = info.get('ERROR', '') or stderr[:300]
            await msg.edit_text("❌ FAILED\n\n" + err[:300])
            return
        result_pak = PAK_TOOL_DIR / "RESULT" / pak_name
        if not result_pak.exists():
            await msg.edit_text("❌ Result nahi mila")
            return
        pak_size = human_size(result_pak.stat().st_size)
        await msg.edit_text("📤 Uploading PAK...")
        caption = "✅ INJECT COMPLETE\n📦 PAK: {}\n✏️ Edited: {}\n➕ Added: {}".format(
            pak_name, info.get('EDITED', '?'), info.get('ADDED', '?'))
        if await send_file(update, result_pak, caption):
            await msg.edit_text("✅ INJECT COMPLETE\n📥 PAK upar bheji")
            clean_edit_folder()
            clean_result_pak(pak_name)
        return

    # ═══ MENU BUTTONS ═══
    if "UNPACK" in text:
        await feature_unpack(update, context)
    elif "INJECT" in text:
        await feature_inject(update, context)
    elif "REPACK FULL" in text:
        await feature_repack_full(update, context)
    elif "REPACK TO PATH" in text:
        await feature_repack_path(update, context)
    elif "PROTECT" in text:
        await feature_protect(update, context)
    elif "DELETE" in text:
        await feature_delete(update, context)
    elif "COMPILE LUA" in text:
        await feature_compile(update, context)
    elif "DECOMPILE LUA" in text:
        await feature_decompile(update, context)
    elif "THEME" in text:
        await feature_theme(update, context)
    elif "FAST MODE" in text:
        await feature_fastmode(update, context)
    elif "STATUS" in text:
        await cmd_status(update, context)
    elif "HELP" in text:
        await cmd_help(update, context)
    else:
        await update.message.reply_text("❓ Use buttons or /help")


# ═══════════════════════════════════════════════════════════════════════════
#  DOCUMENT HANDLER
# ═══════════════════════════════════════════════════════════════════════════

async def document_handler(update, context):
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ Access Denied")
        return

    doc = update.message.document
    if not doc:
        return

    file_name = doc.file_name or "unknown"
    file_size = doc.file_size or 0
    file_name = clean_filename(file_name)

    if file_size > 2 * 1024 * 1024 * 1024:
        await update.message.reply_text("⚠️ Too large: " + human_size(file_size))
        return

    awaiting = context.user_data.get('awaiting')

    # ═══ PAK FOR UNPACK ═══
    if awaiting == 'pak_for_unpack':
        if not file_name.lower().endswith('.pak'):
            await update.message.reply_text("❌ .pak file bhejo")
            return
        try:
            f = await context.bot.get_file(doc.file_id)
            dest = PAK_DIR / file_name
            await f.download_to_drive(str(dest))
            await update.message.reply_text("✅ PAK saved: " + file_name + "\n\n📦 Ab UNPACK dabao")
            context.user_data['awaiting'] = None
        except Exception as e:
            await update.message.reply_text("❌ Failed: " + str(e)[:200])
        return

    # ═══ PAK FOR INJECT ═══
    if awaiting == 'pak_for_inject':
        if not file_name.lower().endswith('.pak'):
            await update.message.reply_text("❌ .pak file bhejo")
            return
        try:
            f = await context.bot.get_file(doc.file_id)
            dest = PAK_TOOL_DIR / "PAK" / file_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            await f.download_to_drive(str(dest))
            await update.message.reply_text("✅ PAK saved: " + file_name + "\n\n💉 Ab INJECT dabao")
            context.user_data['awaiting'] = None
        except Exception as e:
            await update.message.reply_text("❌ Failed: " + str(e)[:200])
        return

    # ═══ PAK FOR REPACK FULL ═══
    if awaiting == 'pak_for_repack_full':
        if not file_name.lower().endswith('.pak'):
            await update.message.reply_text("❌ .pak file bhejo")
            return
        try:
            f = await context.bot.get_file(doc.file_id)
            dest = PAK_TOOL_DIR / "PAK" / file_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            await f.download_to_drive(str(dest))
            await update.message.reply_text("✅ PAK saved: " + file_name + "\n\n🔨 Ab REPACK FULL dabao")
            context.user_data['awaiting'] = None
        except Exception as e:
            await update.message.reply_text("❌ Failed: " + str(e)[:200])
        return

    # ═══ PAK FOR REPACK PATH ═══
    if awaiting == 'pak_for_repack_path':
        if not file_name.lower().endswith('.pak'):
            await update.message.reply_text("❌ .pak file bhejo")
            return
        try:
            f = await context.bot.get_file(doc.file_id)
            dest = PAK_TOOL_DIR / "PAK" / file_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            await f.download_to_drive(str(dest))
            await update.message.reply_text("✅ PAK saved: " + file_name + "\n\n📁 Ab REPACK TO PATH dabao")
            context.user_data['awaiting'] = None
        except Exception as e:
            await update.message.reply_text("❌ Failed: " + str(e)[:200])
        return

    # ═══ PAK FOR PROTECT ═══
    if awaiting == 'pak_for_protect':
        if not file_name.lower().endswith('.pak'):
            await update.message.reply_text("❌ .pak file bhejo")
            return
        try:
            f = await context.bot.get_file(doc.file_id)
            dest = PAK_TOOL_DIR / "PAK" / file_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            await f.download_to_drive(str(dest))
            await update.message.reply_text("✅ PAK saved: " + file_name + "\n\n🔐 Ab PROTECT dabao")
            context.user_data['awaiting'] = None
        except Exception as e:
            await update.message.reply_text("❌ Failed: " + str(e)[:200])
        return

    # ═══ COMPILE FILES ═══
    if awaiting == 'compile_files':
        files = context.user_data.get('compile_files', [])
        files.append((doc.file_id, file_name))
        context.user_data['compile_files'] = files
        input_dir = LUA_DIR / "INPUT"
        input_dir.mkdir(parents=True, exist_ok=True)
        try:
            f = await context.bot.get_file(doc.file_id)
            await f.download_to_drive(str(input_dir / file_name))
        except Exception as e:
            logger.error("Save error: %s", e)
        await update.message.reply_text(
            "📎 File {}: {}\n▶️ Aur bhejo ya /done bhejo".format(len(files), file_name)
        )
        return

    # ═══ DECOMPILE FILES ═══
    if awaiting == 'decompile_files':
        files = context.user_data.get('decompile_files', [])
        files.append((doc.file_id, file_name))
        context.user_data['decompile_files'] = files
        input_dir = LUA_DIR / "INPUT"
        input_dir.mkdir(parents=True, exist_ok=True)
        try:
            f = await context.bot.get_file(doc.file_id)
            await f.download_to_drive(str(input_dir / file_name))
        except Exception as e:
            logger.error("Save error: %s", e)
        await update.message.reply_text(
            "📎 File {}: {}\n▶️ Aur bhejo ya /done bhejo".format(len(files), file_name)
        )
        return

    # ═══ REPACK FILES ═══
    if awaiting == 'repack_files':
        files = context.user_data.get('repack_files', [])
        files.append((doc.file_id, file_name))
        context.user_data['repack_files'] = files
        edit_dir = PAK_TOOL_DIR / "EDIT"
        edit_dir.mkdir(parents=True, exist_ok=True)
        try:
            f = await context.bot.get_file(doc.file_id)
            await f.download_to_drive(str(edit_dir / file_name))
        except Exception as e:
            logger.error("Save error: %s", e)
        await update.message.reply_text(
            "📎 File {}: {}\n▶️ Aur bhejo ya /done bhejo".format(len(files), file_name)
        )
        return

    # ═══ NORMAL UPLOAD ═══
    lower = file_name.lower()
    if lower.endswith(".pak"):
        dest_dir = PAK_DIR
        label = "PAK/"
    elif lower.endswith((".lua", ".luac")):
        dest_dir = LUA_DIR / "INPUT"
        label = "LUA TOOL/INPUT/"
    else:
        dest_dir = PAK_DIR
        label = "PAK/"

    msg = await update.message.reply_text("📥 Downloading " + file_name + "...")

    try:
        file = await context.bot.get_file(doc.file_id)
        dest = dest_dir / file_name
        await file.download_to_drive(str(dest))

        extra_info = ""
        if lower.endswith(".pak"):
            try:
                tool_dest = PAK_TOOL_DIR / "PAK" / file_name
                tool_dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(str(dest), str(tool_dest))
                extra_info = (
                    "\n📁 PAK/          ← UNPACK ke liye\n"
                    "📁 PAK TOOL/PAK/  ← INJECT/REPACK/PROTECT ke liye"
                )
            except Exception as e:
                logger.error("Copy error: %s", e)

        await msg.edit_text(
            "✅ UPLOADED\n"
            "━━━━━━━━━━━━━━━━━━━━\n\n"
            "📄 File: " + file_name + "\n"
            "📊 Size: " + human_size(file_size) + "\n"
            "📁 Path: " + label + file_name + extra_info
        )
    except Exception as e:
        await msg.edit_text("❌ Failed: " + str(e)[:200])


# ═══════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════

def main():
    if BOT_TOKEN == "YOUR_BOT_TOKEN_HERE":
        print("❌ BOT_TOKEN set nahi kiya!")
        return
    if OWNER_ID == 123456789:
        print("❌ OWNER_ID edit karo!")
        return

    print("⚡ NEXA CHEAT BOT starting...")
    print("📁 Base: {}".format(BASE_DIR))
    print("👑 Owner: {}".format(OWNER_ID))

    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("allow", cmd_allow))
    app.add_handler(CommandHandler("deny", cmd_deny))
    app.add_handler(CommandHandler("allowed", cmd_allowed))
    app.add_handler(CommandHandler("pending", cmd_pending))
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("help", cmd_help))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("paks", cmd_paks))
    app.add_handler(CommandHandler("done", text_handler))
    app.add_handler(CallbackQueryHandler(callback_handler))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, text_handler))
    app.add_handler(MessageHandler(filters.Document.ALL, document_handler))

    print("✅ Bot running! Telegram pe /start bhejo.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == '__main__':
    main()
