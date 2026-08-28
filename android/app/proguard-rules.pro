# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }

# timezone package
-keep class net.time4j.** { *; }

# Gson (used internally by some plugins for serialization)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*