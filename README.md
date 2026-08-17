# yomu

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release signing (Android)

Release builds are unsigned-for-Play-Store until a real upload keystore
exists. Generate one once, keep it outside version control, and never lose
it — losing it means you can never publish an update to an existing Play
Store listing under the same app.

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Copy `key.properties.example` to `key.properties` at the repo root, fill in
the passwords/alias you just chose and the path to the `.jks` file, and
`flutter build appbundle --release` will pick it up automatically. Both
`key.properties` and `*.jks` are gitignored. Without this file, release
builds silently fall back to the debug key (fine for local testing, not
upload-ready).

## Chat Coach (Gemini API key)

The Chat Coach tab calls the Gemini API to suggest Japanese phrasing at a
chosen politeness register. It needs an API key from
[Google AI Studio](https://aistudio.google.com/apikey), passed in at build/run
time rather than committed to source.

Copy `secrets.example.json` to `secrets.json` at the repo root and fill in
`GEMINI_API_KEY`, then run/build with:

```sh
flutter run --dart-define-from-file=secrets.json
```

`secrets.json` is gitignored. Without it, the Chat Coach tab shows a setup
message instead of failing silently.

Running via an IDE's Run/Debug button instead of the CLI? Use the "yomu"
launch configs in `.vscode/launch.json` — they already pass
`--dart-define-from-file=secrets.json`. The plain Flutter/Dart default
config does not, so the key comes through empty and you'll see that same
setup message even though `secrets.json` exists.
