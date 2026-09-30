#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  NEXA CHEAT - PROGRESS BAR FIX"
echo "════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. Fix bot_unpack.py — progress har file pe update
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_unpack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, dump_unpacking_log
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_unpack.py <pak>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    unpack_path = base / "UNPACK" / pak_path.stem

    if unpack_path.exists():
        try:
            shutil.rmtree(unpack_path)
        except Exception:
            pass

    try:
        print("Unpacking: {}".format(pak_path.name))

        # QUICK count first
        progress_start("UNPACK", 0)
        progress_update(0, "Reading index...")

        pak = TencentPakFile(pak_path)
        total = sum(len(d) for d in pak._index.values())

        # Set TOTAL now
        progress_start("UNPACK", total)
        progress_update(0, "Starting...")

        original = pak._write_to_disk
        counter = [0]

        def tracked(file_path, entry):
            counter[0] += 1
            progress_update(counter[0], file_path.name)
            return original(file_path, entry)

        pak._write_to_disk = tracked
        pak.dump(unpack_path)

        progress_update(total, "Done")
        progress_finish("done", "{} files".format(total))
        print("SUCCESS")
        print("FILES:{}".format(total))
        print("OUTPUT:{}".format(unpack_path))
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_unpack.py"

# ═══════════════════════════════════════════════════════════════════════════
# 2. Fix bot_repack.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_repack.py <pak>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    old = result_dir / pak_path.name
    if old.exists():
        try:
            old.unlink()
        except Exception:
            pass

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty")
        sys.exit(1)

    try:
        print("Repacking: {}".format(pak_path.name))

        progress_start("REPACK", 0)
        progress_update(0, "Loading PAK...")

        pak = TencentPakFile(pak_path)
        edit_files = [p for p in edit_dir.rglob('*') if p.is_file()]
        total = len(edit_files)

        progress_start("REPACK", total)
        progress_update(0, "Rebuilding...")

        out = result_dir / pak_path.name
        count = repack_pak_file_full(pak, edit_dir, out)

        progress_update(total, "Done")
        progress_finish("done", "{} files".format(count))

        print("SUCCESS")
        print("COUNT:{}".format(count))
        print("SIZE:{}".format(out.stat().st_size))
        print("OUTPUT:{}".format(out))
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_repack.py"

# ═══════════════════════════════════════════════════════════════════════════
# 3. Fix bot_inject.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_inject.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, inject_edit_files
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_inject.py <pak> [yes|no]")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    encrypt = len(sys.argv) > 2 and sys.argv[2].lower() in ('yes', 'y', '1')

    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    old = result_dir / pak_path.name
    if old.exists():
        try:
            old.unlink()
        except Exception:
            pass

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty")
        sys.exit(1)

    try:
        print("Injecting: {}".format(pak_path.name))

        progress_start("INJECT", 0)
        progress_update(0, "Loading PAK...")

        pak = TencentPakFile(pak_path)
        edit_count = len([p for p in edit_dir.rglob('*') if p.is_file()])

        progress_start("INJECT", edit_count)
        progress_update(0, "Processing {} files...".format(edit_count))

        out = result_dir / pak_path.name
        edited, added = inject_edit_files(pak, edit_dir, out, protect_new=encrypt, sm4_type=47)

        progress_update(edit_count, "Done")
        progress_finish("done", "{} files".format(edited + added))

        print("SUCCESS")
        print("EDITED:{}".format(edited))
        print("ADDED:{}".format(added))
        print("SIZE:{}".format(out.stat().st_size))
        print("OUTPUT:{}".format(out))
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_inject.py"

