# Auto-assist UX — making the camera legible to a player (design)

**Date:** 2026-08-28 · **Status:** design approved, ready for ticket breakdown
**Scope:** the camera auto-scoring ("auto-assist", BETA) user experience — aiming,
playing when the board is not recognised, and contributing captured frames.
**Non-scope:** detection quality, model training, the export *transport*.

---

## 1. Problem

Auto-assist exposes its **internal state machine** to the player and never
exposes its **user-facing contract**. Three symptoms, one root cause.

The maintainer named the root cause directly:

> "Je n'ai aujourd'hui aucun retour utilisateur dans le cas où la reconnaissance
> ne fonctionne pas du tout. Par exemple avec une cible différente, ou des
> fléchettes différentes, ou même un angle différent."

The loop **"I played → I helped"** never closes visibly. Every symptom below is a
place where that loop is cut.

### 1.1 Evidence from the code (verified 2026-08-28)

| # | Finding | Location |
|---|---|---|
| E1 | The four "markers" are the outer-double-wire crossings at 20/5, 3/17, 8/11, 13/6. Nothing in the app says so. | `domain/scoring/homography.dart:69` |
| E2 | `setShowOverlays(true)` makes the plugin paint raw class labels on the preview: the label string is `"$name ${"%.1f".format(confidence * 100)}"` → the player literally reads `cal1 82.4`, `dart 91.3`. | `ultralytics_yolo-0.6.5/.../YOLOView.kt:1568` |
| E3 | Calibration feedback is one count, `"{found}/4 markers"`. Which marker is missing is never shown, although `DetectionFrame.calBestPoints` holds per-class position and confidence. | `auto_scorer_yolo_view_io.dart` build / `detection_frame.dart:23` |
| E4 | Tip 1 says "all four **corner** markers" — misleading: it sends the player looking at the corners of the *image*. | `app_en.arb: autoScorerTip1Body` |
| E5 | `TrackerPhase.needsCalibration` renders in `errorContainer` (red). An uncalibrated session therefore shows a **permanent red alarm** for a valid operating mode. | `auto_scorer_status_chip.dart` |
| E6 | `captureManualEntry` (#537) already captures a full-resolution **labelled** frame on every manual dart entry, on all four board pages — **silently**. Nothing in the UI acknowledges it. | `capture_correction_sink.dart` + 4 board pages |
| E7 | The manual capture button is a 20 px icon that is **inert in the default state**: the collapsed vignette wraps the preview in `IgnorePointer`. | `auto_scorer_board_overlay.dart` (documented trade-off) |
| E8 | Five user-facing strings on the camera path are hardcoded English in a 7-language app: `'Capture frame'`, `'Focusing…'`, `'Frame saved for training'`, `'Enable data collection to save frames'`, `'Capture failed (no frame).'` | `auto_scorer_yolo_view_io.dart` |
| E9 | Export hands the zip to the OS share sheet with no destination and no guidance. | `auto_scorer_settings_page.dart::_export` |
| E10 | `auto_scorer_cal_overlay_painter.dart` (202 lines) is dead code — only its own test references it. It drew exactly the per-marker feedback we now want, and was lost in the CameraController → YOLOView migration (#408 → YOLOView). | grep: no `lib/` reference |

### 1.2 A premise corrected

The brief assumed the player *must* press the camera button when no dart is
detected. E6 shows the labelled capture already happens automatically on manual
entry. The real gap is not a hidden button — it is that **nobody is told the
collection is automatic**, and the inert button (E7) signals the opposite.

---

## 2. Decisions taken

| Question | Decision |
|---|---|
| Point 3 objective | Education through copy and visuals — surface the automatic behaviour, do not build a new capture path. |
| Sharing transport | **Unchanged.** Explain it; do not pick a new transport in this round (see `2026-06-21-auto-assist-data-sharing-options.md`, still undecided). |
| Destination named in copy | Upload the zip to the player's **own Google Drive**, then share the file with **mathrb@gmail.com**. Rationale to state in the UI: the zip is too large for e-mail attachments. |
| Vocabulary | Player language by default; technical vocabulary moves behind an advanced setting. |
| Native overlay boxes | **Off by default**, restorable via an "Advanced / technical display" setting. |
| Naming of the uncalibrated state | A mix of "learning mode" and an honest statement of the failure: **"Board not recognised · learning mode"**. Copy must state that this is **not online learning**. |
| Opt-in prompting | Offer to enable recording **at the moment it makes sense** — inside the "not recognised" panel, where the trade-off is self-evident. |
| Deliverable | This design doc, then an epic with native sub-issues; PRs shipped serially. |

---

## 3. Design — three stations of one thread

The thread is the **contribution counter**: it is what makes an invisible
background process visible, and it appears at all three stations.

### Station 1 — Aiming: make recognition legible

**S1.1 Border halo.** A gradient border around the preview reflecting recognition
state: red (no marker) → amber (1–3 markers, or 4 unstable) → green (4 stable).
It is driven by the **same derived state as the pips** (S1.2) — one pure function,
two renderings — so the two signals can never disagree.

Painted Dart-side around the preview widget — **no coordinate mapping**. That
mapping risk is what plausibly killed the Dart overlay at the YOLOView migration
(E10), and it cannot be validated without a device. The halo carries the same
"is it working?" signal at zero geometric risk, and it reads from the oche, which
matters in the collapsed vignette during play (consistent with epic #477).

*Acceptance:* halo state is a pure function of `(markersFound, isStable)`, unit
tested; visible in the aim view and in both in-game preview layouts.

**S1.2 Four pips.** `●●●○` replaces `"{found}/4 markers"`. Filled / amber /
hollow per marker, driven by `calBestPoints`. Detail without a number.

*Acceptance:* pip states derived from `calBestPoints` + threshold, unit tested;
`autoScorerMarkersReframe` copy loses the raw count.

**S1.3 Native overlays off by default.** `setShowOverlays(false)` on the normal
path. A new **"Technical display"** switch, grouped with the confidence sliders,
restores them for debugging.

Accepted trade-off: the player loses *where* the camera sees the markers. S1.4
compensates by teaching it once.

*Acceptance:* default session shows no `cal1 82.4` label anywhere; the switch
restores the boxes; the setting persists like the other auto-scorer prefs.

**S1.4 Say what the markers are.** A dartboard diagram in the setup-tips screen
marking the four wire crossings (20/5, 3/17, 8/11, 13/6), and tip 1 reworded to
drop "corner" (E4).

*Acceptance:* tip 1 no longer contains "corner"; the diagram renders from the
existing dartboard drawing code in `core/widgets` rather than a new asset.

### Station 2 — Playing: learning mode

**S2.1 Explanatory escalation.** In the aim view, after ~10 s without four
markers, the one-line nudge is replaced by a panel: a short statement of fact,
the likely causes (different board, lighting, too head-on an angle, soft-tip),
then the reframe — *you can play normally; every hand-entered score is
photographed and will help teach the camera your board* — with **"Play anyway"**
as the primary action and "Keep aiming" as secondary.

It replaces the aim view's hint region **in place**; it is not a dialog and not a
pushed route. The player is holding a phone at a board — an interruption that
must be dismissed before re-aiming would be worse than the silence it fixes.

If recording is **off**, this panel is also where we offer to turn it on
(decision in §2): this is the one moment where the trade-off is self-evident.

*Acceptance:* escalation is time-based and purely presentational; it never
blocks the existing "Continue without auto-scoring" path; declining the recording
offer still lets the player proceed.

**S2.2 Split the two red states.** `needsCalibration` currently conflates two
unrelated situations (E5). Separate them at the presentation layer:

- never calibrated this session → calm banner, **"Board not recognised · learning mode"**;
- was calibrated and lost it → the existing red alert, which is legitimate.

The overlay already knows which case it is: the aim step returning via
"Continue without auto-scoring" marks the session as learning mode.

*Acceptance:* a learning-mode session never renders `errorContainer`; a
mid-session calibration loss still does. Both covered by chip/overlay tests.

**S2.3 Contribution counter.** During play it lives in the overlay's bar row,
next to the status chip (the row that already holds re-aim / remove-darts /
stop), so it shares the at-distance treatment the chip got in #480. In settings
it is a tile showing the store total. Session count is held in memory and incremented on each
successful persist (no per-capture file listing); the settings tile reads
`CaptureStore.list().length`.

*Acceptance:* the counter increments on manual entry, on correction, and on
manual capture; it is absent when recording is off.

**S2.4 Micro-feedback on capture.** `captureManualEntry` is entirely silent
(E6). Make it acknowledge itself **in the counter itself** — a short highlight
pulse on the counter as it increments. Explicitly **not** a SnackBar: manual
entry happens up to three times per turn, and three snackbars per turn would
cover the board and fight the existing correction/export snackbars.

*Acceptance:* the acknowledgement never blocks scoring and never appears when
recording is off; a failed capture stays silent (it must never disrupt play).

**S2.5 Honest loop copy.** The learning-mode body text states the real loop:
your images → you send them → a retrained model → **it comes back to the app on
its own**. That last step is not a promise: the OTA channel (#715) exists and the
"Detection model" tile already shows it. The copy must explicitly say this is
**not live/on-device learning**, per the maintainer's correction.

*Acceptance:* the strings contain no wording implying the model improves during
play; the learning-mode screen links to the model tile.

### Station 3 — Sending: where my images go

**S3.1 Pre-send screen** replacing the direct hand-off to the share sheet. It
states: what is inside (N photos, M sessions, size); what the photos are (your
board and your room — look before sending); where it goes.

**S3.2 The two-step instruction.** Save the zip to your own Google Drive, then
share that file with **mathrb@gmail.com** (with a copy-address button) —
**because the zip is too large to e-mail**. Stating the reason prevents the
player from attempting an attachment and giving up.

**S3.3 What happens next.** One line closing back to S2.5: what the contribution
triggers, and that the update returns through the app.

*Acceptance:* the share sheet remains the transport, unchanged; the screen is
skippable for a repeat sender; the address is a single constant, not duplicated
across the 7 arb files.

### Station 4 — Debt picked up on the way

**S4.1** i18n the five hardcoded English strings (E8) across all 7 locales.

**S4.2** Resolve the inert capture button (E7): **remove it from the in-game
preview**, keep it only in the aim view — during play the labelled capture is
automatic, and an unlabelled frame is worth less.

**S4.3** Delete `auto_scorer_cal_overlay_painter.dart` and its test (E10), or
keep the mapping helper if a future on-preview overlay is attempted. Recommend
deletion: S1.1/S1.2 deliberately avoid that mapping.

---

## 4. Risks and open points

- **Halo/pip thresholds are advisory heuristics.** Like `kGoodFillRatio` they need
  tuning on device; they must never gate the ready state, only copy and colour.
- **Device verification.** Everything here is camera-path and, per
  `docs/rules/auto-scorer.md`, camera changes are not widget-testable. Pure
  mappings (halo state, pip state, escalation timing) must be extracted as pure
  functions so they *are* tested; the rest needs a device pass on an APK.
- **The transport is still undecided.** S3 makes the current transport
  understandable; it does not remove the need to decide
  `2026-06-21-auto-assist-data-sharing-options.md`.
- **Naming a personal e-mail in shipped copy.** `mathrb@gmail.com` goes into the
  app for lack of a dartlodge address; revisit if a project address appears.
- **BETA labelling** stays mandatory on every user-facing surface touched here.

## 5. Proposed ticket breakdown

One epic, sub-issues shipped serially (one PR end to end before the next).

| # | Ticket | Depends on |
|---|---|---|
| 1 | S4.1 i18n the hardcoded camera strings | — |
| 2 | S1.3 technical-display setting + native overlays off by default | 1 |
| 3 | S1.1 + S1.2 halo and pips | 2 |
| 4 | S1.4 marker diagram + tip rewording | — |
| 5 | S2.2 split learning mode from calibration loss | — |
| 6 | S2.3 + S2.4 contribution counter and capture feedback | 5 |
| 7 | S2.1 + S2.5 escalation panel, recording offer, loop copy | 5, 6 |
| 8 | S3 pre-send screen | 6 |
| 9 | S4.2 + S4.3 remove the in-game capture button, delete dead painter | 3 |
