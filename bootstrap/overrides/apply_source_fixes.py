from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one match in {path}, found {count}: {old!r}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


# Play Billing 9.x: preserve suspended-subscription reconciliation using the
# current QueryPurchasesParams.Builder API rather than weakening entitlement checks.
replace_once(
    "app/src/main/java/com/goodusestudios/kitchenprep/platform/MonetizationCoordinator.kt",
    ".setIncludeSuspendedSubscriptions(true)",
    ".includeSuspendedSubscriptions(true)",
)

# Compose saveable state lives in the runtime.saveable package on the API-36
# compatible Compose baseline. Keep navigation selection restorable.
replace_once(
    "app/src/main/java/com/goodusestudios/kitchenprep/ui/TimelinePulseApp.kt",
    "import androidx.compose.runtime.*\n",
    "import androidx.compose.runtime.*\nimport androidx.compose.runtime.saveable.rememberSaveable\n",
)

# Opt in only where the stable product intentionally uses Material3 bottom
# sheets; do not blanket-suppress experimental API diagnostics across the app.
replace_once(
    "app/src/main/java/com/goodusestudios/kitchenprep/ui/screens/HomeScreen.kt",
    "@Composable\nprivate fun CreateBoardSheet",
    "@OptIn(ExperimentalMaterial3Api::class)\n@Composable\nprivate fun CreateBoardSheet",
)
replace_once(
    "app/src/main/java/com/goodusestudios/kitchenprep/ui/screens/SettingsScreen.kt",
    "@Composable\nfun SettingsScreen",
    "@OptIn(ExperimentalMaterial3Api::class)\n@Composable\nfun SettingsScreen",
)

pulse = "app/src/main/java/com/goodusestudios/kitchenprep/ui/screens/TimelinePulseScreen.kt"
replace_once(
    pulse,
    "GoodUseIcons.ACT_ADDAlarm",
    "GoodUseIcons.ACT_ADD",
)
for function_name in ("AddTaskSheet", "TimingObjectiveSheet", "FinishBoardSheet"):
    replace_once(
        pulse,
        f"@Composable\nprivate fun {function_name}",
        f"@OptIn(ExperimentalMaterial3Api::class)\n@Composable\nprivate fun {function_name}",
    )
