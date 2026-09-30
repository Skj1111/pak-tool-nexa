#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  NEXA CHEAT - LUA FIX"
echo "════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════════════════════
# 1. bot_compile.py — fresh output
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

    # CLEAN old output folder
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
# 2. bot_decompile.py — fresh output
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

    # CLEAN old output folder
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
# SYNTAX CHECK
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "Syntax check:"
for f in bot_compile.py bot_decompile.py; do
    python -m py_compile "$f" 2>&1 && echo "  ✓ $f" || echo "  ✗ $f"
done
echo "════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════════════════════
# TEST — Lua files check
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "LUA TOOL folder status:"
echo ""
echo "INPUT:"
ls -la "LUA TOOL/INPUT/" 2>/dev/null || echo "  (empty or missing)"
echo ""
echo "TOOLS:"
ls -la "LUA TOOL/TOOLS/" 2>/dev/null || echo "  (empty or missing)"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST — Run compile if input files exist
# ═══════════════════════════════════════════════════════════════════════════
LUA_COUNT=$(ls "LUA TOOL/INPUT/"*.lua 2>/dev/null | wc -l)
if [ "$LUA_COUNT" -gt 0 ]; then
    echo "════════════════════════════════════════════════"
    echo "TEST — COMPILE (input has $LUA_COUNT lua files)"
    echo "════════════════════════════════════════════════"
    rm -f ~/.nexa_progress
    python bot_compile.py 2>&1 | tail -5
    echo ""
    echo "COMPILE output:"
    ls "LUA TOOL/COMPILE/" 2>/dev/null | head -5
    echo ""
else
    echo "⚠ No .lua files in LUA TOOL/INPUT/"
    echo "  Upload lua files to Telegram bot first"
fi

echo "════════════════════════════════════════════════"
echo "✓ LUA FIX DONE"
echo "════════════════════════════════════════════════"

