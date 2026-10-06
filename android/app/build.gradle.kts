import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties()
val hasReleaseSigning = releasePropertiesFile.exists()
if (hasReleaseSigning) {
    releasePropertiesFile.inputStream().use(releaseProperties::load)
}

android {
    namespace = "com.kopdes.smart.kopdes"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kopdes.smart.kopdes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = "true"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
                storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        it.name.contains("Release", ignoreCase = true) &&
            (it.name.contains("assemble", ignoreCase = true) ||
                it.name.contains("bundle", ignoreCase = true) ||
                it.name.contains("package", ignoreCase = true))
    }
    if (buildsRelease && !hasReleaseSigning) {
        throw GradleException(
            "Release signing belum dikonfigurasi. Buat android/key.properties dan keystore KOMIT.",
        )
    }
}

flutter {
    source = "../.."
}
