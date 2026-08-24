package studio.gooduse.kitchenprep

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.runtime.*
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.*
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LocalLifecycleOwner
import studio.gooduse.shell.*
import studio.gooduse.kitchenprep.monetization.*

@Composable
fun KitchenPrepRoot(
    initialSharedText:String?=null,
    backend:KitchenBackendPort? = null,
) {
    val resolvedBackend: KitchenBackendPort = backend ?: viewModel<KitchenPrepViewModel>()
    val state by resolvedBackend.state
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    // First use is deliberately shown before Google UMP/Billing initialization. Once
    // the short privacy/ads notice has been seen, the normal UMP regional consent
    // flow is attached. The custom notice is not treated as consent.
    LaunchedEffect(context, state.onboardingComplete) {
        if (state.onboardingComplete) context.findActivity()?.let(resolvedBackend::attachActivity)
    }
    LaunchedEffect(initialSharedText) { if (!initialSharedText.isNullOrBlank()) resolvedBackend.acceptSharedText(initialSharedText) }
    DisposableEffect(lifecycleOwner, resolvedBackend, state.onboardingComplete) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME && state.onboardingComplete) resolvedBackend.onForeground()
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val banner = rememberBannerHandle(state.adRequestAllowed)
    GoodUseFrame(
        bottomRail = if (banner.loaded) ({ LoadedBannerRail(banner) }) else null
    ) {
        when {
            !state.onboardingComplete -> StoreReadyFirstUse(state.onboardingPage) { resolvedBackend.dispatch("ONBOARD_NEXT") }
            state.backendState == BackendState.SETTINGS -> StoreReadySettingsScreen(state, resolvedBackend::dispatch)
            else -> KitchenScreen(state, resolvedBackend::dispatch)
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

@Preview(widthDp=412,heightDp=915,showBackground=true)
@Composable private fun CompactPreview() {
    KitchenPrepRoot(backend=PreviewKitchenBackend().also {
        it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}

@Preview(widthDp=1024,heightDp=768,showBackground=true)
@Composable private fun WidePreview() {
    KitchenPrepRoot(backend=PreviewKitchenBackend().also {
        it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}
