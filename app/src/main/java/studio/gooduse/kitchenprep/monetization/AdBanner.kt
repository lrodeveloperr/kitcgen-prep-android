package studio.gooduse.kitchenprep.monetization

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.google.android.gms.ads.*
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import studio.gooduse.kitchenprep.BuildConfig
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.roundToInt

class BannerHandle internal constructor(
    internal val adView: AdView?,
    val loaded: Boolean,
)

/** Initializes Mobile Ads once per process after UMP + Billing allow an ad request. */
private object MobileAdsBootstrap {
    private val ready = AtomicBoolean(false)
    private val initializing = AtomicBoolean(false)
    private val lock = Any()
    private val callbacks = mutableListOf<() -> Unit>()

    fun ensureInitialized(context: android.content.Context, onReady: () -> Unit) {
        if (ready.get()) {
            onReady()
            return
        }

        var shouldStart = false
        synchronized(lock) {
            if (ready.get()) {
                onReady()
                return
            }
            callbacks += onReady
            if (!initializing.get()) {
                initializing.set(true)
                shouldStart = true
            }
        }
        if (!shouldStart) return

        MobileAds.setRequestConfiguration(
            MobileAds.getRequestConfiguration()
                .toBuilder()
                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_T)
                .build()
        )
        MobileAds.initialize(context.applicationContext) {
            val pending = synchronized(lock) {
                ready.set(true)
                initializing.set(false)
                callbacks.toList().also { callbacks.clear() }
            }
            pending.forEach { it.invoke() }
        }
    }
}

/**
 * Android 1.0 is 18+ only. Adults follow UMP and Google's regional privacy rules.
 * The T maximum-content rating is a brand-suitability choice, not an age signal.
 */
@Composable
fun rememberBannerHandle(enabled: Boolean, availableWidthDp: Int): BannerHandle {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val coroutineScope = rememberCoroutineScope()
    var loaded by remember(enabled, availableWidthDp) { mutableStateOf(false) }
    var retryAttempt by remember(enabled, availableWidthDp) { mutableIntStateOf(0) }
    var retryJob by remember(enabled, availableWidthDp) { mutableStateOf<Job?>(null) }

    val safeWidthDp = availableWidthDp.coerceAtLeast(1)
    val adView = remember(enabled, safeWidthDp) {
        if (!enabled) null else AdView(context).apply {
            adUnitId = BuildConfig.ADMOB_BANNER_ID
            setAdSize(AdSize.getLargeAnchoredAdaptiveBannerAdSize(context, safeWidthDp))
        }
    }

    DisposableEffect(adView, lifecycleOwner, enabled, safeWidthDp) {
        if (adView == null) return@DisposableEffect onDispose { }

        var disposed = false
        lateinit var loadBanner: () -> Unit
        loadBanner = {
            if (disposed) return@let
        }

        fun requestBanner() {
            if (disposed) return
            adView.adListener = object : AdListener() {
                override fun onAdLoaded() {
                    loaded = true
                    retryAttempt = 0
                    retryJob?.cancel()
                    retryJob = null
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    loaded = false
                    retryJob?.cancel()
                    retryJob = null

                    val nonRetriable = error.code == AdRequest.ERROR_CODE_NO_FILL ||
                        error.code == AdRequest.ERROR_CODE_INVALID_REQUEST
                    if (nonRetriable || retryAttempt >= MAX_BANNER_RETRIES || disposed) return

                    val delayMs = (BANNER_RETRY_BASE_MS * (1L shl retryAttempt))
                        .coerceAtMost(BANNER_RETRY_MAX_MS)
                    retryAttempt++
                    retryJob = coroutineScope.launch {
                        delay(delayMs)
                        if (!disposed) requestBanner()
                    }
                }
            }
            adView.loadAd(AdRequest.Builder().build())
        }

        MobileAdsBootstrap.ensureInitialized(context) {
            if (!disposed) requestBanner()
        }

        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> adView.resume()
                Lifecycle.Event.ON_PAUSE -> adView.pause()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        onDispose {
            disposed = true
            retryJob?.cancel()
            retryJob = null
            lifecycleOwner.lifecycle.removeObserver(observer)
            loaded = false
            adView.destroy()
        }
    }

    return BannerHandle(adView, loaded)
}

@Composable
fun LoadedBannerRail(enabled: Boolean) {
    if (!enabled) return
    Column(
        Modifier
            .fillMaxWidth()
            .padding(top = 16.dp)
    ) {
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val availableWidthDp = maxWidth.value.roundToInt().coerceAtLeast(1)
            val handle = rememberBannerHandle(enabled = true, availableWidthDp = availableWidthDp)
            val view = handle.adView ?: return@BoxWithConstraints
            AndroidView(factory = { view }, modifier = Modifier.fillMaxWidth())
        }
    }
}

private const val MAX_BANNER_RETRIES = 3
private const val BANNER_RETRY_BASE_MS = 2_000L
private const val BANNER_RETRY_MAX_MS = 30_000L
