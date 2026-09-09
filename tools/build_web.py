#!/usr/bin/env python3
"""Build the Safari/PWA bundle and its versioned, CDN-free offline game shell.
Pass Flutter options through, e.g. --base-href /hukuk_reels/.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
subprocess.run(['flutter', 'build', 'web', '--release', '--no-web-resources-cdn', *sys.argv[1:]], cwd=root, check=True)
out = root / 'build/web'
files = []
for path in sorted(out.rglob('*')):
    if not path.is_file():
        continue
    name = path.relative_to(out).as_posix()
    if name in {'sw.js', 'flutter_service_worker.js'} or name.endswith(('.map', '.DS_Store')):
        continue
    if name.startswith('assets/assets/audio/'):
        continue
    if name.startswith('canvaskit/') and name not in {'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'}:
        continue
    files.append(name)
hash_value = hashlib.sha256()
for name in files:
    hash_value.update(name.encode())
    hash_value.update((out / name).read_bytes())
source = (root / 'web/sw.js').read_text()
hash_value.update(source.encode())
worker = source.replace('__BUILD_VERSION__', hash_value.hexdigest()[:16]).replace('__CORE_FILES__', json.dumps(files))
(out / 'flutter_service_worker.js').write_text(worker)
(out / 'sw.js').unlink(missing_ok=True)
print(f'Offline game shell: {len(files)} files, {sum((out / f).stat().st_size for f in files) / 1024**2:.1f} MiB. Music requires a connection.')
