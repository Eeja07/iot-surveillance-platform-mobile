plugins {
    id("com.android.application")
    id("kotlin-android")

    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.example.my_app"


        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {


            isMinifyEnabled = true
            isShrinkResources = true


            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
