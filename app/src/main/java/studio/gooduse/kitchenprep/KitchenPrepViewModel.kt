package studio.gooduse.kitchenprep

import android.app.Activity
import android.app.Application
import androidx.compose.runtime.*
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import studio.gooduse.kitchenprep.data.*
import studio.gooduse.kitchenprep.monetization.MonetizationController
import studio.gooduse.kitchenprep.monetization.MonetizationState
import studio.gooduse.kitchenprep.timers.TimerScheduler
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.ceil

class KitchenPrepViewModel(app: Application) : AndroidViewModel(app), KitchenBackendPort {
    private val preferences = KitchenPreferences(app)
    private val repository = KitchenRepository(KitchenDatabase.get(app), TimerScheduler(app))
    private val monetization = MonetizationController(app, preferences, viewModelScope)
    private val mutable = mutableStateOf(KitchenUiState())
    override val state: State<KitchenUiState> get() = mutable
    private val actionMutex = Mutex()
    private var onboardingPage = 0
    private val lastShared = AtomicReference<String?>(null)

    init {
        viewModelScope.launch {
            combine(repository.snapshot, preferences.state, monetization.state) { snapshot, pref, money ->
                buildUiState(snapshot, pref, money)
            }.collect { mutable.value = it }
        }
    }

    override fun attachActivity(activity: Activity) { monetization.attach(activity) }
    override fun onForeground() { monetization.reconcile() }

    override fun acceptSharedText(text: String) {
        if (text.isBlank() || lastShared.getAndSet(text) == text) return
        viewModelScope.launch {
            actionMutex.withLock {
                repository.beginBoard("ANDROID_SHARE_TEXT", text)
                preferences.setScreen(BackendState.QUICK_REVIEW.name)
            }
        }
    }

