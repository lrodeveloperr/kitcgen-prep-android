package studio.gooduse.kitchenprep.monetization

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.*
import studio.gooduse.kitchenprep.AgeTreatment
import studio.gooduse.kitchenprep.BuildConfig

class BannerHandle internal constructor(
    internal val adView: AdView?,
    val loaded: Boolean,
)

/**
 * The release app resolves AgeTreatment before this composable can be enabled.
 * TEEN uses Google's dedicated age-restricted treatment. Adults remain UNSPECIFIED
 * so UMP and regional privacy choices determine the appropriate ad-serving mode.
 */
@Composable
fun rememberBannerHandle(
    enabled: Boolean,
    ageTreatment: AgeTreatment,
): BannerHandle {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    var loaded by remember(enabled, ageTreatment) { mutableStateOf(false) }
    val widthDp = (configuration.screenWidthDp - 32).coerceAtLeast(320)
    val adView = remember(enabled, widthDp, ageTreatment) {
        if (!enabled || ageTreatment !in setOf(AgeTreatment.TEEN, AgeTreatment.ADULT)) null else AdView(context).apply {
            adUnitId = BuildConfig.ADMOB_BANNER_ID
            setAdSize(AdSize.getLargeAnchoredAdaptiveBannerAdSize(context, widthDp))
        }
    }

    DisposableEffect(adView, ageTreatment) {
        if (adView == null) return@DisposableEffect onDispose { }

        val ageSignal = when (ageTreatment) {
            AgeTreatment.TEEN -> AgeRestrictedTreatment.TEEN
            AgeTreatment.ADULT -> AgeRestrictedTreatment.UNSPECIFIED
            else -> AgeRestrictedTreatment.UNSPECIFIED
        }
        val requestConfiguration = MobileAds.getRequestConfiguration()
            .toBuilder()
            .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_T)
            .setAgeRestrictedTreatment(ageSignal)
            .build()
        // Must be set before SDK initialization / ad loading.
        MobileAds.setRequestConfiguration(requestConfiguration)

        MobileAds.initialize(context) {
            // Do not force npa=1 for all users. TEEN treatment disables personalized
            // advertising for teen requests; adults follow UMP/Google ad-serving rules.
            val request = AdRequest.Builder().build()
            adView.adListener = object : AdListener() {
                override fun onAdLoaded() { loaded = true }
                override fun onAdFailedToLoad(error: LoadAdError) { loaded = false }
            }
            adView.loadAd(request)
        }
        onDispose {
            loaded = false
            adView.destroy()
        }
    }
    return BannerHandle(adView, loaded)
}

/**
 * This rail intentionally occupies layout space as soon as an ad request is allowed,
 * even before the banner has loaded. That keeps the bottom navigation/content from
 * shifting when the ad arrives.
 */
@Composable
fun LoadedBannerRail(handle: BannerHandle) {
    val view = handle.adView ?: return
    Column(Modifier.fillMaxWidth().padding(top = 16.dp)) {
        AndroidView(factory = { view }, modifier = Modifier.fillMaxWidth())
    }
}
