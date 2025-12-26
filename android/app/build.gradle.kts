plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.koji"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.koji"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    signingConfigs {
        create("release") {
            // key.properties file in the android root folder
            val keystoreFile = project.rootProject.file("key.properties")
            val props = java.util.Properties()
            if (keystoreFile.exists()) {
                props.load(java.io.FileInputStream(keystoreFile))
            }

            // Prefer env vars (CI), fallback to key.properties (local)
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: props.getProperty("storeFile") ?: "upload-keystore.jks")
            storePassword = System.getenv("ANDROID_STORE_PASSWORD") ?: props.getProperty("storePassword")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: props.getProperty("keyAlias")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: props.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
