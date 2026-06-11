# E2E (Playwright)

Specs drive the Flutter **web** build served on `http://localhost:6780`
(`playwright.config.ts` `baseURL`; the server is started separately —
`reuseExistingServer`). Tests need a browser that can render Flutter CanvasKit
(a real/GPU browser or the deployed build); Flutter web does not render in a
GPU-less headless sandbox.

```bash
cd e2e
npm install              # once
npx playwright test      # all specs
```

## Auto-scorer camera-first sim (`auto_scorer_sim.spec.ts`)

The camera + YOLO are Android-native only, so the camera-first layouts produce
no dart detections on web. A debug bridge
(`lib/core/debug/auto_scorer_sim_bridge_web.dart`), gated by
`--dart-define=AUTOSCORER_SIM=true`, exposes `window.dartlodgeSim` so Playwright
can inject events through the `DartInputSink` seam — the exact point the native
detector emits at. It is absent from the public build (the define is off there).

Serve the sim-enabled build on `:6780`, e.g.:

```bash
flutter run -d web-server --web-port 6780 --dart-define=AUTOSCORER_SIM=true
# or: flutter build web --dart-define=AUTOSCORER_SIM=true  (served on :6780)
```

Hooks (each returns a Promise resolving after the next frame):

- `window.dartlodgeSim.enableAutoScoring()` — switch boards to camera-first
- `window.dartlodgeSim.emit('T20')` — inject one detected dart
- `window.dartlodgeSim.advance()` — advance the turn (board-clear path)

This mocks **post-detection** (the sink): it exercises the camera-first UI +
sink→game integration, not the native tracker / 3-dart cap / board-clear.
