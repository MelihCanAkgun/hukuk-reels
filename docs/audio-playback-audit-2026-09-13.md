# Audio playback investigation — 2026-09-13

## Findings and limits

The reported temporary vocal pitch/tempo change has **not been reproduced or proven fixed**. The smallest mitigation is shipped: normalize the 14 existing playlist files from 32 kHz to 48 kHz AAC, keeping filenames and playlist order. No audio graph, gameplay, multiplayer, SFX implementation or dependency changes.

- `audio_service.dart`: one music `AudioPlayer`, no `setSpeed` or pitch calls. `just_audio_web 0.4.16` initializes `_speed = 1.0` and writes that value on track load/canplaythrough. No music call changes it.
- `web/audio.js`: iOS-only `HTMLMediaElement.play` wrapper routes AUDIO elements through `createMediaElementSource` → music GainNode → destination. SFX use separate BufferSource nodes and their own GainNode in the **same** AudioContext. Non-iOS music uses the native element path.
- `playbackRate` modifications belong to individual SFX BufferSource nodes. Native SFX use separate players' `setSpeed`. Combo rate increases do not modify music playback rate. No app writes to `detune`, `preservesPitch` or `webkitPreservesPitch` were found.
- Block Blast triggers place/clear/combo after placement, gameOver on loss. Rendering and drag updates exist, but code inspection does not prove audio starvation or clock drift.
- ffprobe: all 14 playlist tracks were AAC stereo **32000 Hz**; all four SFX were mono PCM WAV **44100 Hz**. Five additional untracked files outside the playlist are **44100 Hz** and were left untouched and excluded from publication.
- `new AudioContext()` has no requested sample rate. The actual value is device/output dependent. Local macOS Playwright WebKit 26.5 reported **48000 Hz**; all four decoded SFX buffers also reported **48000 Hz**. Thus 44.1 kHz SFX are resampled during decode, not freshly decoded on each effect.

Gemini's graph description and file rates were correct (indeed all playlist files were 32 kHz). Its fixed 48 kHz assumption is device dependent. Its resampling/clock starvation explanation is plausible but **unconfirmed**, not an established root cause. The [Web Audio specification](https://webaudio.github.io/web-audio-api/#MediaElementAudioSourceNode) requires resampling when media and context sample rates differ; this does not mean resampling normally changes pitch. [Apple's iOS audio documentation](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/Using_HTML5_Audio_Video/Device-SpecificConsiderations/Device-SpecificConsiderations.html) explains the native volume restriction, so removing the music GainNode would risk breaking the working iOS volume control without proven benefit.

## Applied change

14 playlist assets converted with the existing ffmpeg executable:

```sh
ffmpeg -nostdin -v error -i ORIGINAL.m4a -map 0:a:0 -c:a aac -profile:a aac_low -ar 48000 -b:a 128k -movflags +faststart OUTPUT.m4a
```

No `asetrate`, speed or pitch filters. AAC is re-encoded, so this is lossy and cannot add source fidelity. Container duration differences are under 0.1 seconds (AAC priming/start timestamp handling), not a tempo change. Originals are retained in git history and `/private/tmp/hukuk-audio-originals` for the local A/B check.

`audio_service.dart` appends `?audio=48k-v1` to web music URLs so HTTP/range caches cannot reuse the old encoding; native asset references and playlist names remain unchanged. Audio routing, volume, pause/resume and track selection code remain unchanged. Matching 48 kHz removes the media/context sample-rate mismatch on measured 48 kHz output; other devices/output routes can still resample.

## Validation

- `flutter test`: **74 passed**.
- `flutter analyze`: **no issues**.
- `node test/web_runtime_test.cjs`: passed, including 100 consecutive SFX rate changes leaving music rate/pitch-preservation and gains intact. These are mocked runtime checks, not acoustic measurements.
- `node test/web_update_test.cjs`: passed.
- `python3 test/audio_assets_test.py`: **14 AAC stereo 48 kHz files**, each decoded end-to-end without errors using ffmpeg.
- `python3 tools/build_web.py --base-href /hukuk-reels/`: release build passed, 47 offline shell files, 15.7 MiB; music stays streamed on demand.
- Real WebKit service-worker test: old→new version with HTTP cache enabled, fresh cached content, **one reload**, success notification, no recurring update button. Card visually inspected.
- Local WebKit with iPhone 14 Pro emulation: original 32 kHz Wildflower versus its 48 kHz conversion on the normal screen and Block Blast, including synthetic drag input and repeated place/combo SFX every 70 ms. Music used an instrumented HTMLAudioElement through the app's actual iOS audio bridge. Playback rate stayed 1.0; media time progressed near wall-clock rate; pause/resume, changing source and GainNode volume passed. This exercises the media pipeline, **not every Flutter music UI interaction**.
- A separate real Flutter music-panel check passed: play, pause, resume, next, previous, versioned track URLs, and volume slider (observed music gain 0.7076). This is still emulated WebKit, not a physical iPhone.
- Both 32 kHz and 48 kHz passed the timing checks: this comparison **does not establish resampling as the cause**. `currentTime` is not a measurement of output waveform pitch. No physical iPhone, installed iOS PWA, long-duration gameplay, Bluetooth route change or speaker capture was available. Audible tempo/pitch and physical iOS regression verification remain outstanding.

Prior update work is included: `web/index.html`, `web/update.js`, `web/update.css`, `web/sw.js`, `tools/build_web.py`, and update/runtime tests. The worker uses cache-reload install requests and a build-version handshake; the card has applying/retry states and a post-reload verified success message.

## Publication

- Source: `fdfad6b`; gh-pages: `c7fac473f6eea44c4beb74a445b1a0693d6b8e54`; app build: `49564a69449af093`.
- [GitHub Pages run 34746559209](https://github.com/MelihCanAkgun/hukuk-reels/actions/runs/34746559209): success.
- Clean source archive used the workspace’s tested `pubspec.lock`; every resolved package URI was compared and matched. No dependency upgrades shipped.
- Live SHA-256 verification passed for index, main JS, service worker, update JS/CSS, audio JS, deployment metadata and all 14 playlist files (21 files total).
- [Live application](https://melihcanakgun.github.io/hukuk-reels/). No backend deployment.

## Converted filenames

All paths below are under `assets/audio/`; each changed from AAC stereo 32000 Hz to AAC stereo 48000 Hz.

- `Wildflower.m4a`
- `Dolu_Kadehi_Ters_Tut.m4a`
- `Sad_Girl.m4a`
- `Takil_Yani_Takmiyo_Belli.m4a`
- `Aramizda_Dinozor.m4a`
- `Bari_Ruyalarima_Gel_Be.m4a`
- `Bekledigim_Gibiyim.m4a`
- `Degistim.m4a`
- `Far_From_Any_Road.m4a`
- `Gunduz_Yuzlu_Kiz.m4a`
- `O_Ben_Olurum.m4a`
- `Sadece_Senin_Olmak.m4a`
- `Sahte_Dualar.m4a`
- `Zaman_Yok.m4a`
