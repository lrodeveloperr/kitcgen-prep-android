package studio.gooduse.kitchenprep.monetization

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import com.google.android.ump.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import studio.gooduse.kitchenprep.data.KitchenPreferences
import java.lang.ref.WeakReference


data class MonetizationState(
    val entitlement: String = "UNKNOWN",
    val billingReady: Boolean = false,
    val canRequestAds: Boolean = false,
    val privacyOptionsRequired: Boolean = false,
    val lastError: String? = null,
) {
    val shouldRequestAds: Boolean get() = entitlement == "FREE" && canRequestAds
}

class MonetizationController(
    context: Context,
    private val preferences: KitchenPreferences,
    private val scope: CoroutineScope,
) : PurchasesUpdatedListener {
    private val appContext = context.applicationContext
    private val consentInformation = UserMessagingPlatform.getConsentInformation(appContext)
    private var activityRef: WeakReference<Activity>? = null
    private var started = false
    @Volatile private var ageTreatment: String = "UNKNOWN"

    private val _state = MutableStateFlow(MonetizationState())
    val state: StateFlow<MonetizationState> = _state

    private val billingClient = BillingClient.newBuilder(appContext)
        .setListener(this)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    init {
        scope.launch {
            preferences.state.collect { p ->
                ageTreatment = p.ageTreatmentState
                if (_state.value.entitlement != p.entitlementState) {
                    _state.value = _state.value.copy(entitlement = p.entitlementState)
                }
            }
        }
    }

    fun attach(activity: Activity) {
        if (ageTreatment !in setOf("TEEN", "ADULT")) return
        activityRef = WeakReference(activity)
        if (!started) {
            started = true
            refreshConsent(activity)
            connectBilling()
        }
    }

    fun reconcile() {
        if (ageTreatment !in setOf("TEEN", "ADULT")) return
        if (billingClient.isReady) queryPurchases() else connectBilling()
    }

    fun showPrivacyOptions() {
        val activity = activityRef?.get() ?: return
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { error ->
            _state.value = _state.value.copy(
                canRequestAds = consentInformation.canRequestAds(),
                privacyOptionsRequired = consentInformation.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
                lastError = error?.message,
            )
        }
    }

    fun purchaseRemoveAds() {
        val activity = activityRef?.get() ?: return
        if (!billingClient.isReady) {
            connectBilling { purchaseRemoveAds() }
            return
        }
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(PRODUCT_ID)
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        val params = QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build()
        billingClient.queryProductDetailsAsync(params) { result, detailsResult ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                _state.value = _state.value.copy(lastError = result.debugMessage)
                return@queryProductDetailsAsync
            }
            val details = detailsResult.productDetailsList.firstOrNull { it.productId == PRODUCT_ID } ?: run {
                _state.value = _state.value.copy(lastError = "Subscription product is not available from Google Play.")
                return@queryProductDetailsAsync
            }
            val offer = details.subscriptionOfferDetails
                ?.firstOrNull { it.basePlanId == BASE_PLAN_ID && it.offerId == null }
                ?: details.subscriptionOfferDetails?.firstOrNull { it.basePlanId == BASE_PLAN_ID }
                ?: details.subscriptionOfferDetails?.firstOrNull()
            if (offer == null) {
                _state.value = _state.value.copy(lastError = "No eligible subscription offer is available.")
                return@queryProductDetailsAsync
            }
            val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
                .setProductDetails(details)
                .setOfferToken(offer.offerToken)
                .build()
            val flowParams = BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(productParams)).build()
            val launch = billingClient.launchBillingFlow(activity, flowParams)
            if (launch.responseCode != BillingClient.BillingResponseCode.OK) {
                _state.value = _state.value.copy(lastError = launch.debugMessage)
            }
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            processPurchases(purchases, confirmedQuery = false)
        } else if (result.responseCode != BillingClient.BillingResponseCode.USER_CANCELED) {
            _state.value = _state.value.copy(lastError = result.debugMessage)
        }
    }

    private fun connectBilling(afterConnected: (() -> Unit)? = null) {
        if (billingClient.isReady) {
            queryPurchases()
            afterConnected?.invoke()
            return
        }
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    _state.value = _state.value.copy(billingReady = true, lastError = null)
                    queryPurchases()
                    afterConnected?.invoke()
                } else {
                    _state.value = _state.value.copy(billingReady = false, lastError = result.debugMessage)
                }
            }
            override fun onBillingServiceDisconnected() {
                _state.value = _state.value.copy(billingReady = false)
            }
        })
    }

    private fun queryPurchases() {
        val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                processPurchases(purchases, confirmedQuery = true)
            } else {
                _state.value = _state.value.copy(lastError = result.debugMessage)
            }
        }
    }

    private fun processPurchases(purchases: List<Purchase>, confirmedQuery: Boolean) {
        val relevant = purchases.filter { PRODUCT_ID in it.products }
        val purchased = relevant.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }
        purchased.filter { !it.isAcknowledged }.forEach { purchase ->
            val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()
            billingClient.acknowledgePurchase(params) { }
        }
        val entitlement = when {
            purchased.isNotEmpty() -> "SUBSCRIBER_ACTIVE"
            confirmedQuery -> "FREE"
            else -> _state.value.entitlement
        }
        if (entitlement != _state.value.entitlement || confirmedQuery) {
            _state.value = _state.value.copy(entitlement = entitlement, lastError = null)
            scope.launch { preferences.setEntitlement(entitlement) }
        }
    }

    private fun refreshConsent(activity: Activity) {
        // For 16–17 users, use UMP's under-age-of-consent tag conservatively. UMP
        // does not forward this to the Mobile Ads SDK; AdBanner.kt independently sets
        // Google's TEEN age-restricted treatment on every ad request path.
        val params = ConsentRequestParameters.Builder()
            .setTagForUnderAgeOfConsent(ageTreatment == "TEEN")
            .build()
        consentInformation.requestConsentInfoUpdate(
            activity,
            params,
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { formError ->
                    _state.value = _state.value.copy(
                        canRequestAds = consentInformation.canRequestAds(),
                        privacyOptionsRequired = consentInformation.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
                        lastError = formError?.message,
                    )
                }
            },
            { error ->
                _state.value = _state.value.copy(canRequestAds = false, lastError = error.message)
            },
        )
    }

    fun close() { billingClient.endConnection() }

    companion object {
        const val PRODUCT_ID = "remove_ads_monthly"
        const val BASE_PLAN_ID = "monthly"
    }
}