# ═══════════════════════════════════════════════════════════════════════════
# 4. Fix bot_protect.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_protect.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, protect_pak_file
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_protect.py <pak>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    old = result_dir / pak_path.name
    if old.exists():
        try:
            old.unlink()
        except Exception:
            pass

    try:
        print("Protecting: {}".format(pak_path.name))

        progress_start("PROTECT", 0)
        progress_update(0, "Loading PAK...")

        pak = TencentPakFile(pak_path)
        total = sum(len(d) for d in pak._index.values())

        progress_start("PROTECT", total)
        progress_update(0, "Encrypting...")

        out = result_dir / pak_path.name
        protected, skipped = protect_pak_file(pak, out, sm4_type=47)

        progress_update(total, "Done")
        progress_finish("done", "{} files".format(protected))

        print("SUCCESS")
        print("PROTECTED:{}".format(protected))
        print("SKIPPED:{}".format(skipped))
        print("SIZE:{}".format(out.stat().st_size))
        print("OUTPUT:{}".format(out))
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_protect.py"

# ═══════════════════════════════════════════════════════════════════════════
# 5. Fix bot_repack_path.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack_path.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 3:
        print("ERROR: Usage: bot_repack_path.py <pak> <target>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    target = sys.argv[2].strip('/').replace('\\', '/')
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    old = result_dir / pak_path.name
    if old.exists():
        try:
            old.unlink()
        except Exception:
            pass

    try:
        print("Repacking to path: {}".format(target))

        progress_start("REPACK TO PATH", 0)
        progress_update(0, "Loading PAK...")

        pak = TencentPakFile(pak_path)
        edit_files = [p for p in edit_dir.rglob('*') if p.is_file()]
        progress_start("REPACK TO PATH", len(edit_files))

        out = result_dir / pak_path.name
        count = repack_pak_file_full(pak, edit_dir, out, target, force_add=True)

        progress_finish("done", "{} files -> {}".format(count, target))
        if count > 0:
            print("SUCCESS")
            print("COUNT:{}".format(count))
            print("SIZE:{}".format(out.stat().st_size))
            print("TARGET:{}".format(target))
            print("OUTPUT:{}".format(out))
        else:
            print("ERROR: No files processed")
            sys.exit(1)
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_repack_path.py"

# ═══════════════════════════════════════════════════════════════════════════
# 6. Fix bot_compile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_compile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _compile_one_lua, _list_lua_files
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    base = Path(__file__).parent
    lua_dir = base / "LUA TOOL"
    tools_dir = lua_dir / "TOOLS"
    input_dir = lua_dir / "INPUT"
    output_dir = lua_dir / "COMPILE"

    if output_dir.exists():
        try:
            shutil.rmtree(output_dir)
        except Exception:
            pass
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_dir.exists() or not any(input_dir.rglob('*.lua')):
        print("ERROR: INPUT folder empty")
        sys.exit(1)

    tools = _find_lua_tool(tools_dir)
    if not (tools.get('luajit') or tools.get('luac')):
        print("ERROR: No Lua compiler")
        sys.exit(1)

    files = _list_lua_files(input_dir)
    progress_start("COMPILE", len(files))

    ok = 0
    fail = 0
    for i, src in enumerate(files, 1):
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        progress_update(i, str(rel))
        try:
            success, used = _compile_one_lua(src, out, tools)
            if success:
                ok += 1
            else:
                fail += 1
        except Exception:
            fail += 1

    progress_finish("done", "{} ok, {} fail".format(ok, fail))
    print("SUCCESS" if ok > 0 else "ERROR")
    print("OK:{}".format(ok))
    print("FAIL:{}".format(fail))
    print("OUTPUT:{}".format(output_dir))


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_compile.py"

# ═══════════════════════════════════════════════════════════════════════════
# 7. Fix bot_decompile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_decompile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _decompile_one_lua, _list_lua_files
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    base = Path(__file__).parent
    lua_dir = base / "LUA TOOL"
    tools_dir = lua_dir / "TOOLS"
    input_dir = lua_dir / "INPUT"
    output_dir = lua_dir / "DECOMPILE"

    if output_dir.exists():
        try:
            shutil.rmtree(output_dir)
        except Exception:
            pass
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_dir.exists() or not any(input_dir.rglob('*.lua')):
        print("ERROR: INPUT folder empty")
        sys.exit(1)

    tools = _find_lua_tool(tools_dir)
    if not (tools.get('unluac') or tools.get('ljd')):
        print("ERROR: No decompiler")
        sys.exit(1)

    files = _list_lua_files(input_dir)
    progress_start("DECOMPILE", len(files))

    ok = 0
    fail = 0
    for i, src in enumerate(files, 1):
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        progress_update(i, str(rel))
        try:
            success, used = _decompile_one_lua(src, out, tools)
            if success:
                ok += 1
            else:
                fail += 1
        except Exception:
            fail += 1

    progress_finish("done", "{} ok, {} fail".format(ok, fail))
    print("SUCCESS" if ok > 0 else "ERROR")
    print("OK:{}".format(ok))
    print("FAIL:{}".format(fail))
    print("OUTPUT:{}".format(output_dir))


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_decompile.py"

# ═══════════════════════════════════════════════════════════════════════════
# 8. Fix telegram_bot.py — fast progress updates
# ═══════════════════════════════════════════════════════════════════════════
python3 << 'PYEOF'
with open('telegram_bot.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Reduce sleep time from 3 to 0.7 seconds
old_sleep = 'await asyncio.sleep(3)'
if old_sleep in content:
    content = content.replace(old_sleep, 'await asyncio.sleep(0.7)')
    print("✓ sleep(3) → sleep(0.7)")

# Add progress read at start (before process runs)
old_start = '''async def run_with_progress(query, script, args, title, timeout=7200):
    """Run script with live progress on Telegram."""
    # CLEAN OLD PROGRESS FILE
    try:
        pf = Path.home() / ".nexa_progress"
        if pf.exists():
            pf.unlink()
    except Exception:
        pass

    await query.edit_message_text("Starting: " + title + "...")'''

new_start = '''async def run_with_progress(query, script, args, title, timeout=7200):
    """Run script with live progress on Telegram."""
    # CLEAN OLD PROGRESS FILE
    try:
        pf = Path.home() / ".nexa_progress"
        if pf.exists():
            pf.unlink()
    except Exception:
        pass

    await query.edit_message_text("Starting: " + title + "...\\n\\nPlease wait")'''

if old_start in content:
    content = content.replace(old_start, new_start, 1)
    print("✓ start message updated")

with open('telegram_bot.py', 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

echo "✓ telegram_bot.py"

# ═══════════════════════════════════════════════════════════════════════════
# SYNTAX CHECK
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "Syntax check:"
for f in progress_helper.py bot_*.py telegram_bot.py; do
    python -m py_compile "$f" 2>&1 && echo "  ✓ $f" || echo "  ✗ $f"
done
echo "════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST — Progress bar live
# ═══════════════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════"
echo "TEST — Live progress"
echo "════════════════════════════════════════════════"

PAK_FILE=$(ls PAK/*.pak 2>/dev/null | head -1)
if [ -z "$PAK_FILE" ]; then
    echo "  No PAK files"
else
    echo "  PAK: $PAK_FILE"
    rm -f ~/.nexa_progress
    rm -rf "UNPACK/$(basename "$PAK_FILE" .pak)" 2>/dev/null

    python bot_unpack.py "$PAK_FILE" > /dev/null 2>&1 &
    PID=$!

    echo ""
    echo "  Progress snapshots (every 0.5s):"
    for i in 1 2 3 4 5; do
        sleep 0.5
        if [ -f ~/.nexa_progress ]; then
            CURRENT=$(grep "CURRENT:" ~/.nexa_progress | cut -d: -f2)
            TOTAL=$(grep "TOTAL:" ~/.nexa_progress | cut -d: -f2)
            STATUS=$(grep "STATUS:" ~/.nexa_progress | cut -d: -f2)
            echo "    [$i] $CURRENT/$TOTAL ($STATUS)"
        fi
    done

    wait $PID 2>/dev/null
    echo ""
    echo "  ✓ Done"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "✓ PROGRESS BAR FIX DONE"
echo "════════════════════════════════════════════════"

