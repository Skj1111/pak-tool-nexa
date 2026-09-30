#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "⚡ NEXA CHEAT — Progress Bar Setup"
echo "════════════════════════════════════"

# ═══════════════════════════════════════════════════════════════════════════
# 1. progress_helper.py
# ═══════════════════════════════════════════════════════════════════════════
cat > progress_helper.py << 'PYEOF'
#!/usr/bin/env python3
"""Shared progress tracker for bot scripts."""
import time
from pathlib import Path

PROGRESS_FILE = Path.home() / ".nexa_progress"


def _read() -> dict:
    try:
        if not PROGRESS_FILE.exists():
            return {}
        data = {}
        for line in PROGRESS_FILE.read_text(encoding='utf-8').splitlines():
            if ':' in line:
                k, _, v = line.partition(':')
                data[k.strip()] = v.strip()
        return data
    except Exception:
        return {}


def _write(data: dict):
    try:
        out = "\n".join(f"{k}:{v}" for k, v in data.items()) + "\n"
        PROGRESS_FILE.write_text(out, encoding='utf-8')
    except Exception:
        pass


def progress_start(task_name: str, total: int = 0):
    _write({
        'TASK': task_name,
        'CURRENT': '0',
        'TOTAL': str(total),
        'STATUS': 'running',
        'STARTED': str(int(time.time())),
        'CURRENT_ITEM': '',
    })


def progress_update(current: int, item: str = ""):
    data = _read()
    if not data:
        return
    data['CURRENT'] = str(current)
    if item:
        data['CURRENT_ITEM'] = item.replace('\n', ' ')[:80]
    _write(data)


def progress_finish(status: str = "done", message: str = ""):
    data = _read()
    if not data:
        return
    data['STATUS'] = status
    if message:
        data['MESSAGE'] = message.replace('\n', ' ')[:100]
    _write(data)


def progress_read() -> dict:
    return _read()
PYEOF
echo "✓ progress_helper.py"

# ═══════════════════════════════════════════════════════════════════════════
# 2. bot_unpack.py (with progress)
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_unpack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, dump_unpacking_log
from progress_helper import progress_start, progress_update, progress_finish


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_unpack.py <pak>"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)

    base = Path(__file__).parent
    unpack_path = base / "UNPACK" / pak_path.stem

    try:
        progress_start("UNPACK", 100)
        progress_update(0, f"Opening {pak_path.name}")

        print(f"Unpacking: {pak_path.name}")
        pak = TencentPakFile(pak_path)

        total = sum(len(d) for d in pak._index.values())
        progress_start("UNPACK", total)

        original_write = pak._write_to_disk
        counter = [0]

        def tracked_write(file_path, entry):
            counter[0] += 1
            progress_update(counter[0], file_path.name)
            return original_write(file_path, entry)

        pak._write_to_disk = tracked_write
        pak.dump(unpack_path)
        progress_update(total, "Done")

        try:
            log_path = unpack_path / f'Debug_{pak_path.stem}.log'
            dump_unpacking_log(pak, log_path)
        except Exception:
            pass

        progress_finish("done", f"{total} files extracted")
        print("SUCCESS")
        print(f"FILES:{total}")
        print(f"OUTPUT:{unpack_path}")
    except Exception as e:
        progress_finish("error", str(e))
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_unpack.py"

# ═══════════════════════════════════════════════════════════════════════════
# 3. bot_repack.py (with progress)
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full
from progress_helper import progress_start, progress_update, progress_finish


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_repack.py <pak>"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty"); sys.exit(1)

    try:
        progress_start("REPACK", 100)
        progress_update(0, f"Loading {pak_path.name}")

        print(f"Repacking: {pak_path.name}")
        pak = TencentPakFile(pak_path)

        edit_files = [p for p in edit_dir.rglob('*') if p.is_file()]
        total = len(edit_files)
        progress_start("REPACK", total)
        progress_update(0, f"{total} files to process")

        out = result_dir / pak_path.name
        progress_update(10, "Rebuilding archive...")
        count = repack_pak_file_full(pak, edit_dir, out)
        progress_update(total, "Done")
        progress_finish("done", f"{count} files repacked")

        if count > 0:
            print("SUCCESS")
            print(f"COUNT:{count}")
            print(f"SIZE:{out.stat().st_size}")
            print(f"OUTPUT:{out}")
        else:
            print("ERROR: No files processed"); sys.exit(1)
    except Exception as e:
        progress_finish("error", str(e))
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_repack.py"

