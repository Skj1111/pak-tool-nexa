#!/data/data/com.termux/files/usr/bin/bash
cd ~/pak-tool-nexa

echo "════════════════════════════════════════════════"
echo "  NEXA CHEAT - INJECT + REPACK TO PATH FIX"
echo "════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. bot_inject.py — clean output folder
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

    # Clean old result PAK if exists
    old_result = result_dir / pak_path.name
    if old_result.exists():
        try:
            old_result.unlink()
        except Exception:
            pass

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty")
        sys.exit(1)

    try:
        progress_start("INJECT", 100)
        progress_update(0, "Loading " + pak_path.name)

        print("Injecting into: {}".format(pak_path.name))
        pak = TencentPakFile(pak_path)

        edit_count = len([p for p in edit_dir.rglob('*') if p.is_file()])
        progress_start("INJECT", edit_count)
        progress_update(0, "{} files".format(edit_count))

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
# 2. bot_repack_path.py — clean output folder
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

    # Clean old result PAK if exists
    old_result = result_dir / pak_path.name
    if old_result.exists():
        try:
            old_result.unlink()
        except Exception:
            pass

    if not edit_dir.exists() or not any(edit_dir.iterdir()):
        print("ERROR: EDIT folder empty")
        sys.exit(1)

    try:
        progress_start("REPACK TO PATH", 100)
        progress_update(0, "Loading " + pak_path.name)

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
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
PYEOF
echo "✓ bot_repack_path.py"

# ═══════════════════════════════════════════════════════════════════════════
# SYNTAX CHECK
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════════"
echo "Syntax check:"
for f in bot_inject.py bot_repack_path.py; do
    python -m py_compile "$f" 2>&1 && echo "  ✓ $f" || echo "  ✗ $f"
done
echo "════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════════════════════
# STATUS CHECK
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "PAK TOOL status:"
echo ""
echo "PAK TOOL/PAK:"
ls "PAK TOOL/PAK/" 2>/dev/null | head -5 || echo "  (empty)"
echo ""
echo "PAK TOOL/EDIT:"
ls "PAK TOOL/EDIT/" 2>/dev/null | head -5 || echo "  (empty)"
echo ""

echo "════════════════════════════════════════════════"
echo "✓ FIX DONE"
echo "════════════════════════════════════════════════"

