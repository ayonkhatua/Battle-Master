plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 🌟 ADD THIS LINE FOR FIREBASE 🌟
    id("com.google.gms.google-services")
}

android {
    namespace = "com.hypernest.battlemaster"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🌟 DESUGARING ENABLED HERE 🌟
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.hypernest.battlemaster"
        
        // 🔥 UPDATE: Hardcoded to 23. Ye karna bohot zaroori hai!
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase Bill of Materials (BoM). Updated to a newer stable version.
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))

    // 🌟 UPDATE: Specific Firebase modules
    implementation("com.google.firebase:firebase-analytics")
    
    // 🌟 DESUGARING DEPENDENCY ADDED HERE (For flutter_local_notifications) 🌟
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
