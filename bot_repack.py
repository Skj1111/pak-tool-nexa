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
