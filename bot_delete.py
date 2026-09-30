#!/usr/bin/env python3
import sys
import shutil
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print("ERROR: Usage: bot_delete.py <folder>")
        sys.exit(1)
    folder_name = sys.argv[1]
    forbidden = ['PAK', 'UNPACK', 'REPACK', 'RESULT', 'PAK TOOL', 'LUA TOOL']
    if folder_name in forbidden:
        print("ERROR: Cannot delete protected: {}".format(folder_name))
        sys.exit(1)
    base = Path(__file__).parent
    target = base / folder_name
    if not target.exists():
        print("ERROR: Not found: {}".format(folder_name))
        sys.exit(1)
    if not target.is_dir():
        print("ERROR: Not a folder")
        sys.exit(1)
    try:
        shutil.rmtree(target)
        print("SUCCESS")
        print("DELETED:{}".format(folder_name))
    except Exception as e:
        print("ERROR: {}".format(e))
        sys.exit(1)


if __name__ == '__main__':
    main()
