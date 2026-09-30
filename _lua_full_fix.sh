#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  LUA COMPILE / DECOMPILE — FULL FIX"
echo "════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. FOLDERS BANAO
# ═══════════════════════════════════════════════════════════════════════════
mkdir -p "LUA TOOL/INPUT" "LUA TOOL/COMPILE" "LUA TOOL/DECOMPILE" "LUA TOOL/TOOLS"
echo "✓ Folders created"

# ═══════════════════════════════════════════════════════════════════════════
# 2. LUAJIT INSTALL (COMPILE KE LIYE)
# ═══════════════════════════════════════════════════════════════════════════
if ! command -v luajit >/dev/null 2>&1; then
    echo "📦 Installing LuaJIT..."
    pkg install luajit -y
fi

if command -v luajit >/dev/null 2>&1; then
    ln -sf "$(which luajit)" "LUA TOOL/TOOLS/luajit"
    echo "✓ LuaJIT: $(which luajit)"
else
    echo "✗ LuaJIT install FAILED"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 3. LUAC INSTALL (fallback)
# ═══════════════════════════════════════════════════════════════════════════
if ! command -v luac5.3 >/dev/null 2>&1; then
    echo "📦 Installing Lua 5.3..."
    pkg install lua53 -y
fi

if command -v luac5.3 >/dev/null 2>&1; then
    ln -sf "$(which luac5.3)" "LUA TOOL/TOOLS/luac5.3"
    echo "✓ luac5.3: $(which luac5.3)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. JAVA INSTALL (DECOMPILE KE LIYE)
# ═══════════════════════════════════════════════════════════════════════════
if ! command -v java >/dev/null 2>&1; then
    echo "📦 Installing Java..."
    pkg install openjdk-17 -y
fi

if command -v java >/dev/null 2>&1; then
    echo "✓ Java: $(java -version 2>&1 | head -1)"
else
    echo "⚠ Java not installed — decompile won't work"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 5. UNLUAC.JAR DOWNLOAD (DECOMPILE KE LIYE)
# ═══════════════════════════════════════════════════════════════════════════
UNLUAC_PATH="LUA TOOL/TOOLS/unluac.jar"

if [ ! -f "$UNLUAC_PATH" ] || [ $(stat -c%s "$UNLUAC_PATH" 2>/dev/null || echo 0) -lt 100000 ]; then
    echo "📦 Downloading unluac.jar..."
    rm -f "$UNLUAC_PATH"

    for url in \
        "https://github.com/scratchminer/unluac/releases/latest/download/unluac.jar" \
        "https://github.com/Jeong-Min-Cho/unluac/releases/latest/download/unluac.jar" \
        "https://github.com/FModel/unluac/releases/latest/download/unluac.jar"
    do
        echo "  Trying: $url"
        curl -L -f -s -o "$UNLUAC_PATH" "$url" 2>/dev/null
        SIZE=$(stat -c%s "$UNLUAC_PATH" 2>/dev/null || echo 0)
        if [ "$SIZE" -gt 100000 ]; then
            echo "  ✓ Downloaded ($((SIZE/1024)) KB)"
            break
        fi
        rm -f "$UNLUAC_PATH"
    done
fi

if [ -f "$UNLUAC_PATH" ]; then
    SIZE=$(stat -c%s "$UNLUAC_PATH")
    if [ "$SIZE" -gt 100000 ]; then
        echo "✓ unluac.jar: $((SIZE/1024)) KB"
    else
        echo "✗ unluac.jar too small"
        rm -f "$UNLUAC_PATH"
    fi
else
    echo "⚠ unluac.jar not found"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 6. TEST FILE BANAO
# ═══════════════════════════════════════════════════════════════════════════
if [ ! -f "LUA TOOL/INPUT/test.lua" ]; then
    cat > "LUA TOOL/INPUT/test.lua" << 'EOF'
-- NEXA CHEAT test file
local function greet(name)
    print("Hello, " .. name .. "!")
    return 42
end

greet("BGMI")
EOF
    echo "✓ test.lua created"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 7. COMPILE TEST
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "TEST: COMPILE"
echo "════════════════════════════════════════════════"

if command -v luajit >/dev/null 2>&1; then
    luajit -b "LUA TOOL/INPUT/test.lua" "LUA TOOL/COMPILE/test.lua" 2>&1
    if [ -f "LUA TOOL/COMPILE/test.lua" ]; then
        SIZE=$(stat -c%s "LUA TOOL/COMPILE/test.lua")
        echo "✓ COMPILE OK ($SIZE bytes)"
        xxd "LUA TOOL/COMPILE/test.lua" | head -1
    else
        echo "✗ COMPILE FAILED"
    fi
else
    echo "✗ LuaJIT not available"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 8. DECOMPILE TEST
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "TEST: DECOMPILE"
echo "════════════════════════════════════════════════"

if command -v java >/dev/null 2>&1 && [ -f "$UNLUAC_PATH" ]; then
    java -jar "$UNLUAC_PATH" "LUA TOOL/COMPILE/test.lua" > "LUA TOOL/DECOMPILE/test.lua" 2>&1
    if [ -f "LUA TOOL/DECOMPILE/test.lua" ] && [ $(stat -c%s "LUA TOOL/DECOMPILE/test.lua") -gt 10 ]; then
        echo "✓ DECOMPILE OK"
        head -5 "LUA TOOL/DECOMPILE/test.lua"
    else
        echo "⚠ DECOMPILE FAILED (expected for LuaJIT bytecode)"
        echo "  unluac sirf standard Lua ke liye hai"
        echo "  LuaJIT ke liye: luadec.metaworm.site"
        rm -f "LUA TOOL/DECOMPILE/test.lua"
    fi
else
    echo "⚠ Java ya unluac.jar missing"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 9. STATUS
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "STATUS"
echo "════════════════════════════════════════════════"
echo ""
echo "TOOLS:"
ls -la "LUA TOOL/TOOLS/"
echo ""
echo "INPUT:"
ls "LUA TOOL/INPUT/"
echo ""
echo "COMPILE:"
ls "LUA TOOL/COMPILE/"
echo ""
echo "DECOMPILE:"
ls "LUA TOOL/DECOMPILE/"
echo ""
echo "════════════════════════════════════════════════"
echo "✓ LUA FIX DONE"
echo "════════════════════════════════════════════════"

