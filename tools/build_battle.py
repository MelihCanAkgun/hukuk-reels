#!/usr/bin/env python3
"""Compile the SAME pure Dart rules used by Flutter for the Worker runtime."""
from pathlib import Path
import subprocess
import hashlib
import json

root = Path(__file__).resolve().parents[1]
out = root / 'backend/generated/battle_rules.js'
subprocess.run(['dart', 'compile', 'js', '-O2', '--no-source-maps',
                '-o', str(out), str(root / 'backend/dart/battle_rules.dart')], cwd=root, check=True)
sources = ['lib/features/game/block_blast_engine.dart', 'lib/features/game/block_battle_core.dart',
           'backend/dart/battle_rules.dart']
(root / 'backend/generated/battle_rules.sources.json').write_text(json.dumps(
    {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in sources}, indent=2) + '\n')
# The compilation dependency list is local machine-specific.
out.with_suffix('.js.deps').unlink(missing_ok=True)