# ═══════════════════════════════════════════════════════════════════════════
# 4. bot_inject.py (with progress)
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_inject.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, inject_edit_files
from progress_helper import progress_start, progress_update, progress_finish


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_inject.py <pak> [yes|no]"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    encrypt = len(sys.argv) > 2 and sys.argv[2].lower() in ('yes', 'y', '1')

    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty"); sys.exit(1)

    try:
        progress_start("INJECT", 100)
        progress_update(0, f"Loading {pak_path.name}")

        print(f"Injecting into: {pak_path.name}")
        pak = TencentPakFile(pak_path)

        edit_count = len([p for p in edit_dir.rglob('*') if p.is_file()])
        progress_start("INJECT", edit_count)
        progress_update(0, f"{edit_count} files to inject")

        out = result_dir / pak_path.name
        edited, added = inject_edit_files(pak, edit_dir, out, protect_new=encrypt, sm4_type=47)

        progress_update(edit_count, "Done")
        progress_finish("done", f"{edited + added} files processed")

        print("SUCCESS")
        print(f"EDITED:{edited}")
        print(f"ADDED:{added}")
        print(f"SIZE:{out.stat().st_size}")
        print(f"OUTPUT:{out}")
    except Exception as e:
        progress_finish("error", str(e))
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_inject.py"

# ═══════════════════════════════════════════════════════════════════════════
# 5. bot_protect.py (with progress)
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_protect.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, protect_pak_file
from progress_helper import progress_start, progress_update, progress_finish


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_protect.py <pak>"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)

    base = Path(__file__).parent
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    try:
        progress_start("PROTECT", 100)
        progress_update(0, f"Loading {pak_path.name}")

        print(f"Protecting: {pak_path.name}")
        pak = TencentPakFile(pak_path)

        total = sum(len(d) for d in pak._index.values())
        progress_start("PROTECT", total)

        out = result_dir / pak_path.name
        protected, skipped = protect_pak_file(pak, out, sm4_type=47)

        progress_update(total, "Done")
        progress_finish("done", f"{protected} files protected")

        print("SUCCESS")
        print(f"PROTECTED:{protected}")
        print(f"SKIPPED:{skipped}")
        print(f"SIZE:{out.stat().st_size}")
        print(f"OUTPUT:{out}")
    except Exception as e:
        progress_finish("error", str(e))
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_protect.py"

# ═══════════════════════════════════════════════════════════════════════════
# 6. bot_repack_path.py (without progress — simple)
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack_path.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full
from progress_helper import progress_start, progress_update, progress_finish


def main():
    if len(sys.argv) < 3:
        print("ERROR: Usage: bot_repack_path.py <pak> <target>"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    target = sys.argv[2].strip('/').replace('\\', '/')
    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)

    base = Path(__file__).parent
    edit_dir = base / "PAK TOOL" / "EDIT"
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    try:
        progress_start("REPACK TO PATH", 100)
        progress_update(0, f"Loading {pak_path.name}")

        pak = TencentPakFile(pak_path)
        edit_files = [p for p in edit_dir.rglob('*') if p.is_file()]
        progress_start("REPACK TO PATH", len(edit_files))

        out = result_dir / pak_path.name
        count = repack_pak_file_full(pak, edit_dir, out, target, force_add=True)

        progress_finish("done", f"{count} files -> {target}")
        if count > 0:
            print("SUCCESS")
            print(f"COUNT:{count}")
            print(f"SIZE:{out.stat().st_size}")
            print(f"TARGET:{target}")
            print(f"OUTPUT:{out}")
        else:
            print("ERROR: No files processed"); sys.exit(1)
    except Exception as e:
        progress_finish("error", str(e))
        print(f"ERROR: {e}"); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_repack_path.py"

