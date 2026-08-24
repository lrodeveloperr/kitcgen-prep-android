package studio.gooduse.kitchenprep

import android.app.Activity
import androidx.compose.runtime.*

interface KitchenBackendPort {
    val state: State<KitchenUiState>
    fun dispatch(action:String, payload:String?=null)
    fun attachActivity(activity: Activity) {}
    fun acceptSharedText(text: String) {}
    fun onForeground() {}
}

class PreviewKitchenBackend(initialSharedText:String?=null): KitchenBackendPort {
    private val mutable = mutableStateOf(
        KitchenUiState(
            backendState = if (initialSharedText.isNullOrBlank()) BackendState.HOME else BackendState.QUICK_REVIEW,
            sourceText = initialSharedText.orEmpty(),
            sourceType = if (initialSharedText.isNullOrBlank()) "MANUAL" else "ANDROID_SHARE_TEXT",
            tasks = previewTasks,
            recentBoards = listOf(RecentBoardUi("preview","Dinner prep","COMPLETED",8)),
        )
    )
    override val state: State<KitchenUiState> get() = mutable

    override fun dispatch(action:String,payload:String?) {
        val s=mutable.value
        mutable.value = when(action) {
            "AGE_RESOLVED" -> s.copy(ageTreatment=runCatching { AgeTreatment.valueOf(payload.orEmpty()) }.getOrDefault(AgeTreatment.UNKNOWN))
            "ONBOARD_NEXT" -> if (s.onboardingPage < 1) s.copy(onboardingPage=s.onboardingPage+1)
                               else s.copy(onboardingComplete=true)
            "NEW_BOARD","CREATE_PASTE","CREATE_REFERENCE" -> s.copy(backendState=BackendState.CREATE_BOARD, sourceType=when(action){"CREATE_PASTE"->"PASTE_TEXT";"CREATE_REFERENCE"->"REFERENCE_URL";else->"MANUAL"})
            "INPUT_CAPTURED","REFERENCE_INPUT_CAPTURED" -> s.copy(backendState=BackendState.QUICK_REVIEW, sourceText=payload?.substringAfter('\u0000') ?: s.sourceText)
            "EDIT_INPUT" -> s.copy(backendState=BackendState.CREATE_BOARD)
            "REVIEW_CONFIRMED" -> s.copy(backendState=BackendState.SELECT_MODE)
            "MODE_HOME" -> s.copy(backendState=BackendState.MODE_SPECIFIC_SETUP,mode=BoardMode.HOME)
            "MODE_STATION" -> s.copy(backendState=BackendState.MODE_SPECIFIC_SETUP,mode=BoardMode.STATION)
            "MODE_CONFIRMED" -> s.copy(backendState=if(s.mode==BoardMode.STATION) BackendState.PREP_GAP else BackendState.TIMING_OBJECTIVE)
            "PREP_GAP_CONFIRMED" -> s.copy(backendState=BackendState.TIMING_OBJECTIVE)
            "TIMING_COOK_NOW" -> s.copy(backendState=BackendState.READY_OVERVIEW,timing=TimingMode.COOK_NOW)
            "TIMING_SERVE_AT" -> s.copy(backendState=BackendState.READY_OVERVIEW,timing=TimingMode.SERVE_AT,targetReadyAt=payload?.toLongOrNull())
            "TIMING_READY_BY" -> s.copy(backendState=BackendState.READY_OVERVIEW,timing=TimingMode.READY_BY,targetReadyAt=payload?.toLongOrNull())
            "BOARD_STARTED" -> s.copy(backendState=BackendState.RUN_BOARD)
            "PAUSE" -> s.copy(backendState=BackendState.PAUSED_BOARD,paused=true)
            "RESUME","FINISH_CONTINUE" -> s.copy(backendState=BackendState.RUN_BOARD,paused=false)
            "OPEN_FINISH" -> s.copy(backendState=BackendState.FINISH)
            "FINISH_ANYWAY" -> s.copy(backendState=BackendState.REUSE_OR_HOME)
            "RETURN_HOME" -> s.copy(backendState=BackendState.HOME)
            "SETTINGS" -> s.copy(settingsReturn=s.backendState,backendState=BackendState.SETTINGS)
            "CLOSE_SETTINGS" -> s.copy(backendState=s.settingsReturn)
            "SAFETY_ACK" -> s.copy(safetyDisclosureNeeded=false)
            "TASK_COMPLETE" -> s.copy(tasks=s.tasks.map { if(it.id==payload) it.copy(status=TaskStatus.DONE) else it })
            "TASK_START","TASK_START_OVERRIDE" -> s.copy(tasks=s.tasks.map { if(it.id==payload) it.copy(status=TaskStatus.ACTIVE) else it })
            "TASK_SKIP" -> s.copy(tasks=s.tasks.map { if(it.id==payload) it.copy(status=TaskStatus.SKIPPED) else it })
            "TASK_UNDO" -> s.copy(tasks=s.tasks.map { if(it.id==payload) it.copy(status=TaskStatus.AVAILABLE) else it })
            else -> s
        }
    }
}
