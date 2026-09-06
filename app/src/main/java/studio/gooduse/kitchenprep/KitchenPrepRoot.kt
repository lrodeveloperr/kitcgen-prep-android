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

    // No app-owned onboarding. Attach monetization immediately; UMP and Billing still
    // independently gate whether an ad request is permitted.
    LaunchedEffect(context, resolvedBackend) {
        context.findActivity()?.let(resolvedBackend::attachActivity)
    }
    LaunchedEffect(initialSharedText, resolvedBackend) {
        if (!initialSharedText.isNullOrBlank()) {
            resolvedBackend.acceptSharedText(initialSharedText)
        }
    }
    DisposableEffect(lifecycleOwner, resolvedBackend) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) resolvedBackend.onForeground()
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    GoodUseFrame(
        // The rail exists before the ad itself loads, preventing ad-load layout shift.
        // A subscriber never gets the rail because Billing is verified first.
        bottomRail = if (state.adRequestAllowed) ({ LoadedBannerRail(enabled = true) }) else null
    ) {
        when {
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
        it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}

@Preview(widthDp=1024,heightDp=768,showBackground=true)
@Composable private fun WidePreview() {
    KitchenPrepRoot(backend=PreviewKitchenBackend().also {
        it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}