# ═══════════════════════════════════════════════════════════════════════════
# 7. bot_compile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_compile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _compile_one_lua, _list_lua_files
from progress_helper import progress_start, progress_update, progress_finish


def main():
    base = Path(__file__).parent
    lua_dir = base / "LUA TOOL"
    tools_dir = lua_dir / "TOOLS"
    input_dir = lua_dir / "INPUT"
    output_dir = lua_dir / "COMPILE"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_dir.exists() or not any(input_dir.rglob('*.lua')):
        print("ERROR: INPUT folder empty"); sys.exit(1)

    tools = _find_lua_tool(tools_dir)
    if not (tools.get('luajit') or tools.get('luac')):
        print("ERROR: No Lua compiler"); sys.exit(1)

    files = _list_lua_files(input_dir)
    progress_start("COMPILE", len(files))

    ok = 0; fail = 0
    for i, src in enumerate(files, 1):
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        progress_update(i, str(rel))
        try:
            success, used = _compile_one_lua(src, out, tools)
            if success: ok += 1
            else: fail += 1
        except Exception:
            fail += 1

    progress_finish("done", f"{ok} ok, {fail} fail")
    print("SUCCESS" if ok > 0 else "ERROR")
    print(f"OK:{ok}")
    print(f"FAIL:{fail}")
    print(f"OUTPUT:{output_dir}")


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_compile.py"

# ═══════════════════════════════════════════════════════════════════════════
# 8. bot_decompile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_decompile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _decompile_one_lua, _list_lua_files
from progress_helper import progress_start, progress_update, progress_finish


def main():
    base = Path(__file__).parent
    lua_dir = base / "LUA TOOL"
    tools_dir = lua_dir / "TOOLS"
    input_dir = lua_dir / "INPUT"
    output_dir = lua_dir / "DECOMPILE"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_dir.exists() or not any(input_dir.rglob('*.lua')):
        print("ERROR: INPUT folder empty"); sys.exit(1)

    tools = _find_lua_tool(tools_dir)
    if not (tools.get('unluac') or tools.get('ljd')):
        print("ERROR: No decompiler"); sys.exit(1)

    files = _list_lua_files(input_dir)
    progress_start("DECOMPILE", len(files))

    ok = 0; fail = 0
    for i, src in enumerate(files, 1):
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        progress_update(i, str(rel))
        try:
            success, used = _decompile_one_lua(src, out, tools)
            if success: ok += 1
            else: fail += 1
        except Exception:
            fail += 1

    progress_finish("done", f"{ok} ok, {fail} fail")
    print("SUCCESS" if ok > 0 else "ERROR")
    print(f"OK:{ok}")
    print(f"FAIL:{fail}")
    print(f"OUTPUT:{output_dir}")


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_decompile.py"

# ═══════════════════════════════════════════════════════════════════════════
# 9. bot_delete.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_delete.py << 'PYEOF'
#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_delete.py <folder>"); sys.exit(1)
    folder_name = sys.argv[1]
    forbidden = ['PAK', 'UNPACK', 'REPACK', 'RESULT', 'PAK TOOL', 'LUA TOOL']
    if folder_name in forbidden:
        print(f"ERROR: Cannot delete protected: {folder_name}"); sys.exit(1)
    base = Path(__file__).parent
    target = base / folder_name
    if not target.exists():
        print(f"ERROR: Not found: {folder_name}"); sys.exit(1)
    if not target.is_dir():
        print(f"ERROR: Not a folder"); sys.exit(1)
    try:
        shutil.rmtree(target)
        print("SUCCESS")
        print(f"DELETED:{folder_name}")
    except Exception as e:
        print(f"ERROR: {e}"); sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_delete.py"

# ═══════════════════════════════════════════════════════════════════════════
# SYNTAX CHECK
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "Syntax check:"
for f in progress_helper.py bot_*.py; do
    python -m py_compile "$f" 2>&1 && echo "  ✓ $f" || echo "  ✗ $f"
done

echo ""
echo "════════════════════════════════════════════════"
echo "✓ All files created!"
echo "════════════════════════════════════════════════"

