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
