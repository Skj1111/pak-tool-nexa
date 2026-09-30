#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from tool import TencentPakFile, dump_unpacking_log
from progress_helper import progress_start, progress_update, progress_finish, reset_progress


def main():
    reset_progress()

    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_unpack.py <pak>")
        sys.exit(1)
    pak_path = Path(sys.argv[1])
    if not pak_path.exists():
        print("ERROR: Not found: {}".format(pak_path))
        sys.exit(1)

    base = Path(__file__).parent
    unpack_path = base / "UNPACK" / pak_path.stem

    if unpack_path.exists():
        try:
            shutil.rmtree(unpack_path)
        except Exception:
            pass

    try:
        print("Unpacking: {}".format(pak_path.name))

        # QUICK count first
        progress_start("UNPACK", 0)
        progress_update(0, "Reading index...")

        pak = TencentPakFile(pak_path)
        total = sum(len(d) for d in pak._index.values())

        # Set TOTAL now
        progress_start("UNPACK", total)
        progress_update(0, "Starting...")

        original = pak._write_to_disk
        counter = [0]

        def tracked(file_path, entry):
            counter[0] += 1
            progress_update(counter[0], file_path.name)
            return original(file_path, entry)

        pak._write_to_disk = tracked
        pak.dump(unpack_path)

        progress_update(total, "Done")
        progress_finish("done", "{} files".format(total))
        print("SUCCESS")
        print("FILES:{}".format(total))
        print("OUTPUT:{}".format(unpack_path))
    except Exception as e:
        progress_finish("error", str(e))
        print("ERROR: {}".format(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
