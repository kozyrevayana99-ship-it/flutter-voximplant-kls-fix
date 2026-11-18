# Conference Simulcast bridge fix

This is a local patch of the upstream `flutter_voximplant` **3.18.0** package,
marked `3.18.0+kls.1`. It is not an official Voximplant release.

The upstream Dart `VIClient.conference()` sends `enableSimulcast` over the
platform channel. The iOS and Android bridges in 3.18.0 do not apply it to
the native call settings, so the native SDK default remains in effect.

This patch forwards explicit `true` and `false` values for conference calls:

- iOS: `VICallSettings.enableSimulcast`.
- Android: `CallSettings.enableSimulcast`.

Omitted/null values retain native defaults. Ordinary calls retain their
existing behavior. No public Dart API changes were made.

The native dependencies remain **iOS SDK 2.60.0** and **Android SDK 2.46.0**.
All upstream 3.18.0 camera/renderer lifecycle fixes are retained. The native
version extension is `flutter-3.18.0-kls.1` on both platforms so server logs
can distinguish the patched bridge from an unmodified 3.18.0 build. Simulcast
support also depends on the native SDK and negotiated media; forwarding
the flag does not by itself prove stable cellular delivery.

## Verification

- The exact iOS adapter method was executed against test doubles using
  real Foundation, NSNumber and NSNull: the upstream method fails the two
  explicit-value cases; the patched method passes all five cases.
- The inserted iOS setting block compiles against the real iOS SDK 2.60.0
  headers for an arm64 simulator target.
- The Android SDK 2.46.0 class file contains a public, mutable primitive
  boolean `CallSettings.enableSimulcast`, matching the assignment.
- The workflow in `.github/workflows/native-bridge-check.yml` builds a
  disposable probe application for Android and an iOS simulator. It must
  run in the repository before this patch is treated as build-verified
  on both platforms. A full Android build has not been run locally.

The probe application is generated during CI and contains no application
credentials or production call configuration. Native SDK binaries are
resolved from the upstream dependencies and are not vendored here.

## Using this package

For FlutterFlow, use a Git dependency pinned to the exact commit that passed
the native build checks. The Git URL is supplied after this source package
has been placed in the intended repository. Do not keep a second pub.dev
entry for `flutter_voximplant` at the same time.

Upstream source: <https://github.com/voximplant/flutter_voximplant>

The original license and copyright notices are preserved in `LICENSE` and
the source files.
