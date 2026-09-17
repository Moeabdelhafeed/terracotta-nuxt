# Live Audio Visualizer — Per-Platform Implementation Plan

The audio module currently ships:

- **`SyntheticBandExtractor`** — precomputed pseudo-bands derived from
  the decoded waveform envelope. Cross-platform today. Same shape
  every play of the same track. Wired through `bandStream` on
  `AudioPlayerHandle`.

This document plans the incremental path to *live* per-platform
visualization — bands derived from the actual audio output buffer in
real time, reacting to EQ, mixing, and platform effects.

The visualizer's `bandStream` is the integration seam — every path
below produces a `Stream<List<double>>` that the existing
`GlobalAudioVisualizer(bandStream: ...)` already consumes.

---

## Order of attack

Ranked by effort × value:

| # | Platform | Effort | Real-time? | Notes |
|---|----------|--------|------------|-------|
| 1 | Web | 1 day | ✅ | `AnalyserNode`, easiest win |
| 2 | Android | 1-2 days | ✅ | `android.media.audiofx.Visualizer` |
| 3 | True FFT (precomputed) | 2-3 days | ❌ (same as today) | Replace `Synthetic` with real FFT — gives true bands without going live |
| 4 | iOS | 3-5 days | ✅ | `MTAudioProcessingTap`, needs just_audio fork |
| 5 | macOS | shares with iOS | ✅ | Same code path as iOS |
| 6 | Windows / Linux | 1 week | ✅ | Player swap (`media_kit`) |

---

## Path 1 — Web

The Web Audio API gives a free real-time FFT via `AnalyserNode`. The
just_audio web plugin uses an `<audio>` element under the hood; we
can tap that element via `AudioContext.createMediaElementSource`.

### Steps

1. Add a thin JS-interop layer in
   `lib/shared/module/audio/audio_visualizer_web.dart` (compiled only
   on web via conditional imports).
2. On player init, find the `<audio>` element associated with the
   just_audio player. Options:
   - Hook into just_audio_web (small fork to expose the
     `HTMLAudioElement` ref), or
   - Walk the DOM for the single `<audio>` element after
     `setUrl()` resolves (works for one-player apps, fragile for
     many).
3. Build the audio graph:
   ```js
   const ctx = new (window.AudioContext || window.webkitAudioContext)();
   const src = ctx.createMediaElementSource(audioEl);
   const analyser = ctx.createAnalyser();
   analyser.fftSize = 256; // → 128 frequency bins
   analyser.smoothingTimeConstant = 0.7;
   src.connect(analyser);
   analyser.connect(ctx.destination); // pass-through so audio still plays
   ```
4. Each frame, call `analyser.getByteFrequencyData(buf)` and convert
   `Uint8Array(128)` → `List<double>` normalized 0..1.
5. Push into a `StreamController<List<double>>.broadcast()`. Expose
   it via the same `AudioPlayerHandle.bandStream` slot the player
   already declares.

### Caveats
- AudioContext requires a user gesture to start on most browsers.
  Lazy-init on first `play()`.
- iOS Safari is fussy about `createMediaElementSource` and CORS
  audio — set `audioEl.crossOrigin = 'anonymous'` and require the
  server to send proper CORS headers.

### Estimated LOC
- ~80 lines JS-interop wrapper
- ~30 lines Dart glue to wire it into the player state

---

## Path 2 — Android

Android ships the `Visualizer` API since API 9. It captures audio
from a session ID + delivers FFT samples to a listener. just_audio
exposes `player.androidAudioSessionId` for this purpose.

### Steps

1. Add `RECORD_AUDIO` permission to `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```
   Request at runtime via the existing `permission_handler`.
2. Create a minimal Flutter plugin under
   `android/app/src/main/kotlin/.../AudioFftPlugin.kt`:
   - Register `MethodChannel("app.audio.fft")` with `start(sessionId)`
     + `stop()`.
   - Register `EventChannel("app.audio.fft/bands")`.
   - On `start`, instantiate `Visualizer(sessionId)`:
     ```kotlin
     visualizer = Visualizer(sessionId).apply {
       captureSize = Visualizer.getCaptureSizeRange()[1] // 1024
       scalingMode = Visualizer.SCALING_MODE_NORMALIZED
       setDataCaptureListener(listener, Visualizer.getMaxCaptureRate() / 2,
         /* waveform= */ false, /* fft= */ true)
       enabled = true
     }
     ```
   - In the listener, convert interleaved Re/Im byte pairs to
     magnitudes, normalize 0..1, send the `FloatArray` via the event
     sink as `List<Double>`.
3. Bucket the raw FFT bins into `bandCount` logarithmic bands
   (matches human pitch perception — equal log-spacing not linear).
4. Dart side: `AudioVisualizerNativePlatform.instance =
   AndroidAudioFftPlatform();` — wires the EventChannel into a
   `Stream<List<double>>`.
5. In `GlobalAudioPlayer` state, on `play()` first call:
   `await native.start(sessionId: _player.androidAudioSessionId)`.
   On `dispose()`: `native.stop()`.

### Caveats
- Some OEMs lock the Visualizer API behind device policy. Always
  catch — fall back to `SyntheticBandExtractor` on failure.
- The `RECORD_AUDIO` permission is required even though we're reading
  output. Surface this in the UX *before* enabling the live mode.
- Stop the Visualizer when the player pauses to save CPU.

### Estimated LOC
- ~120 lines Kotlin
- ~50 lines Dart glue

