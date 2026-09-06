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
    val billingVerifiedThisSession: Boolean = false,
    val canRequestAds: Boolean = false,
    val privacyOptionsRequired: Boolean = false,
    val removeAdsFormattedPrice: String? = null,
    val removeAdsBillingPeriod: String? = null,
    val purchaseInProgress: Boolean = false,
    val lastError: String? = null,
) {
    // Fail closed for ads until Google Play has confirmed the current entitlement in
    // this process. A cached FREE value must never cause a returning subscriber to
    // briefly see an ad before Billing reconciliation completes.
    val shouldRequestAds: Boolean
        get() = entitlement == "FREE" && billingVerifiedThisSession && canRequestAds
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
    private var connectionInProgress = false
    private var purchaseQueryGeneration = 0L
    private val afterConnected = mutableListOf<() -> Unit>()

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
                // The preference is only a cold-start cache. Once the controller has
                // any in-process entitlement result, an older DataStore emission must
                // never overwrite it.
                if (_state.value.entitlement == "UNKNOWN") {
                    _state.value = _state.value.copy(entitlement = p.entitlementState)
                }
            }
        }
    }

    fun attach(activity: Activity) {
        activityRef = WeakReference(activity)
        if (!started) {
            started = true
            // There is no app-owned onboarding gate. UMP and Billing initialize as
            // soon as an Activity is available; ads still remain blocked until both
            // consent and Billing entitlement verification allow them.
            refreshConsent(activity)
            connectBilling()
        }
    }

    fun reconcile() {
        if (billingClient.isReady) {
            queryPurchases()
            refreshOfferDetails()
        } else {
            connectBilling()
        }
    }

    fun showPrivacyOptions() {
        val activity = activityRef?.get() ?: return
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { error ->
            applyConsentState(error?.message)
        }
    }

    fun purchaseRemoveAds() {
        if (_state.value.entitlement == "SUBSCRIBER_ACTIVE" || _state.value.purchaseInProgress) return
        val activity = activityRef?.get() ?: run {
            _state.value = _state.value.copy(lastError = "Google Play purchase is not available right now.")
            return
        }

        _state.value = _state.value.copy(purchaseInProgress = true, lastError = null)
        launchRemoveAdsPurchase(activity)
    }

    private fun launchRemoveAdsPurchase(activity: Activity) {
        if (!billingClient.isReady) {
            connectBilling { launchRemoveAdsPurchase(activity) }
            return
        }

        queryRemoveAdsProduct(
            onLoaded = { details, offer ->
                val phase = offer.pricingPhases.pricingPhaseList.lastOrNull()
                _state.value = _state.value.copy(
                    removeAdsFormattedPrice = phase?.formattedPrice,
                    removeAdsBillingPeriod = phase?.billingPeriod,
                    lastError = null,
                )

                val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(details)
                    .setOfferToken(offer.offerToken)
                    .build()
                val flowParams = BillingFlowParams.newBuilder()
                    .setProductDetailsParamsList(listOf(productParams))
                    .build()
                val launch = billingClient.launchBillingFlow(activity, flowParams)
                when (launch.responseCode) {
                    BillingClient.BillingResponseCode.OK -> Unit
                    BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> {
                        _state.value = _state.value.copy(purchaseInProgress = false, lastError = null)
                        queryPurchases()
                    }
                    else -> failPurchase(launch.debugMessage.ifBlank { "Google Play could not start the purchase." })
                }
            },
            onUnavailable = ::failPurchase,
        )
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        _state.value = _state.value.copy(purchaseInProgress = false)
        when {
            result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null -> {
                // Invalidate any older in-flight FREE query before applying this
                // user-initiated purchase result.
                purchaseQueryGeneration++
                processPurchases(purchases, confirmedQuery = false)
            }

            result.responseCode == BillingClient.BillingResponseCode.USER_CANCELED ->
                _state.value = _state.value.copy(lastError = null)

            result.responseCode == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> {
                _state.value = _state.value.copy(lastError = null)
                queryPurchases()
            }

            else -> _state.value = _state.value.copy(
                lastError = result.debugMessage.ifBlank { "Google Play purchase failed." },
            )
        }
    }

    private fun connectBilling(after: (() -> Unit)? = null) {
        if (billingClient.isReady) {
            _state.value = _state.value.copy(billingReady = true)
            queryPurchases()
            refreshOfferDetails()
            after?.invoke()
            return
        }

        if (after != null) afterConnected += after
        if (connectionInProgress) return
        connectionInProgress = true

        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                connectionInProgress = false
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    _state.value = _state.value.copy(billingReady = true, lastError = null)
                    queryPurchases()
                    refreshOfferDetails()
                    val callbacks = afterConnected.toList()
                    afterConnected.clear()
                    callbacks.forEach { it.invoke() }
                } else {
                    afterConnected.clear()
                    _state.value = _state.value.copy(
                        billingReady = false,
                        billingVerifiedThisSession = false,
                        purchaseInProgress = false,
                        lastError = result.debugMessage.ifBlank { "Google Play Billing is unavailable." },
                    )
                }
            }

            override fun onBillingServiceDisconnected() {
                connectionInProgress = false
                _state.value = _state.value.copy(
                    billingReady = false,
                    billingVerifiedThisSession = false,
                )
            }
        })
    }

    private fun refreshOfferDetails() {
        if (!billingClient.isReady) return
        queryRemoveAdsProduct(
            onLoaded = { _, offer ->
                val phase = offer.pricingPhases.pricingPhaseList.lastOrNull()
                _state.value = _state.value.copy(
                    removeAdsFormattedPrice = phase?.formattedPrice,
                    removeAdsBillingPeriod = phase?.billingPeriod,
                )
            },
            onUnavailable = {
                // Background catalog refresh failure should not interrupt normal app
                // use. A user-initiated purchase performs the same strict query and
                // surfaces a useful message if it still fails.
                _state.value = _state.value.copy(
                    removeAdsFormattedPrice = null,
                    removeAdsBillingPeriod = null,
                )
            },
        )
    }

    private fun queryRemoveAdsProduct(
        onLoaded: (ProductDetails, ProductDetails.SubscriptionOfferDetails) -> Unit,
        onUnavailable: (String) -> Unit,
    ) {
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(PRODUCT_ID)
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        val params = QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build()

        billingClient.queryProductDetailsAsync(params) { result, detailsResult ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                onUnavailable(result.debugMessage.ifBlank { "Google Play could not load subscription details." })
                return@queryProductDetailsAsync
            }

            val details = detailsResult.productDetailsList.firstOrNull { it.productId == PRODUCT_ID }
            if (details == null) {
                onUnavailable("Subscription product is not available from Google Play.")
                return@queryProductDetailsAsync
            }

            // Fail closed: only the exact monthly base plan with no promotional offer
            // is eligible for launch. Never silently substitute another base plan.
            val offer = details.subscriptionOfferDetails
                ?.firstOrNull { it.basePlanId == BASE_PLAN_ID && it.offerId == null }
            if (offer == null) {
                onUnavailable("The monthly remove-ads plan is not available from Google Play.")
                return@queryProductDetailsAsync
            }

            onLoaded(details, offer)
        }
    }

    private fun queryPurchases() {
        if (!billingClient.isReady) {
            _state.value = _state.value.copy(billingVerifiedThisSession = false)
            return
        }

        val generation = ++purchaseQueryGeneration
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            // Ignore stale callbacks. This prevents an older pre-purchase FREE query
            // from racing a newer subscriber result and re-enabling ads.
            if (generation != purchaseQueryGeneration) return@queryPurchasesAsync

            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                processPurchases(purchases, confirmedQuery = true)
            } else {
                _state.value = _state.value.copy(
                    billingVerifiedThisSession = false,
                    lastError = result.debugMessage.ifBlank { "Google Play could not verify the subscription." },
                )
            }
        }
    }

    private fun processPurchases(purchases: List<Purchase>, confirmedQuery: Boolean) {
        val relevant = purchases.filter { PRODUCT_ID in it.products }
        val purchased = relevant.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }

        purchased.filter { !it.isAcknowledged }.forEach(::acknowledgeWithRetry)

        val entitlement = when {
            purchased.isNotEmpty() -> "SUBSCRIBER_ACTIVE"
            confirmedQuery -> "FREE"
            else -> _state.value.entitlement
        }

        _state.value = _state.value.copy(
            entitlement = entitlement,
            billingVerifiedThisSession = _state.value.billingVerifiedThisSession || confirmedQuery,
            lastError = null,
        )
        scope.launch { preferences.setEntitlement(entitlement) }
    }

    private fun acknowledgeWithRetry(purchase: Purchase, attempt: Int = 0) {
        if (purchase.isAcknowledged) return
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient.acknowledgePurchase(params) { result ->
            when {
                result.responseCode == BillingClient.BillingResponseCode.OK -> Unit

                result.responseCode == BillingClient.BillingResponseCode.ITEM_NOT_OWNED -> {
                    // Refresh Play's authoritative state rather than repeatedly
                    // acknowledging a token Play says is stale.
                    queryPurchases()
                }

                isTransientBillingError(result.responseCode) && attempt < MAX_ACK_RETRIES -> {
                    val delayMs = ACK_RETRY_BASE_MS * (1L shl attempt)
                    scope.launch {
                        delay(delayMs)
                        acknowledgeWithRetry(purchase, attempt + 1)
                    }
                }

                else -> _state.value = _state.value.copy(
                    lastError = result.debugMessage.ifBlank {
                        "Google Play could not acknowledge the subscription. It will be retried later."
                    },
                )
            }
        }
    }

    private fun isTransientBillingError(code: Int): Boolean = code in setOf(
        BillingClient.BillingResponseCode.SERVICE_DISCONNECTED,
        BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE,
        BillingClient.BillingResponseCode.NETWORK_ERROR,
        BillingClient.BillingResponseCode.ERROR,
    )

    private fun refreshConsent(activity: Activity) {
        val params = ConsentRequestParameters.Builder().build()
        consentInformation.requestConsentInfoUpdate(
            activity,
            params,
            {
                // A previous-session consent state can already permit ads immediately
                // after this update, even before a form is shown.
                applyConsentState(null)
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { formError ->
                    applyConsentState(formError?.message)
                }
            },
            { error ->
                // UMP explicitly recommends checking canRequestAds() even after an
                // update error because a valid consent state may exist from a prior
                // session.
                applyConsentState(error.message)
            },
        )
    }

    private fun applyConsentState(errorMessage: String?) {
        val canRequestAds = consentInformation.canRequestAds()
        _state.value = _state.value.copy(
            canRequestAds = canRequestAds,
            privacyOptionsRequired =
                consentInformation.privacyOptionsRequirementStatus ==
                    ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
            // A recoverable UMP error should not interrupt the user when a valid
            // previous-session consent state still permits ads.
            lastError = if (errorMessage != null && !canRequestAds) errorMessage else null,
        )
    }

    private fun failPurchase(message: String) {
        _state.value = _state.value.copy(
            purchaseInProgress = false,
            lastError = message,
        )
    }

    fun close() {
        afterConnected.clear()
        billingClient.endConnection()
    }

    companion object {
        const val PRODUCT_ID = "remove_ads_monthly"
        const val BASE_PLAN_ID = "monthly"
        const val LAUNCH_US_BASE_PRICE = "US$1.49/month"
        private const val MAX_ACK_RETRIES = 4
        private const val ACK_RETRY_BASE_MS = 1_000L
    }
}
