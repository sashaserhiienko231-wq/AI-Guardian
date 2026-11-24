import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localSigningProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.inputStream().use { localSigningProperties.load(it) }
}

fun signingValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)?.trim()?.takeIf { it.isNotEmpty() }
        ?: localSigningProperties.getProperty(propertyName)?.trim()?.takeIf { it.isNotEmpty() }

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
}

android {
    namespace = "com.example.ai_guardian"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ai_guardian"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            val storeFileValue = signingValue("AI_GUARDIAN_KEYSTORE", "storeFile")
            val storePasswordValue = signingValue("AI_GUARDIAN_STORE_PASSWORD", "storePassword")
            val keyAliasValue = signingValue("AI_GUARDIAN_KEY_ALIAS", "keyAlias")
            val keyPasswordValue = signingValue("AI_GUARDIAN_KEY_PASSWORD", "keyPassword")

            if (releaseTaskRequested &&
                (storeFileValue == null || storePasswordValue == null ||
                    keyAliasValue == null || keyPasswordValue == null)
            ) {
                throw GradleException(
                    "Production release signing is not configured. Set AI_GUARDIAN_KEYSTORE, " +
                        "AI_GUARDIAN_STORE_PASSWORD, AI_GUARDIAN_KEY_ALIAS, and " +
                        "AI_GUARDIAN_KEY_PASSWORD, or provide android/key.properties.",
                )
            }
            if (storeFileValue != null && storePasswordValue != null &&
                keyAliasValue != null && keyPasswordValue != null
            ) {
                val productionStoreFile = rootProject.file(storeFileValue)
                if (releaseTaskRequested && !productionStoreFile.isFile) {
                    throw GradleException("The configured production keystore file was not found.")
                }
                if (productionStoreFile.isFile) {
                    signingConfigs.create("production") {
                        storeFile = productionStoreFile
                        storePassword = storePasswordValue
                        keyAlias = keyAliasValue
                        keyPassword = keyPasswordValue
                    }
                    signingConfig = signingConfigs.getByName("production")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
