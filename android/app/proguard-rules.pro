# google_mlkit_text_recognition's Android side compiles against the Chinese,
# Devanagari, Japanese, and Korean script recognizers as compileOnly deps —
# the app only bundles Japanese (build.gradle.kts), by design, since Yomu is
# a Japanese-only app. R8 otherwise fails release builds with "missing class"
# errors for the three scripts we never ship.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**
