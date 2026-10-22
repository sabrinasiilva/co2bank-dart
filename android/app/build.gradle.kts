import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push do alerta (Firebase): o google-services.json é criado pelo
// `flutterfire configure` (docs/FIREBASE.md). Sem ele o build segue normal,
// só sem push.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Chave fixa do app para o APK de release. Sem ela, cada build sai com uma
// assinatura diferente e o Android não deixa atualizar por cima: é preciso
// desinstalar. O arquivo android/key.properties não vai para o Git; no GitHub
// Actions ele é montado a partir dos segredos do repositório.
val propriedadesChave = Properties().apply {
    val arquivo = rootProject.file("key.properties")
    if (arquivo.exists()) arquivo.inputStream().use { load(it) }
}

android {
    namespace = "com.co2bank.co2bank_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Exigido pelo flutter_local_notifications (notificação de alerta do limite).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.co2bank.co2bank_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // O Flutter 3.38 já usa 24, que é o mínimo do firebase_messaging.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (propriedadesChave.isNotEmpty()) {
            create("release") {
                storeFile = rootProject.file(propriedadesChave.getProperty("storeFile"))
                storePassword = propriedadesChave.getProperty("storePassword")
                keyAlias = propriedadesChave.getProperty("keyAlias")
                keyPassword = propriedadesChave.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Com a chave do app quando ela existe; senão, a de debug (o build
            // continua funcionando, só não dá para atualizar por cima).
            signingConfig = if (propriedadesChave.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
