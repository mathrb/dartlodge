# DartLodge — Privacy Policy

> This Markdown is the repo-readable source. The **published** version is
> `web_extra/privacy.html`, deployed by `pages.yml` to
> <https://mathrb.github.io/dartlodge/privacy.html> (the Google Play privacy
> policy URL). **Keep the two in sync** when either changes.

**Effective date:** 2026-06-24

DartLodge is a local-first, open-source darts scoring and statistics app. This
policy explains what data the app handles and what (very little) leaves your
device. It is written to be read, not to cover lawyers — if anything here is
unclear, contact us (below).

## Summary

- DartLodge has **no user accounts** and **no cloud sync**. Your games,
  players, statistics, and achievements stay **on your device**.
- We **do not** show ads, run third-party analytics, or sell or share your data.
- The **only** information that leaves your device by default is **anonymous
  crash and error diagnostics** (via Sentry), used solely to find and fix bugs.
- The optional **camera auto-scoring** feature processes images **on your
  device**. Saving images for model improvement is **off by default** and
  opt-in; saved images **never leave your device** unless you explicitly export
  them yourself.

## Data stored on your device

The app stores the following locally, in an on-device database (SQLite on
mobile/desktop, IndexedDB on web):

- Players you create (names you choose) and per-player activity.
- Games you play, their configuration, and the individual scoring events.
- Statistics, computed from your game history, and achievements, stored once
  you earn them.
- App settings and preferences.

This data is never transmitted to us or any third party. Uninstalling the app,
or using the app's own delete/clear functions, removes it.

## Crash and error diagnostics (Sentry)

To keep the app stable, DartLodge sends **crash reports and unhandled error
diagnostics** to [Sentry](https://sentry.io), a crash-reporting service. These
reports may include:

- The error and its stack trace.
- Basic device and app information (e.g. app version, operating-system version,
  device model).

These diagnostics are used **only** to diagnose and fix crashes and bugs. They
do **not** include your players' names, your game data, your statistics, or any
images. We do not use them for advertising or profiling.

**You can turn crash reporting off** at any time in Settings → Feedback. It is on
by default; once you disable it the change takes effect the next time you open
the app, after which no crash or error diagnostics are sent.

DartLodge also includes an optional **"Report a Bug"** feature in Settings. If
you choose to use it, the description you type is sent to Sentry so we can
investigate the problem. Please avoid including personal information in that
text.

**Data retention.** Crash and error diagnostics (including any "Report a Bug"
text) are retained by Sentry for **up to 90 days**, after which they are
automatically and permanently deleted. We keep them only this long because their
sole purpose is to diagnose and fix recent crashes — once an issue is understood
and a release has stabilised, older reports serve no purpose, so we do not retain
them beyond this window.

## Camera and auto-scoring (optional, beta)

DartLodge includes an **optional, experimental (beta)** auto-scoring feature
that uses your device camera to detect darts on the board. The detection model
is still learning, and you can choose to help improve it. If you enable the
feature:

- The camera is used **only** while auto-scoring is active, and only after you
  enable it (it is **off by default**).
- Image processing and dart detection happen **entirely on your device**.
  Camera frames are **not** uploaded.

Separately, a **"Collect training data"** option (also **off by default**) lets
you save board images and your scoring corrections **on your device** to help
train and improve the detection model. These saved images:

- Stay on your device.
- Are **never** uploaded automatically.
- Can be **exported by you**, manually, via your device's share sheet — for
  example to share them with the project to train the model. Exporting is
  entirely your choice and under your control. You can also clear all saved
  images at any time.

## What we do NOT collect

- No account, email, phone number, or login.
- No advertising identifiers, location, contacts, or device fingerprinting.
- No third-party advertising or analytics SDKs.
- No selling or sharing of personal data.

## Children

DartLodge is not directed at children under 13 and does not knowingly collect
personal information from children.

## Network access

In normal use the app works fully offline. The app contacts the network only to
send the crash diagnostics described above. There is no DartLodge backend server
that your game data is sent to.

## Open source

DartLodge is open source. You can review exactly how data is handled in the
source code, including the crash-reporting setup and the on-device-only capture
pipeline.

## Changes to this policy

If this policy changes, the updated version will be published at the same URL
with a new effective date.

## Contact

Questions about this policy or your data: **mathrb@gmail.com**
