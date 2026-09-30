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
