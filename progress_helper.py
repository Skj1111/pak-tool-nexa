#!/usr/bin/env python3
"""Progress tracker for bot scripts."""
import time
from pathlib import Path

PROGRESS_FILE = Path.home() / ".nexa_progress"


def reset_progress():
    """Delete progress file — call at script start."""
    try:
        if PROGRESS_FILE.exists():
            PROGRESS_FILE.unlink()
    except Exception:
        pass


def _read():
    try:
        if not PROGRESS_FILE.exists():
            return {}
        data = {}
        for line in PROGRESS_FILE.read_text(encoding='utf-8').splitlines():
            if ':' in line:
                k, _, v = line.partition(':')
                data[k.strip()] = v.strip()
        return data
    except Exception:
        return {}


def _write(data):
    try:
        out = "\n".join("{}:{}".format(k, v) for k, v in data.items()) + "\n"
        PROGRESS_FILE.write_text(out, encoding='utf-8')
    except Exception:
        pass


def progress_start(task_name, total=0):
    # Always reset first
    reset_progress()
    _write({
        'TASK': task_name,
        'CURRENT': '0',
        'TOTAL': str(total),
        'STATUS': 'running',
        'STARTED': str(int(time.time())),
        'CURRENT_ITEM': '',
    })


def progress_update(current, item=""):
    data = _read()
    if not data:
        return
    data['CURRENT'] = str(current)
    if item:
        data['CURRENT_ITEM'] = item.replace('\n', ' ')[:80]
    _write(data)


def progress_finish(status="done", message=""):
    data = _read()
    if not data:
        return
    data['STATUS'] = status
    if message:
        data['MESSAGE'] = message.replace('\n', ' ')[:100]
    _write(data)


def progress_read():
    return _read()
