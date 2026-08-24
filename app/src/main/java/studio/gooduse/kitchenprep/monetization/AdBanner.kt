package studio.gooduse.kitchenprep.monetization

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.*
import studio.gooduse.kitchenprep.BuildConfig

class BannerHandle internal constructor(
    internal val adView: AdView?,
    val loaded: Boolean,
)

/**
 * Android 1.0 is 18+ only. There is no teen/child ad-treatment branch.
 * Adults follow UMP and Google's regional privacy/ad-serving rules. We keep a Teen
 * maximum ad-content rating for brand suitability without changing the audience age.
 */
@Composable
fun rememberBannerHandle(enabled: Boolean): BannerHandle {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    var loaded by remember(enabled) { mutableStateOf(false) }
    val widthDp = (configuration.screenWidthDp - 32).coerceAtLeast(320)
    val adView = remember(enabled, widthDp) {
        if (!enabled) null else AdView(context).apply {
            adUnitId = BuildConfig.ADMOB_BANNER_ID
            setAdSize(AdSize.getLargeAnchoredAdaptiveBannerAdSize(context, widthDp))
        }
    }

    DisposableEffect(adView) {
        if (adView == null) return@DisposableEffect onDispose { }
        MobileAds.setRequestConfiguration(
            MobileAds.getRequestConfiguration()
                .toBuilder()
                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_T)
                .build()
        )
        MobileAds.initialize(context) {
            // Do not force non-personalized ads globally. UMP/regional privacy choices
            // determine the permitted adult ad-serving mode.
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

@Composable
fun LoadedBannerRail(handle: BannerHandle) {
    val view = handle.adView ?: return
    Column(Modifier.fillMaxWidth().padding(top = 16.dp)) {
        AndroidView(factory = { view }, modifier = Modifier.fillMaxWidth())
    }
}
