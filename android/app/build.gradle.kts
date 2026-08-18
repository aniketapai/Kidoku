import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads from <repo root>/key.properties, which is
// gitignored and never committed. See README for how to generate the
// upload keystore this file points at. Until that file exists, release
// builds fall back to the debug key so `flutter build apk --release`
// keeps working locally — that fallback build is NOT upload-ready.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aniket.yomu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications' Android library is itself built
        // with core library desugaring enabled — AGP requires every
        // consuming module (this app) to enable it too, or the build
        // fails with "Dependency ... requires core library desugaring".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.aniket.yomu"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // google_mlkit_text_recognition's Android side ships the
            // Japanese/Chinese/Devanagari/Korean recognizers as compileOnly —
            // the app must supply whichever it actually uses (see the
            // dependencies block below) or R8 fails release builds with
            // "missing class" errors for all four. proguard-rules.pro
            // silences the warning for the three we deliberately don't ship.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Camera Translate's OCR only recognizes Japanese — see
    // TextRecognitionScript.japanese in ocr_translation_service.dart.
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    // Required alongside isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
