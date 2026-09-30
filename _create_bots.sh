#!/data/data/com.termux/files/usr/bin/bash
# Creates all bot_*.py standalone scripts

cd ~/pak-tool-nexa

# ═══════════════════════════════════════════════════════════════════════════
# 1. bot_unpack.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_unpack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, dump_unpacking_log

def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_unpack.py <pak>"); sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print(f"ERROR: Not found: {pak_path}"); sys.exit(1)
    base = Path(__file__).parent
    unpack_path = base / "UNPACK" / pak_path.stem
    try:
        print(f"Unpacking: {pak_path.name}")
        pak = TencentPakFile(pak_path)
        pak.dump(unpack_path)
        try:
            log_path = unpack_path / f'Debug_{pak_path.stem}.log'
            dump_unpacking_log(pak, log_path)
        except Exception:
            pass
        file_count = sum(len(d) for d in pak._index.values())
        print("SUCCESS")
        print(f"FILES:{file_count}")
        print(f"OUTPUT:{unpack_path}")
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_unpack.py

# ═══════════════════════════════════════════════════════════════════════════
# 2. bot_inject.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_inject.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, inject_edit_files

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
        print(f"Injecting into: {pak_path.name}")
        pak = TencentPakFile(pak_path)
        out = result_dir / pak_path.name
        edited, added = inject_edit_files(pak, edit_dir, out, protect_new=encrypt, sm4_type=47)
        print("SUCCESS")
        print(f"EDITED:{edited}")
        print(f"ADDED:{added}")
        print(f"SIZE:{out.stat().st_size}")
        print(f"OUTPUT:{out}")
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_inject.py

# ═══════════════════════════════════════════════════════════════════════════
# 3. bot_repack.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full

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
        print(f"Repacking: {pak_path.name}")
        pak = TencentPakFile(pak_path)
        out = result_dir / pak_path.name
        count = repack_pak_file_full(pak, edit_dir, out)
        if count > 0:
            print("SUCCESS")
            print(f"COUNT:{count}")
            print(f"SIZE:{out.stat().st_size}")
            print(f"OUTPUT:{out}")
        else:
            print("ERROR: No files processed"); sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_repack.py

# ═══════════════════════════════════════════════════════════════════════════
# 4. bot_repack_path.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_repack_path.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, repack_pak_file_full

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
    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty"); sys.exit(1)
    try:
        print(f"Repacking {pak_path.name} -> {target}")
        pak = TencentPakFile(pak_path)
        out = result_dir / pak_path.name
        count = repack_pak_file_full(pak, edit_dir, out, target, force_add=True)
        if count > 0:
            print("SUCCESS")
            print(f"COUNT:{count}")
            print(f"SIZE:{out.stat().st_size}")
            print(f"TARGET:{target}")
            print(f"OUTPUT:{out}")
        else:
            print("ERROR: No files processed"); sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_repack_path.py

# ═══════════════════════════════════════════════════════════════════════════
# 5. bot_protect.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_protect.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, protect_pak_file

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
        print(f"Protecting: {pak_path.name}")
        pak = TencentPakFile(pak_path)
        out = result_dir / pak_path.name
        protected, skipped = protect_pak_file(pak, out, sm4_type=47)
        print("SUCCESS")
        print(f"PROTECTED:{protected}")
        print(f"SKIPPED:{skipped}")
        print(f"SIZE:{out.stat().st_size}")
        print(f"OUTPUT:{out}")
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback; traceback.print_exc(); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_protect.py

# ═══════════════════════════════════════════════════════════════════════════
# 6. bot_compile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_compile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _compile_one_lua, _list_lua_files

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
        print("ERROR: No Lua compiler found"); sys.exit(1)
    files = _list_lua_files(input_dir)
    ok = 0; fail = 0
    for src in files:
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        try:
            success, used = _compile_one_lua(src, out, tools)
            if success: ok += 1
            else: fail += 1
        except Exception:
            fail += 1
    print("SUCCESS" if ok > 0 else "ERROR")
    print(f"OK:{ok}")
    print(f"FAIL:{fail}")
    print(f"OUTPUT:{output_dir}")

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_compile.py

# ═══════════════════════════════════════════════════════════════════════════
# 7. bot_decompile.py
# ═══════════════════════════════════════════════════════════════════════════
cat > bot_decompile.py << 'PYEOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import _find_lua_tool, _decompile_one_lua, _list_lua_files

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
        print("ERROR: No decompiler found"); sys.exit(1)
    files = _list_lua_files(input_dir)
    ok = 0; fail = 0
    for src in files:
        rel = src.relative_to(input_dir)
        out = output_dir / rel
        try:
            success, used = _decompile_one_lua(src, out, tools)
            if success: ok += 1
            else: fail += 1
        except Exception:
            fail += 1
    print("SUCCESS" if ok > 0 else "ERROR")
    print(f"OK:{ok}")
    print(f"FAIL:{fail}")
    print(f"OUTPUT:{output_dir}")

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_decompile.py

# ═══════════════════════════════════════════════════════════════════════════
# 8. bot_delete.py
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
        print(f"ERROR: Cannot delete protected folder: {folder_name}"); sys.exit(1)
    base = Path(__file__).parent
    target = base / folder_name
    if not target.exists():
        print(f"ERROR: Not found: {folder_name}"); sys.exit(1)
    if not target.is_dir():
        print(f"ERROR: Not a folder: {folder_name}"); sys.exit(1)
    try:
        shutil.rmtree(target)
        print("SUCCESS")
        print(f"DELETED:{folder_name}")
    except Exception as e:
        print(f"ERROR: {e}"); sys.exit(1)

if __name__ == '__main__':
    main()
PYEOF
chmod +x bot_delete.py

echo ""
echo "════════════════════════════════════════════════"
echo "✓ All 8 bot scripts created"
echo "════════════════════════════════════════════════"
ls -la bot_*.py

