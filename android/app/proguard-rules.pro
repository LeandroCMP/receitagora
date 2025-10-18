# Keep Stripe push provisioning classes that are referenced via reflection
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Required by the Stripe Flutter plugin to avoid stripping Kotlin metadata used at runtime
-keepclassmembers class kotlin.Metadata { *; }
