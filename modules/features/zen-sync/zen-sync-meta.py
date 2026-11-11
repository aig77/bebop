#!/usr/bin/env python3
"""Print zen-sync R2 metadata as JSON without exposing credentials on argv."""

import json
import os
import sys

sys.path.insert(0, os.environ["ZEN_SYNC_LIB"])

import cloud  # noqa: E402

config = {
    "account_id": os.environ["R2_ACCOUNT_ID"],
    "access_key": os.environ["R2_ACCESS_KEY"],
    "secret_key": os.environ["R2_SECRET_KEY"],
    "bucket": os.environ["R2_BUCKET"],
    "age_mode": os.environ.get("AGE_MODE", "keyfile"),
    "age_key_path": os.environ.get("AGE_KEY_PATH", ""),
    "config_dir": os.path.expanduser("~/.config/zen-sync"),
}

try:
    meta = cloud.cmd_status(config)
except Exception as exc:  # noqa: BLE001
    print(json.dumps({"error": str(exc)}))
    sys.exit(1)

if meta is None:
    print(json.dumps({"error": "no remote session"}))
else:
    print(json.dumps(meta))
