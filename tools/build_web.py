#!/usr/bin/env python3
"""Build the Safari/PWA bundle and its versioned, CDN-free offline game shell.
Pass Flutter options through, e.g. --base-href /hukuk_reels/.
"""
import hashlib
import json
import shutil
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
# --wasm: main.dart.wasm (skwasm) and main.dart.js (CanvasKit) side by side;
# web/flutter_bootstrap.js picks one (Settings → App lets Safari opt in).
subprocess.run(['flutter', 'build', 'web', '--release', '--wasm', '--no-web-resources-cdn', *sys.argv[1:]], cwd=root, check=True)
# Safari has no Chromium break iterators, so it loads skwasm_heavy; Chrome loads skwasm.
wasm_files = ['main.dart.mjs', 'main.dart.wasm', *(f'canvaskit/{n}' for n in (
    'skwasm.js', 'skwasm.wasm', 'skwasm_heavy.js', 'skwasm_heavy.wasm'))]
out = root / 'build/web'
# Never loaded (flutter_bootstrap.js asks for the 'full' CanvasKit and does not
# enable wimp; .symbols are only for debugging). Dropping them keeps the Pages
# upload ~19 MB smaller, which makes GitHub's file sync faster.
for unused in ['canvaskit/chromium', 'canvaskit/wimp.js', 'canvaskit/wimp.wasm', *(
        p.relative_to(out).as_posix() for p in out.rglob('*.symbols'))]:
    target = out / unused
    if target.is_dir():
        shutil.rmtree(target)
    else:
        target.unlink(missing_ok=True)
files = []
for path in sorted(out.rglob('*')):
    if not path.is_file():
        continue
    name = path.relative_to(out).as_posix()
    if name in {'sw.js', 'flutter_service_worker.js'} or name.endswith(('.map', '.DS_Store')):
        continue
    if name.startswith('assets/assets/audio/'):
        continue
    if name in wasm_files:
        continue
    if name.startswith('canvaskit/') and name not in {'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'}:
        continue
    files.append(name)
missing = [name for name in wasm_files if not (out / name).is_file()]
if missing:
    sys.exit(f'WebAssembly build is missing {missing}')
hash_value = hashlib.sha256()
for name in files + wasm_files:
    hash_value.update(name.encode())
    hash_value.update((out / name).read_bytes())
source = (root / 'web/sw.js').read_text()
hash_value.update(source.encode())
version = hash_value.hexdigest()[:16]
index = out / 'index.html'
index.write_text(index.read_text().replace('__BUILD_VERSION__', version))
worker = (source.replace('__BUILD_VERSION__', version).replace('__CORE_FILES__', json.dumps(files))
          .replace('__WASM_FILES__', json.dumps(wasm_files)))
(out / 'flutter_service_worker.js').write_text(worker)
(out / 'sw.js').unlink(missing_ok=True)
size = lambda names: sum((out / f).stat().st_size for f in names) / 1024**2
print(f'Offline game shell: {len(files)} files, {size(files):.1f} MiB (+{size(wasm_files):.1f} MiB WebAssembly engine '
      'where chosen). Music requires a connection.')