---

## Path 3 — True precomputed FFT (cross-platform)

Replaces `SyntheticBandExtractor`'s envelope-based fake with real per-
frequency FFT bands. Still precomputed (not live) but truly spectral.

### Steps

1. Add deps:
   ```yaml
   fftea: ^1.5.0          # pure-Dart FFT
   ```
   For decode, pick one:
   - `ffmpeg_kit_flutter_new` — works for any format, ~50MB binary
   - `wav: ^1.4.0` — pure Dart, WAV-only
   - Platform-specific bridges + a single Dart interface
2. Implement `DecoderBandExtractor` (stub already exists in
   `audio_band_extractor.dart`):
   ```dart
   final pcm = await Decoder.decodeToMonoFloat32(source);
   final frameSize = pcm.sampleRate ~/ framesPerSec; // e.g. 50fps
   final fft = FFT(frameSize);
   final snapshots = <List<double>>[];
   for (var i = 0; i + frameSize <= pcm.samples.length; i += frameSize) {
     final slice = applyHann(pcm.samples.sublist(i, i + frameSize));
     final spectrum = fft.realFft(slice);
     final magnitudes = spectrum.discardConjugates().magnitudes();
     snapshots.add(logBucket(magnitudes, bandCount));
   }
   ```
3. Cache snapshots to disk keyed by source hash so the decode runs
   once per track.
4. Same `bandStream` integration as today — no widget changes.

### Caveats
- ffmpeg_kit_flutter_new adds significant install size — gate it
  behind a flavor or only ship to platforms that need it.
- Decode of long tracks blocks the isolate — run extraction in a
  worker isolate (`compute()` or `Isolate.run`).

### Estimated LOC
- ~200 lines extractor
- ~50 lines decoder bridge

---

## Path 4 — iOS

Most expensive path. `AVPlayerItem.audioMix` accepts an
`AVMutableAudioMix` with an `AVAudioMixInputParameters` carrying an
`MTAudioProcessingTap`. The tap delivers raw PCM via a C callback.

### Steps

1. Fork `just_audio_darwin` (or contribute upstream) to expose the
   `AVPlayerItem` to native code, **or** maintain a parallel
   AVPlayer for taps only.
2. Build the tap (Swift, calling into C functions):
   ```swift
   var callbacks = MTAudioProcessingTapCallbacks(
     version: kMTAudioProcessingTapCallbacksVersion_0,
     clientInfo: ...,
     init: tapInit, finalize: tapFinalize,
     prepare: tapPrepare, unprepare: tapUnprepare,
     process: tapProcess
   )
   var tap: Unmanaged<MTAudioProcessingTap>?
   MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks,
     kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
   ```
3. In `tapProcess`, call `MTAudioProcessingTapGetSourceAudio` to get
   buffers, then run FFT via `vDSP_fft_zrip` from `Accelerate`.
4. Convert to `List<Double>`, push through an EventChannel.

### Caveats
- `MTAudioProcessingTap` is C-API + reference-counted manually. Easy
  to leak / crash.
- Output flag `PostEffects` taps after Core Audio EQ — usually what
  the user expects.
- This entire path is shared with macOS.

### Estimated LOC
- ~300 lines Swift/C
- ~60 lines Dart glue

---

## Path 5 — Windows / Linux desktop

Native desktop audio capture isn't exposed by Flutter, and just_audio
desktop wraps libVLC / miniaudio without buffer hooks.

### Options

- **Swap player** to `media_kit` (libmpv-based) which exposes
  decoded audio frames via `--audio-pid` / Lua hooks. Big change,
  loses lock-screen integration just_audio provides via audio_service.
- **WASAPI loopback** (Windows) / **PulseAudio monitor** (Linux): tap
  the system output stream. Captures *all* audio, not just our
  player. Acceptable if the user understands that.

### Recommendation
Skip until requested. Most desktop audio apps don't need this.

---

## Integration architecture (shared across paths)

```
┌────────────────────────────┐
│ AudioVisualizerNative      │  abstract — already shipped
│ Platform                   │  in audio_visualizer_native.dart
│   - start()                │
│   - stop()                 │
│   - Stream<List<double>>   │
└──────────────┬─────────────┘
               │
       ┌───────┴────────┬─────────────────┐
       │                │                 │
┌──────▼──────┐  ┌──────▼──────┐   ┌──────▼──────┐
│ AndroidImpl │  │ WebImpl     │   │ iOSImpl     │
│ (Visualizer │  │ (Web Audio  │   │ (MTAudio    │
│  API)       │  │  Analyser)  │   │  ProcTap)   │
└─────────────┘  └─────────────┘  └─────────────┘
```

`GlobalAudioPlayer` picks the platform impl at runtime (`kIsWeb` /
`Platform.isAndroid` / etc.) and falls back to
`SyntheticBandExtractor` when no live impl is available.

The `AudioPlayerHandle.bandStream` consumers (i.e. the visualizer)
don't change — same widget, same API, just a richer source.

---

## Ship order recommendation

1. **Now**: SyntheticBandExtractor (DONE)
2. **+1 day**: Web via AnalyserNode (biggest reach, easiest impl)
3. **+1-2 days**: Android via Visualizer API
4. **+2-3 days**: True precomputed FFT (cross-platform fallback that
   beats synthetic on quality)
5. **+3-5 days**: iOS + macOS via MTAudioProcessingTap
6. Desktop: defer until asked
