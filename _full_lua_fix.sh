#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  COMPLETE LUA FIX — COMPILE + DECOMPILE"
echo "════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. Folders
# ═══════════════════════════════════════════════════════════════════════════
mkdir -p "LUA TOOL/INPUT" "LUA TOOL/COMPILE" "LUA TOOL/DECOMPILE" "LUA TOOL/TOOLS"
echo "✓ Folders created"

# ═══════════════════════════════════════════════════════════════════════════
# 2. LuaJIT install
# ═══════════════════════════════════════════════════════════════════════════
if ! command -v luajit >/dev/null 2>&1; then
    echo "📦 Installing LuaJIT..."
    pkg install luajit -y 2>&1 | tail -2
fi

if command -v luajit >/dev/null 2>&1; then
    ln -sf "$(which luajit)" "LUA TOOL/TOOLS/luajit"
    echo "✓ LuaJIT linked"
else
    echo "✗ LuaJIT FAILED"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 3. Java install
# ═══════════════════════════════════════════════════════════════════════════
if ! command -v java >/dev/null 2>&1; then
    echo "📦 Installing Java..."
    pkg install openjdk-17 -y 2>&1 | tail -2
fi

if command -v java >/dev/null 2>&1; then
    echo "✓ Java installed"
else
    echo "✗ Java FAILED"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. unluac.jar download
# ═══════════════════════════════════════════════════════════════════════════
UNLUAC="LUA TOOL/TOOLS/unluac.jar"
if [ ! -f "$UNLUAC" ] || [ $(stat -c%s "$UNLUAC" 2>/dev/null || echo 0) -lt 100000 ]; then
    echo "📦 Downloading unluac.jar..."
    rm -f "$UNLUAC"
    for url in \
        "https://github.com/scratchminer/unluac/releases/latest/download/unluac.jar" \
        "https://github.com/Jeong-Min-Cho/unluac/releases/latest/download/unluac.jar"
    do
        curl -L -f -s -o "$UNLUAC" "$url" 2>/dev/null
        SIZE=$(stat -c%s "$UNLUAC" 2>/dev/null || echo 0)
        [ "$SIZE" -gt 100000 ] && break
        rm -f "$UNLUAC"
    done
fi

[ -f "$UNLUAC" ] && echo "✓ unluac.jar: $(( $(stat -c%s "$UNLUAC") / 1024 )) KB"

# ═══════════════════════════════════════════════════════════════════════════
# 5. Rewrite bot_compile.py — with error reporting
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

    # CLEAN output
    if output_dir.exists():
        try:
            shutil.rmtree(output_dir)
        except Exception:
            pass
    output_dir.mkdir(parents=True, exist_ok=True)

    # CHECK input
    if not input_dir.exists():
        print("ERROR: LUA TOOL/INPUT folder not found")
        sys.exit(1)

    files = _list_lua_files(input_dir)
    if not files:
        print("ERROR: No .lua files in LUA TOOL/INPUT/")
        print("INFO: Put readable .lua source files in LUA TOOL/INPUT/")
        sys.exit(1)

    # FIND tools
    tools = _find_lua_tool(tools_dir)
    print("INFO: Tools found:")
    for k, v in tools.items():
        if v:
            print("  {} = {}".format(k, v))

    if not (tools.get('luajit') or tools.get('luac')):
        print("ERROR: No Lua compiler in LUA TOOL/TOOLS/")
        print("INFO: Install with: pkg install luajit")
        sys.exit(1)

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
                print("OK: {} ({})".format(rel, used))
            else:
                fail += 1
                print("FAIL: {} ({})".format(rel, used))
        except Exception as e:
            fail += 1
            print("FAIL: {} ({})".format(rel, str(e)[:100]))

    progress_finish("done", "{} ok, {} fail".format(ok, fail))
    print()
    print("SUCCESS" if ok > 0 else "ERROR")
    print("OK:{}".format(ok))
    print("FAIL:{}".format(fail))
    print("OUTPUT:{}".format(output_dir))


if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_compile.py
python -m py_compile bot_compile.py && echo "✓ bot_compile.py updated"

# ═══════════════════════════════════════════════════════════════════════════
# 6. Rewrite bot_decompile.py
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

    # CLEAN output
    if output_dir.exists():
        try:
            shutil.rmtree(output_dir)
        except Exception:
            pass
    output_dir.mkdir(parents=True, exist_ok=True)

    # CHECK input
    if not input_dir.exists():
        print("ERROR: LUA TOOL/INPUT folder not found")
        sys.exit(1)

    files = _list_lua_files(input_dir)
    if not files:
        print("ERROR: No .lua files in LUA TOOL/INPUT/")
        sys.exit(1)

    # FIND tools
    tools = _find_lua_tool(tools_dir)
    print("INFO: Tools found:")
    for k, v in tools.items():
        if v:
            print("  {} = {}".format(k, v))

    if not (tools.get('unluac') or tools.get('ljd')):
        print("ERROR: No decompiler in LUA TOOL/TOOLS/")
        print("INFO: Need unluac.jar (for standard Lua)")
        sys.exit(1)

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
                print("OK: {} ({})".format(rel, used))
            else:
                fail += 1
                print("FAIL: {} ({})".format(rel, used))
        except Exception as e:
            fail += 1
            print("FAIL: {} ({})".format(rel, str(e)[:100]))

    progress_finish("done", "{} ok, {} fail".format(ok, fail))
    print()
    print("SUCCESS" if ok > 0 else "ERROR")
    print("OK:{}".format(ok))
    print("FAIL:{}".format(fail))
    print("OUTPUT:{}".format(output_dir))


if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_decompile.py
python -m py_compile bot_decompile.py && echo "✓ bot_decompile.py updated"

# ═══════════════════════════════════════════════════════════════════════════
# 7. Test with sample
# ═══════════════════════════════════════════════════════════════════════════
cat > "LUA TOOL/INPUT/test.lua" << 'EOF'
-- NEXA CHEAT test
local function hello(name)
    print("Hello, " .. name .. "!")
    return 42
end
hello("BGMI")
EOF

echo ""
echo "════════════════════════════════════════════════"
echo "TEST: COMPILE"
echo "════════════════════════════════════════════════"
python bot_compile.py 2>&1

echo ""
echo "════════════════════════════════════════════════"
echo "TEST: DECOMPILE"
echo "════════════════════════════════════════════════"
python bot_decompile.py 2>&1

# ═══════════════════════════════════════════════════════════════════════════
# 8. Final status
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "FINAL STATUS"
echo "════════════════════════════════════════════════"
echo ""
echo "TOOLS:"
ls -la "LUA TOOL/TOOLS/" 2>/dev/null
echo ""
echo "INPUT:"
ls "LUA TOOL/INPUT/" 2>/dev/null
echo ""
echo "COMPILE:"
ls "LUA TOOL/COMPILE/" 2>/dev/null
echo ""
echo "DECOMPILE:"
ls "LUA TOOL/DECOMPILE/" 2>/dev/null
echo ""
echo "════════════════════════════════════════════════"
echo "✓ FIX DONE"
echo "════════════════════════════════════════════════"