    override fun dispatch(action: String, payload: String?) {
        viewModelScope.launch {
            actionMutex.withLock {
                when (action) {
                    "ONBOARD_NEXT" -> {
                        if (onboardingPage < 1) onboardingPage++ else preferences.setOnboardingComplete(true)
                        mutable.value = mutable.value.copy(onboardingPage = onboardingPage)
                    }
                    "SAFETY_ACK" -> preferences.setSafetyAcknowledged(true)
                    "NEW_BOARD" -> begin("MANUAL")
                    "CREATE_PASTE" -> begin("PASTE_TEXT")
                    "CREATE_REFERENCE" -> begin("REFERENCE_URL")
                    "DUPLICATE_BOARD" -> {
                        val created = repository.duplicateLatestBoard()
                        if (created == null) {
                            mutable.value = mutable.value.copy(userMessage = "No finished board to duplicate.")
                            preferences.setScreen(BackendState.HOME.name)
                        } else preferences.setScreen(BackendState.QUICK_REVIEW.name)
                    }
                    "DUPLICATE_TEMPLATE" -> {
                        val created = repository.duplicateLatestTemplate()
                        if (created == null) {
                            mutable.value = mutable.value.copy(userMessage = "No saved template yet.")
                        } else preferences.setScreen(BackendState.QUICK_REVIEW.name)
                    }
                    "INPUT_CAPTURED" -> {
                        repository.captureInput(payload.orEmpty())
                        preferences.setScreen(BackendState.QUICK_REVIEW.name)
                    }
                    "REFERENCE_INPUT_CAPTURED" -> {
                        val parts = payload.orEmpty().split('\u0000', limit = 2)
                        repository.captureReferenceInput(parts.getOrElse(0) { "" }, parts.getOrElse(1) { "" })
                        preferences.setScreen(BackendState.QUICK_REVIEW.name)
                    }
                    "EDIT_INPUT" -> preferences.setScreen(BackendState.CREATE_BOARD.name)
                    "REVIEW_CONFIRMED" -> preferences.setScreen(BackendState.SELECT_MODE.name)
                    "MODE_HOME" -> { repository.setMode("HOME"); preferences.setScreen(BackendState.MODE_SPECIFIC_SETUP.name) }
                    "MODE_STATION" -> { repository.setMode("STATION"); preferences.setScreen(BackendState.MODE_SPECIFIC_SETUP.name) }
                    "MODE_CONFIRMED" -> preferences.setScreen(if (mutable.value.mode == BoardMode.STATION) BackendState.PREP_GAP.name else BackendState.TIMING_OBJECTIVE.name)
                    "PREP_GAP_SET" -> parsePrepGap(payload)?.let { (id,target,unit,onHand,verified) -> repository.setPrepGap(id,target,unit,onHand,verified) }
                    "PREP_GAP_CONFIRMED" -> preferences.setScreen(BackendState.TIMING_OBJECTIVE.name)
                    "TIMING_COOK_NOW" -> setTiming("COOK_NOW", null)
                    "TIMING_SERVE_AT" -> setTiming("SERVE_AT", payload?.toLongOrNull())
                    "TIMING_READY_BY" -> setTiming("READY_BY", payload?.toLongOrNull())
                    "BOARD_STARTED" -> { repository.startBoard(); preferences.setScreen(BackendState.RUN_BOARD.name) }
                    "TASK_START" -> handleStartTask(payload.orEmpty(), false)
                    "TASK_START_OVERRIDE" -> handleStartTask(payload.orEmpty(), true)
                    "TASK_COMPLETE" -> repository.completeTask(payload.orEmpty())
                    "TASK_SKIP" -> repository.skipTask(payload.orEmpty())
                    "TASK_UNDO" -> repository.undoTask(payload.orEmpty())
                    "TASK_PRIORITIZE" -> repository.prioritizeTask(payload.orEmpty())
                    "TIMER_ADD_1" -> repository.extendTaskTimer(payload.orEmpty(), 60)
                    "TIMER_ADD_2" -> repository.extendTaskTimer(payload.orEmpty(), 120)
                    "TIMER_ADD_5" -> repository.extendTaskTimer(payload.orEmpty(), 300)
                    "PAUSE" -> { repository.pauseBoard(); preferences.setScreen(BackendState.PAUSED_BOARD.name) }
                    "RESUME" -> { repository.resumeBoard(); preferences.setScreen(BackendState.RUN_BOARD.name) }
                    "OPEN_FINISH" -> preferences.setScreen(BackendState.FINISH.name)
                    "FINISH_CONTINUE" -> preferences.setScreen(if (mutable.value.paused) BackendState.PAUSED_BOARD.name else BackendState.RUN_BOARD.name)
                    "FINISH_ANYWAY" -> { repository.finishBoard(); preferences.setScreen(BackendState.REUSE_OR_HOME.name) }
                    "SAVE_TEMPLATE" -> { repository.saveTemplate(); mutable.value = mutable.value.copy(userMessage = "Template saved.") }
                    "ADD_NOTE" -> repository.addNote(payload.orEmpty())
                    "RETURN_HOME" -> preferences.setScreen(BackendState.HOME.name)
                    "SETTINGS" -> {
                        preferences.setSettingsReturn(mutable.value.backendState.name)
                        preferences.setScreen(BackendState.SETTINGS.name)
                    }
                    "CLOSE_SETTINGS" -> preferences.setScreen(mutable.value.settingsReturn.name)
                    "PRIVACY_CHOICES" -> monetization.showPrivacyOptions()
                    "REMOVE_ADS" -> monetization.purchaseRemoveAds()
                    "DELETE_LOCAL_DATA" -> {
                        repository.deleteAllLocalData()
                        preferences.clearLocalAppState()
                        mutable.value = mutable.value.copy(userMessage = "Local app data deleted. Any Play subscription remains separate.")
                    }
                    "CANCEL_BOARD" -> { repository.cancelBoard(); preferences.setScreen(BackendState.HOME.name) }
                }
            }
        }
    }

    private suspend fun handleStartTask(taskId: String, allowDependencyOverride: Boolean) {
        when (repository.startTask(taskId, allowDependencyOverride)) {
            StartTaskResult.STARTED -> Unit
            StartTaskResult.ALREADY_RUNNING -> mutable.value = mutable.value.copy(userMessage = "This task is already active.")
            StartTaskResult.DEPENDENCIES_UNRESOLVED -> mutable.value = mutable.value.copy(userMessage = "Complete its dependencies first, or use the explicit override.")
            StartTaskResult.NOT_STARTABLE -> mutable.value = mutable.value.copy(userMessage = "This task cannot be started in its current state.")
            StartTaskResult.NOT_FOUND -> mutable.value = mutable.value.copy(userMessage = "Task not found.")
        }
    }

    private suspend fun begin(source: String) {
        repository.beginBoard(source)
        preferences.setScreen(BackendState.CREATE_BOARD.name)
    }

    private suspend fun setTiming(mode: String, target: Long?) {
        if (mode != "COOK_NOW" && target == null) return
        repository.setTiming(mode, target)
        preferences.setScreen(BackendState.BUILD_EXECUTION_GRAPH.name)
        try {
            repository.buildExecutionGraph()
            preferences.setScreen(BackendState.READY_OVERVIEW.name)
        } catch (e: DependencyCycleException) {
            mutable.value = mutable.value.copy(userMessage = "A dependency cycle prevents automatic scheduling. Edit or explicitly override the dependency.")
            preferences.setScreen(BackendState.QUICK_REVIEW.name)
        }
    }

