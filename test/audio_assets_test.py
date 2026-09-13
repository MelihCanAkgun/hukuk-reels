"""Run with python3 test/audio_assets_test.py; uses existing ffprobe/ffmpeg tools."""
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
config = (root / 'lib/core/config/app_config.dart').read_text()
tracks = re.findall(r"'([^']+\.m4a)'", config.split('musicTracks = [')[1].split('];')[0])
for name in tracks:
    path = root / name
    info = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-select_streams', 'a:0',
        '-show_entries', 'stream=codec_name,sample_rate,channels', '-of', 'json', str(path),
    ]))['streams'][0]
    assert info == {'codec_name': 'aac', 'sample_rate': '48000', 'channels': 2}, (name, info)
    subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-xerror', '-i', str(path),
                    '-map', '0:a:0', '-f', 'null', '-'], check=True)
print(f'{len(tracks)} playlist assets: AAC stereo 48 kHz, complete decode passed.')
