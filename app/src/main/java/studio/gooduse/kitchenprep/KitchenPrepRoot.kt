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

    val ageResolved = state.ageTreatment == AgeTreatment.TEEN || state.ageTreatment == AgeTreatment.ADULT

    // No UMP, Billing connection, or Mobile Ads initialization occurs until the app
    // has resolved an admitted age-treatment category and completed the short app-owned
    // first-use privacy notice. The entered date of birth is never persisted.
    LaunchedEffect(context, state.onboardingComplete, state.ageTreatment) {
        if (state.onboardingComplete && ageResolved) {
            context.findActivity()?.let(resolvedBackend::attachActivity)
        }
    }
    LaunchedEffect(initialSharedText) {
        if (!initialSharedText.isNullOrBlank() && ageResolved && state.onboardingComplete) {
            resolvedBackend.acceptSharedText(initialSharedText)
        }
    }
    DisposableEffect(lifecycleOwner, resolvedBackend, state.onboardingComplete, state.ageTreatment) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME && state.onboardingComplete && ageResolved) {
                resolvedBackend.onForeground()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val banner = rememberBannerHandle(
        enabled = state.adRequestAllowed,
        ageTreatment = state.ageTreatment,
    )
    GoodUseFrame(
        bottomRail = if (banner.loaded) ({ LoadedBannerRail(banner) }) else null
    ) {
        when {
            state.ageTreatment == AgeTreatment.UNKNOWN -> NeutralAgeGate(blocked = false) {
                resolvedBackend.dispatch("AGE_RESOLVED", it.name)
            }
            state.ageTreatment == AgeTreatment.BLOCKED -> NeutralAgeGate(blocked = true) { }
            !state.onboardingComplete -> StoreReadyFirstUse(storeIntroPage) {
                if (storeIntroPage < 2) {
                    storeIntroPage++
                } else {
                    // Legacy backend persists onboarding completion after two ONBOARD_NEXT
                    // actions. Keep that storage contract unchanged for this branch.
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
        it.dispatch("AGE_RESOLVED","ADULT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}

@Preview(widthDp=1024,heightDp=768,showBackground=true)
@Composable private fun WidePreview() {
    KitchenPrepRoot(backend=PreviewKitchenBackend().also {
        it.dispatch("AGE_RESOLVED","ADULT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("ONBOARD_NEXT"); it.dispatch("NEW_BOARD");
        it.dispatch("INPUT_CAPTURED", "Chop onions\nRoast vegetables"); it.dispatch("REVIEW_CONFIRMED");
        it.dispatch("MODE_STATION"); it.dispatch("MODE_CONFIRMED"); it.dispatch("PREP_GAP_CONFIRMED");
        it.dispatch("TIMING_COOK_NOW"); it.dispatch("BOARD_STARTED")
    })
}