    private fun buildUiState(snapshot: BoardSnapshot, pref: KitchenPreferenceState, money: MonetizationState): KitchenUiState {
        val board = snapshot.board
        val resolvedScreen = recoverScreen(pref.screenState, board)
        val timersByTask = snapshot.timers.associateBy { it.taskId }
        val now = System.currentTimeMillis()
        val tasks = snapshot.tasks.map { task ->
            val timer = timersByTask[task.id]
            val minutes = task.estimatedDurationSeconds?.let { ceil(it / 60.0).toInt() }
            val detail = when {
                timer?.state == "EXPIRED_ATTENTION_REQUIRED" -> "Timer expired • attention required"
                timer?.state == "RUNNING" -> "Timer running • ${ceil(((timer.deadlineAt - now).coerceAtLeast(0L)) / 60000.0).toInt()} min left"
                task.suggestedStartAt != null -> "Suggested schedule"
                else -> null
            }
            PrepTask(
                id = task.id,
                text = task.displayText,
                status = runCatching { TaskStatus.valueOf(task.status) }.getOrDefault(TaskStatus.AVAILABLE),
                minutes = minutes,
                detail = detail,
                attention = timer?.state == "EXPIRED_ATTENTION_REQUIRED",
                timerDeadlineAt = timer?.deadlineAt,
            )
        }
        val taskTextById = tasks.associate { it.id to it.text }
        val gaps = snapshot.prepGaps.map { gap ->
            PrepGapUi(gap.taskId, taskTextById[gap.taskId] ?: "Task", gap.targetValue, gap.onHandValue, gap.makeValue, gap.targetUnit, gap.verified)
        }
        val recent = snapshot.recentBoards.filter { it.status in setOf("COMPLETED", "ARCHIVED_INCOMPLETE") }.map {
            RecentBoardUi(it.id, it.title, it.status)
        }
        return KitchenUiState(
            backendState = resolvedScreen,
            onboardingPage = onboardingPage,
            onboardingComplete = pref.onboardingComplete,
            safetyDisclosureNeeded = !pref.safetyAcknowledged,
            boardTitle = board?.title ?: "Dinner prep",
            sourceText = board?.draftText.orEmpty(),
            sourceType = board?.sourceType ?: "MANUAL",
            referenceUrl = board?.referenceUrl.orEmpty(),
            mode = board?.mode?.let { runCatching { BoardMode.valueOf(it) }.getOrNull() },
            timing = board?.timingMode?.let { runCatching { TimingMode.valueOf(it) }.getOrNull() },
            targetReadyAt = board?.targetReadyAt,
            paused = board?.status == "PAUSED",
            adRequestAllowed = money.shouldRequestAds,
            privacyChoicesRequired = money.privacyOptionsRequired,
            entitlementState = money.entitlement,
            removeAdsFormattedPrice = money.removeAdsFormattedPrice,
            removeAdsBillingPeriod = money.removeAdsBillingPeriod,
            purchaseInProgress = money.purchaseInProgress,
            settingsReturn = runCatching { BackendState.valueOf(pref.settingsReturnState) }.getOrDefault(BackendState.HOME),
            tasks = tasks,
            prepGaps = gaps,
            recentBoards = recent,
            userMessage = money.lastError ?: mutable.value.userMessage,
        )
    }

    private fun recoverScreen(requested: String, board: BoardEntity?): BackendState {
        val parsed = runCatching { BackendState.valueOf(requested) }.getOrDefault(BackendState.HOME)
        if (parsed == BackendState.SETTINGS || parsed == BackendState.REUSE_OR_HOME) return parsed
        return when (board?.status) {
            "ACTIVE" -> if (parsed == BackendState.FINISH) parsed else BackendState.RUN_BOARD
            "PAUSED" -> if (parsed == BackendState.FINISH) parsed else BackendState.PAUSED_BOARD
            "READY" -> BackendState.READY_OVERVIEW
            "DRAFT" -> parsed.takeIf { it !in setOf(BackendState.HOME, BackendState.RUN_BOARD, BackendState.PAUSED_BOARD, BackendState.REUSE_OR_HOME) } ?: BackendState.CREATE_BOARD
            else -> BackendState.HOME
        }
    }

    private fun parsePrepGap(payload: String?): PrepGapParts? {
        val p = payload.orEmpty().split('|')
        if (p.size < 5) return null
        return PrepGapParts(p[0], p[1].toDoubleOrNull() ?: return null, p[2], p[3].toDoubleOrNull() ?: return null, p[4].toBoolean())
    }

    override fun onCleared() {
        monetization.close()
        super.onCleared()
    }

    private data class PrepGapParts(val taskId:String,val target:Double,val unit:String,val onHand:Double,val verified:Boolean)
}
