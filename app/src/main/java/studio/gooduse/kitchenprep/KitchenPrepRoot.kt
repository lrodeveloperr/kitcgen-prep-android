package studio.gooduse.kitchenprep

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
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
    var storeIntroPage by rememberSaveable { mutableIntStateOf(0) }

    // Android 1.0 is declared and marketed for adults 18+ only. No date-of-birth
    // collection or mixed-audience/teen ad path is implemented. UMP/Billing/Ads are
    // attached only after the short app-owned first-use notice is complete.
    LaunchedEffect(context, state.onboardingComplete) {
        if (state.onboardingComplete) context.findActivity()?.let(resolvedBackend::attachActivity)
    }
    LaunchedEffect(initialSharedText, state.onboardingComplete) {
        if (!initialSharedText.isNullOrBlank() && state.onboardingComplete) {
            resolvedBackend.acceptSharedText(initialSharedText)
        }
    }
    DisposableEffect(lifecycleOwner, resolvedBackend, state.onboardingComplete) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME && state.onboardingComplete) resolvedBackend.onForeground()
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val banner = rememberBannerHandle(enabled = state.adRequestAllowed)
    GoodUseFrame(
        // Reserve the bottom rail as soon as ads are allowed so banner load never
        // shifts the app. The visual shell adds a non-interactive gap from navigation.
        bottomRail = if (state.adRequestAllowed) ({ LoadedBannerRail(banner) }) else null
    ) {
        when {
            !state.onboardingComplete -> StoreReadyFirstUse(storeIntroPage) {
                if (storeIntroPage < 2) {
                    storeIntroPage++
                } else {
                    // Legacy backend persists onboarding completion after two actions.
                    resolvedBackend.dispatch("ONBOARD_NEXT")
                    resolvedBackend.dispatch("ONBOARD_NEXT")
                }
            }
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
        it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}

@Preview(widthDp=1024,heightDp=768,showBackground=true)
@Composable private fun WidePreview() {
    KitchenPrepRoot(backend=PreviewKitchenBackend().also {
        it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}
