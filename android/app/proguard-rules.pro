# Keep Kotlin metadata so reflection-based plugins continue to work when minification is enabled
-keepclassmembers class kotlin.Metadata { *; }
