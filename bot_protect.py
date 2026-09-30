#!/usr/bin/env python3
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, protect_pak_file
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_protect.py <pak>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    result_dir = base / "PAK TOOL" / "RESULT"
    result_dir.mkdir(parents=True, exist_ok=True)

    old = result_dir / pak_path.name
    if old.exists():
        try:
            old.unlink()
        except Exception:
            pass

    try:
        print("Protecting: {}".format(pak_path.name))

        progress_start("PROTECT", 0)
        progress_update(0, "Loading PAK...")

        pak = TencentPakFile(pak_path)
        total = sum(len(d) for d in pak._index.values())

        progress_start("PROTECT", total)
        progress_update(0, "Encrypting...")

        out = result_dir / pak_path.name
        protected, skipped = protect_pak_file(pak, out, sm4_type=47)

        progress_update(total, "Done")
        progress_finish("done", "{} files".format(protected))

        print("SUCCESS")
        print("PROTECTED:{}".format(protected))
        print("SKIPPED:{}".format(skipped))
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
