import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// android/key.properties — the upload keystore, written by .github/workflows/deploy-prod.yml
// and git-ignored. Empty when the file is absent, which is every local build and every dev
// APK, so those keep the debug signing the sideload note below explains.
val keystoreProperties = Properties().apply {
    val propsFile = rootProject.file("key.properties")
    if (propsFile.exists()) propsFile.inputStream().use { load(it) }
}

android {
    namespace = "com.forhu.cheapestgo.cheapest_go_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.forhu.cheapestgo.cheapest_go_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // AGP drops v1 (JAR) signing once minSdk is 24, because AOSP has verified v2
            // since Android 7. The installers on ColorOS and Funtouch have not: handed an
            // APK carrying only a v2 signature they refuse it as "There was a problem
            // parsing the package", which reads as a broken build rather than a policy.
            //
            // `adb install` goes round that installer, which is why the same file lands
            // over USB and fails when tapped in Downloads. These APKs are sideloaded for
            // testing, so the extra signature is the whole point of building them.
            enableV1Signing = true
            enableV2Signing = true
        }

        if (keystoreProperties.isNotEmpty()) {
            create("upload") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // The upload key when android/key.properties exists, the debug key otherwise. A
            // release signed with the debug key builds cleanly and is rejected by Play at the
            // moment of upload, which is why deploy-prod.yml refuses to run without the keystore.
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // For AppCompatDelegate.setApplicationLocales: the per-app language Android 13 added,
    // backported here so handsets below it get it too. Stripe's SDK already brings
    // AppCompat in transitively; naming it here is what makes the version ours to pin.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
