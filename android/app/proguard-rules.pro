# Keep Stripe push provisioning classes shipped in stripe-android-issuing-push-provisioning
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Required by the Stripe Flutter plugin to avoid stripping Kotlin metadata used at runtime
-keepclassmembers class kotlin.Metadata { *; }
