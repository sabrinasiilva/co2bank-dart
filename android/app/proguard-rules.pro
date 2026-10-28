# O rotulador de imagens do ML Kit cita o firebase-iid só no código de modelos
# baixados da nuvem, que o app não usa. O firebase-iid foi excluído no
# build.gradle.kts porque repete uma classe do firebase-messaging.
-dontwarn com.google.firebase.iid.FirebaseInstanceId
