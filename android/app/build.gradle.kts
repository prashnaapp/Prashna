import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.prashna.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.prashna.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: error("android/key.properties is missing keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: error("android/key.properties is missing keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: error("android/key.properties is missing storePassword")
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                    ?: error("android/key.properties is missing storeFile")
                storeFile = rootProject.file(storeFilePath)
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to debug signing for release.
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
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

gradle.taskGraph.whenReady {
    val isReleasePackagingTask = allTasks.any { task ->
        val name = task.name
        name.contains("Release", ignoreCase = false) &&
            (
                name.startsWith("assemble") ||
                    name.startsWith("bundle") ||
                    name.startsWith("package") ||
                    name.startsWith("sign")
            )
    }
    if (isReleasePackagingTask && !hasReleaseKeystore) {
        throw GradleException(
            "Release build requires android/key.properties and a production keystore. " +
                "Copy android/key.properties.example to android/key.properties and set " +
                "storeFile, storePassword, keyAlias, and keyPassword. " +
                "Release builds must not use debug signing.",
        )
    }
}
