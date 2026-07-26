# Literia patches for flutter_tts

This directory vendors `flutter_tts` 4.2.5 from
<https://github.com/dlutton/flutter_tts>.

The upstream license is preserved in `LICENSE`. The example, generated
documentation, and upstream tests are intentionally omitted because this
directory is consumed only as an application dependency.

Local patches:

1. Web boundary events convert JavaScript values through `dartify()` and read
   utterance text through its typed interop getter. This keeps the WebAssembly
   compiler from relying on runtime casts between JS and Dart types.
2. Android relies on AGP 9 built-in Kotlin and no longer applies or bundles the
   standalone Kotlin Gradle plugin. The vendored package therefore requires
   Flutter 3.44 and Dart 3.12, matching Literia. This follows Flutter's
   [plugin migration guide][kotlin-migration].

[kotlin-migration]: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors

When upgrading, replace the vendored platform and Dart sources from the new
upstream release, reapply only patches that remain necessary, then run:

    flutter test
    flutter analyze
    flutter build web --release
    flutter build web --wasm
    flutter build apk --debug
    flutter build windows --release
