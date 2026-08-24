package studio.gooduse.kitchenprep

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import java.util.Calendar

/**
 * Neutral age screen used before UMP, Billing, Mobile Ads, or any age-dependent
 * advertising path is initialized. The entered date is used only to derive
 * TEEN / ADULT / BLOCKED and is not persisted.
 */
@Composable
fun NeutralAgeGate(
    blocked: Boolean,
    onResolved: (AgeTreatment) -> Unit,
) {
    if (blocked) {
        Column(
            Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("Kitchen Prep Board", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(18.dp))
            Card(Modifier.fillMaxWidth()) {
                Text(
                    "This version isn't available for this age.",
                    Modifier.padding(18.dp),
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
        }
        return
    }

    var month by rememberSaveable { mutableStateOf("") }
    var day by rememberSaveable { mutableStateOf("") }
    var year by rememberSaveable { mutableStateOf("") }
    var invalid by rememberSaveable { mutableStateOf(false) }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp, vertical = 30.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Spacer(Modifier.height(10.dp))
        Text("Kitchen Prep Board", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
        Text("Your date of birth", style = MaterialTheme.typography.titleLarge)
        Text(
            "Enter your date of birth. It is used on this device to choose the appropriate app and advertising treatment. The date itself is not saved.",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                month,
                { month = it.filter(Char::isDigit).take(2); invalid = false },
                Modifier.weight(1f),
                label = { Text("Month") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
            OutlinedTextField(
                day,
                { day = it.filter(Char::isDigit).take(2); invalid = false },
                Modifier.weight(1f),
                label = { Text("Day") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
            OutlinedTextField(
                year,
                { year = it.filter(Char::isDigit).take(4); invalid = false },
                Modifier.weight(1.25f),
                label = { Text("Year") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
        }

        if (invalid) {
            Text("Enter a valid date.", color = MaterialTheme.colorScheme.error)
        }

        Button(
            onClick = {
                val treatment = resolveAgeTreatment(month, day, year)
                if (treatment == null) invalid = true else onResolved(treatment)
            },
            enabled = month.isNotBlank() && day.isNotBlank() && year.length == 4,
            modifier = Modifier.fillMaxWidth().heightIn(min = 54.dp),
        ) { Text("Continue") }
    }
}

private fun resolveAgeTreatment(monthText: String, dayText: String, yearText: String): AgeTreatment? {
    val month = monthText.toIntOrNull() ?: return null
    val day = dayText.toIntOrNull() ?: return null
    val year = yearText.toIntOrNull() ?: return null
    val now = Calendar.getInstance()
    val dob = Calendar.getInstance().apply {
        isLenient = false
        clear()
        set(Calendar.YEAR, year)
        set(Calendar.MONTH, month - 1)
        set(Calendar.DAY_OF_MONTH, day)
    }
    try {
        dob.timeInMillis
    } catch (_: IllegalArgumentException) {
        return null
    }
    if (dob.after(now)) return null
    var age = now.get(Calendar.YEAR) - dob.get(Calendar.YEAR)
    val birthdayPassed = now.get(Calendar.MONTH) > dob.get(Calendar.MONTH) ||
        (now.get(Calendar.MONTH) == dob.get(Calendar.MONTH) && now.get(Calendar.DAY_OF_MONTH) >= dob.get(Calendar.DAY_OF_MONTH))
    if (!birthdayPassed) age--
    return when {
        age < 0 -> null
        age < 16 -> AgeTreatment.BLOCKED
        age < 18 -> AgeTreatment.TEEN
        else -> AgeTreatment.ADULT
    }
}

/**
 * Store-review first-use flow after age treatment is resolved.
 *
 * This intentionally does not request notification or exact-alarm permissions.
 * Those permissions belong at the moment the user starts a feature that needs them.
 * The privacy page is notice only; Google UMP remains the consent mechanism where
 * advertising consent/privacy messaging is legally or contractually required.
 */
@Composable
fun StoreReadyFirstUse(page: Int, next: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    val safeOpen: (String) -> Unit = { url -> if (url.startsWith("https://")) uriHandler.openUri(url) }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp, vertical = 28.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Spacer(Modifier.height(8.dp))
        Text("Kitchen Prep Board", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)

        when (page.coerceIn(0, 2)) {
            0 -> {
                Text("Prep work, clearly ordered.", style = MaterialTheme.typography.titleLarge)
                StoreInfoCard("On device", "Boards and prep data stay in app-private local storage.")
                StoreInfoCard("No account", "Start without creating an account or cloud profile.")
                Text(
                    "Language follows the device/app locale. The release UI must be supplied through localized Android string resources.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            1 -> {
                Text("Privacy & ads", style = MaterialTheme.typography.titleLarge)
                StoreInfoCard("Local-first", "Your kitchen boards are not uploaded to a GoodUse Studios cloud database.")
                StoreInfoCard(
                    "Free version",
                    "Google Mobile Ads may process device and app-use information for ad serving, measurement and fraud prevention. Age treatment and Google privacy choices are applied before ads are requested.",
                )
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedButton(
                        onClick = { safeOpen(BuildConfig.PRIVACY_POLICY_URL) },
                        enabled = BuildConfig.PRIVACY_POLICY_URL.startsWith("https://"),
                    ) { Text("Privacy") }
                    OutlinedButton(
                        onClick = { safeOpen(BuildConfig.TERMS_URL) },
                        enabled = BuildConfig.TERMS_URL.startsWith("https://"),
                    ) { Text("Terms") }
                }
                Text(
                    "This page is information, not advertising consent. Google UMP handles required advertising consent/privacy choices separately.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            else -> {
                Text("A board in three moves", style = MaterialTheme.typography.titleLarge)
                StoreStep(1, "Add or paste", "Capture the prep work.")
                StoreStep(2, "Review", "Check tasks, quantities and area.")
                StoreStep(3, "Time & run", "Set the timing goal and work from Live.")
            }
        }

        Spacer(Modifier.weight(1f, fill = false))
        Button(onClick = next, modifier = Modifier.fillMaxWidth().heightIn(min = 54.dp)) {
            Text(if (page >= 2) "Start" else "Continue")
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            repeat(3) { index ->
                Text(if (index == page.coerceIn(0, 2)) "●" else "○", modifier = Modifier.padding(horizontal = 4.dp))
            }
        }
    }
}

@Composable
private fun StoreInfoCard(title: String, detail: String) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(title, fontWeight = FontWeight.SemiBold)
            Text(detail, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
private fun StoreStep(number: Int, title: String, detail: String) {
    Card(Modifier.fillMaxWidth()) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Surface(shape = MaterialTheme.shapes.large, color = MaterialTheme.colorScheme.primaryContainer) {
                Box(Modifier.size(38.dp), contentAlignment = Alignment.Center) {
                    Text(number.toString(), fontWeight = FontWeight.Bold)
                }
            }
            Column {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(detail, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}
