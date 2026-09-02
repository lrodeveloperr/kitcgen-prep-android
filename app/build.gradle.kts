plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.kapt")
}

val demoAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val demoAdMobBannerId = "ca-app-pub-3940256099942544/9214589741"
val adMobAppIdProvider = providers.gradleProperty("ADMOB_APP_ID").orElse(demoAdMobAppId)
val adMobBannerIdProvider = providers.gradleProperty("ADMOB_BANNER_ID").orElse(demoAdMobBannerId)
val legalBase = "https://lrodeveloperr.github.io/kitchen-prep-board-policies-repo"

android {
    namespace = "studio.gooduse.kitchenprep"
    compileSdk = 37

    defaultConfig {
        applicationId = "studio.gooduse.kitchenprep"
        minSdk = 23
        targetSdk = 36
        // First Google Play upload; no APK/AAB has previously been uploaded.
        versionCode = 1
        versionName = "1.0.0"

        // Debug/device QA may use Google's demo IDs. Release builds are blocked below
        // unless explicit production IDs are supplied as Gradle properties.
        manifestPlaceholders["ADMOB_APP_ID"] = adMobAppIdProvider.get()
        buildConfigField("String", "ADMOB_BANNER_ID", "\"${adMobBannerIdProvider.get()}\"")

        buildConfigField("String", "PRIVACY_POLICY_URL", "\"" + providers.gradleProperty("PRIVACY_POLICY_URL").orElse("$legalBase/privacy/").get() + "\"")
        buildConfigField("String", "TERMS_URL", "\"" + providers.gradleProperty("TERMS_URL").orElse("$legalBase/terms/").get() + "\"")
        buildConfigField("String", "SUPPORT_URL", "\"" + providers.gradleProperty("SUPPORT_URL").orElse("$legalBase/support/").get() + "\"")
        buildConfigField("String", "SAFETY_URL", "\"" + providers.gradleProperty("SAFETY_URL").orElse("$legalBase/safety/").get() + "\"")
        buildConfigField("String", "SUBSCRIPTION_TERMS_URL", "\"" + providers.gradleProperty("SUBSCRIPTION_TERMS_URL").orElse("$legalBase/subscription/").get() + "\"")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

// A release must never silently ship Google's demo inventory. Debug remains easy to
// run, while bundleRelease/assembleRelease fail early until production IDs are set.
val verifyProductionMonetizationConfig = tasks.register("verifyProductionMonetizationConfig") {
    group = "verification"
    doLast {
        val appId = providers.gradleProperty("ADMOB_APP_ID").orNull
        val bannerId = providers.gradleProperty("ADMOB_BANNER_ID").orNull
        require(!appId.isNullOrBlank()) {
            "Release blocked: set ADMOB_APP_ID to the production AdMob app ID."
        }
        require(!bannerId.isNullOrBlank()) {
            "Release blocked: set ADMOB_BANNER_ID to the production banner unit ID."
        }
        require(appId != demoAdMobAppId && bannerId != demoAdMobBannerId) {
            "Release blocked: Google demo AdMob IDs cannot be used in a release build."
        }
        require(Regex("^ca-app-pub-[0-9]+~[0-9]+$").matches(appId)) {
            "Release blocked: ADMOB_APP_ID has an invalid format."
        }
        require(Regex("^ca-app-pub-[0-9]+/[0-9]+$").matches(bannerId)) {
            "Release blocked: ADMOB_BANNER_ID has an invalid format."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyProductionMonetizationConfig)
}

kapt {
    arguments {
        arg("room.schemaLocation", "$projectDir/schemas")
        arg("room.incremental", "true")
    }
}

dependencies {
    implementation(project(":gooduse-shell"))

    val composeBom = platform("androidx.compose:compose-bom:2026.08.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)
    implementation("androidx.activity:activity-compose:1.12.3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.10.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.10.0")
    implementation("androidx.datastore:datastore-preferences:1.2.1")

    implementation("androidx.room:room-runtime:2.8.4")
    kapt("androidx.room:room-compiler:2.8.4")

    implementation("com.android.billingclient:billing-ktx:9.1.0")
    implementation("com.google.android.gms:play-services-ads:25.4.0")
    implementation("com.google.android.ump:user-messaging-platform:4.0.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    testImplementation(kotlin("test"))
    testImplementation("junit:junit:4.13.2")
}
