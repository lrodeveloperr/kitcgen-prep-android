package studio.gooduse.kitchenprep.data

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.kitchenDataStore by preferencesDataStore(name = "kitchen_prep_preferences")

data class KitchenPreferenceState(
    val onboardingComplete: Boolean = false,
    val safetyAcknowledged: Boolean = false,
    val screenState: String = "HOME",
    val settingsReturnState: String = "HOME",
    val entitlementState: String = "UNKNOWN",
    val lastEntitlementVerifiedAt: Long? = null,
)

class KitchenPreferences(private val context: Context) {
    private object Keys {
        val ONBOARDING = booleanPreferencesKey("onboarding_complete")
        val SAFETY_ACK = booleanPreferencesKey("safety_acknowledged")
        val SCREEN = stringPreferencesKey("screen_state")
        val SETTINGS_RETURN = stringPreferencesKey("settings_return_state")
        val ENTITLEMENT = stringPreferencesKey("entitlement_state")
        val ENTITLEMENT_AT = longPreferencesKey("entitlement_verified_at")
    }

    val state: Flow<KitchenPreferenceState> = context.kitchenDataStore.data.map { p ->
        KitchenPreferenceState(
            onboardingComplete = p[Keys.ONBOARDING] ?: false,
            safetyAcknowledged = p[Keys.SAFETY_ACK] ?: false,
            screenState = p[Keys.SCREEN] ?: "HOME",
            settingsReturnState = p[Keys.SETTINGS_RETURN] ?: "HOME",
            entitlementState = p[Keys.ENTITLEMENT] ?: "UNKNOWN",
            lastEntitlementVerifiedAt = p[Keys.ENTITLEMENT_AT],
        )
    }

    suspend fun setOnboardingComplete(value: Boolean) = context.kitchenDataStore.edit { it[Keys.ONBOARDING] = value }
    suspend fun setSafetyAcknowledged(value: Boolean) = context.kitchenDataStore.edit { it[Keys.SAFETY_ACK] = value }
    suspend fun setScreen(value: String) = context.kitchenDataStore.edit { it[Keys.SCREEN] = value }
    suspend fun setSettingsReturn(value: String) = context.kitchenDataStore.edit { it[Keys.SETTINGS_RETURN] = value }
    suspend fun setEntitlement(value: String, verifiedAt: Long = System.currentTimeMillis()) = context.kitchenDataStore.edit {
        it[Keys.ENTITLEMENT] = value
        it[Keys.ENTITLEMENT_AT] = verifiedAt
    }

    /**
     * Deletes app-owned local preference/profile state while leaving the Play-derived
     * entitlement cache in place. Billing reconciliation remains authoritative.
     */
    suspend fun clearLocalAppState() = context.kitchenDataStore.edit { p ->
        p.remove(Keys.ONBOARDING)
        p.remove(Keys.SAFETY_ACK)
        p.remove(Keys.SCREEN)
        p.remove(Keys.SETTINGS_RETURN)
    }
}
