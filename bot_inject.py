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
