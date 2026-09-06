package studio.gooduse.kitchenprep

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Store-readiness Settings route. The remove-ads row displays pricing returned by
 * Google Play ProductDetails. The US launch base is $1.49/month, but the UI never
 * hard-codes that storefront price because Google Play localizes price/currency.
 */
@Composable
fun StoreReadySettingsScreen(s: KitchenUiState, dispatch: (String, String?) -> Unit) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    var deleteConfirm by remember { mutableStateOf(false) }

    fun open(url: String) {
        if (url.startsWith("https://")) uriHandler.openUri(url)
    }

    fun manageSubscription() {
        val uri = Uri.parse(
            "https://play.google.com/store/account/subscriptions?sku=remove_ads_monthly&package=${context.packageName}"
        )
        context.startActivity(Intent(Intent.ACTION_VIEW, uri))
    }

    val priceDetail = when {
        s.purchaseInProgress -> "Opening Google Play…"
        s.removeAdsFormattedPrice != null && s.removeAdsBillingPeriod == "P1M" ->
            "${s.removeAdsFormattedPrice} per month · auto-renewing"
        s.removeAdsFormattedPrice != null ->
            "${s.removeAdsFormattedPrice} · auto-renewing subscription"
        else ->
            "Monthly auto-renewing subscription. Google Play will show the localized price before purchase."
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 20.dp),
    ) {
        item {
            Text("Settings", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        }

        item {
            StoreSettingsGroup("Privacy & data") {
                StoreLinkRow("Privacy Policy", BuildConfig.PRIVACY_POLICY_URL.isNotBlank()) { open(BuildConfig.PRIVACY_POLICY_URL) }
                HorizontalDivider()
                StoreLinkRow(
                    "Privacy choices",
                    s.privacyChoicesRequired,
                    if (s.privacyChoicesRequired) "Google privacy options" else "No Google privacy-options form is required for this session",
                ) { dispatch("PRIVACY_CHOICES", null) }
                HorizontalDivider()
                StoreLinkRow("Delete local data", true, "Boards, tasks, templates, timers and learning history") { deleteConfirm = true }
            }
        }

        item {
            StoreSettingsGroup("Legal & support") {
                StoreLinkRow("Terms of Use", BuildConfig.TERMS_URL.isNotBlank()) { open(BuildConfig.TERMS_URL) }
                HorizontalDivider()
                StoreLinkRow("Safety Notice", BuildConfig.SAFETY_URL.isNotBlank()) { open(BuildConfig.SAFETY_URL) }
                HorizontalDivider()
                StoreLinkRow("Support", BuildConfig.SUPPORT_URL.isNotBlank()) { open(BuildConfig.SUPPORT_URL) }
            }
        }

        item {
            StoreSettingsGroup("Ads & subscription") {
                if (s.entitlementState == "SUBSCRIBER_ACTIVE") {
                    StoreLinkRow("Ad-free", false, "Active Google Play subscription") { }
                } else {
                    StoreLinkRow(
                        "Remove ads",
                        !s.purchaseInProgress,
                        priceDetail,
                    ) { dispatch("REMOVE_ADS", null) }
                }
                HorizontalDivider()
                StoreLinkRow("Manage subscription", true) { manageSubscription() }
                if (BuildConfig.SUBSCRIPTION_TERMS_URL.isNotBlank()) {
                    HorizontalDivider()
                    StoreLinkRow("Subscription terms", true) { open(BuildConfig.SUBSCRIPTION_TERMS_URL) }
                }
            }
        }

        item {
            StoreSettingsGroup("About") {
                Text(
                    "Kitchen Prep Board is an organizational aid. Timers and task completion do not prove food safety, doneness, allergen control, storage safety or freedom from cross-contamination.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp),
                )
            }
        }

        item {
            Button(
                onClick = { dispatch("CLOSE_SETTINGS", null) },
                modifier = Modifier.fillMaxWidth().heightIn(min = 52.dp),
            ) { Text("Done") }
        }
    }

    if (deleteConfirm) {
        AlertDialog(
            onDismissRequest = { deleteConfirm = false },
            title = { Text("Delete local data?") },
            text = { Text("This deletes app data stored on this device. It does not cancel a Google Play subscription.") },
            confirmButton = {
                TextButton(onClick = {
                    dispatch("DELETE_LOCAL_DATA", null)
                    deleteConfirm = false
                }) { Text("Delete") }
            },
            dismissButton = { TextButton(onClick = { deleteConfirm = false }) { Text("Cancel") } },
        )
    }
}

@Composable
private fun StoreSettingsGroup(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Card(Modifier.fillMaxWidth()) { Column(content = content) }
    }
}

@Composable
private fun StoreLinkRow(
    title: String,
    enabled: Boolean,
    detail: String? = null,
    onClick: () -> Unit,
) {
    ListItem(
        headlineContent = { Text(title, fontWeight = FontWeight.Medium) },
        supportingContent = detail?.let { { Text(it) } },
        trailingContent = {
            TextButton(onClick = onClick, enabled = enabled) {
                Text(if (enabled) "Open" else "—")
            }
        },
    )
}
