# Keep Google Error Prone annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep JSR305 annotations
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }

# Keep Tink related classes
-keep class com.google.crypto.tink.** { *; }
-keepclassmembers class * {
    @com.google.crypto.tink.annotations.** *;
}