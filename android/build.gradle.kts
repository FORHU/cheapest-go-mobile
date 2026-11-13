allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication { create<BasicAuthentication>("basic") }
            credentials {
                username = "mapbox"
                password = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").orNull
                    ?: System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                    ?: ""
            }
        }
    }
}

subprojects {
    plugins.withId("com.android.library") {
        if (!plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            plugins.apply("org.jetbrains.kotlin.android")
        }
    }
}

// Why a release build cannot lint `stripe_android`.
//
// Stripe's SDK depends on `stripe-android-issuing-push-provisioning`, which pulls
// `play-services-tapandpay` — an artifact Google publishes only to partners in its wallet
// programme. Compilation is fine, because the classes come from the push-provisioning jar
// itself; it is lint's own classpath that cannot be resolved, and `lintVitalAnalyzeRelease`
// fails the build before the APK is assembled. The dependency cannot simply be excluded: the
// SDK's own Kotlin references it.
//
// So lintVital is off — in a dependency's code, which we do not write and would not fix.
// `flutter analyze` and `:app`'s own lint still cover this repo.
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
