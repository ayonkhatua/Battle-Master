// 🌟 1. Ye dono line sabse upar add karni hain
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 🌟 ADD THIS LINE FOR FIREBASE 🌟
    id("com.google.gms.google-services")
}

// 🌟 2. Keystore Properties load karna (Kotlin DSL style)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

    // 🌟 3. Release Signing Config banana
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            // 🌟 4. Release config aur Proguard attach karna
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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