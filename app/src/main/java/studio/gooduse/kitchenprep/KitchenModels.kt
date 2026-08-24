package studio.gooduse.kitchenprep

enum class BackendState {
    HOME, CREATE_BOARD, QUICK_REVIEW, SELECT_MODE, MODE_SPECIFIC_SETUP, PREP_GAP,
    TIMING_OBJECTIVE, BUILD_EXECUTION_GRAPH, READY_OVERVIEW, RUN_BOARD, PAUSED_BOARD,
    FINISH, REUSE_OR_HOME, SETTINGS
}
enum class BoardMode { HOME, STATION }
enum class TimingMode { COOK_NOW, SERVE_AT, READY_BY }
enum class TaskStatus { BLOCKED, AVAILABLE, ACTIVE, WAITING, DONE, SKIPPED }

data class PrepTask(
    val id:String,
    val text:String,
    val status:TaskStatus,
    val minutes:Int?=null,
    val detail:String?=null,
    val attention:Boolean=false,
    val timerDeadlineAt:Long?=null,
)

data class PrepGapUi(
    val taskId: String,
    val taskText: String,
    val target: Double,
    val onHand: Double,
    val make: Double,
    val unit: String,
    val verified: Boolean,
)

data class RecentBoardUi(
    val id: String,
    val title: String,
    val status: String,
    val taskCount: Int? = null,
)

data class KitchenUiState(
    val backendState:BackendState = BackendState.HOME,
    val onboardingPage:Int = 0,
    val onboardingComplete:Boolean = false,
    val safetyDisclosureNeeded:Boolean = true,
    val boardTitle:String = "Dinner prep",
    val sourceText:String = "",
    val sourceType:String = "MANUAL",
    val referenceUrl:String = "",
    val mode:BoardMode? = null,
    val timing:TimingMode? = null,
    val targetReadyAt:Long? = null,
    val paused:Boolean = false,
    val adLoaded:Boolean = false,
    val adRequestAllowed:Boolean = false,
    val privacyChoicesRequired:Boolean = false,
    val entitlementState:String = "UNKNOWN",
    val removeAdsFormattedPrice:String? = null,
    val removeAdsBillingPeriod:String? = null,
    val purchaseInProgress:Boolean = false,
    val settingsReturn:BackendState = BackendState.HOME,
    val tasks:List<PrepTask> = emptyList(),
    val prepGaps:List<PrepGapUi> = emptyList(),
    val recentBoards:List<RecentBoardUi> = emptyList(),
    val userMessage:String? = null,
)

val previewTasks = listOf(
    PrepTask("t1","Roast vegetables",TaskStatus.ACTIVE,18,"Oven • started 7 min ago"),
    PrepTask("t2","Make herb dressing",TaskStatus.AVAILABLE,8,"No dependency"),
    PrepTask("t3","Rest cooked chicken",TaskStatus.WAITING,6,"Timer running"),
    PrepTask("t4","Warm plates",TaskStatus.BLOCKED,4,"After roast vegetables"),
    PrepTask("t5","Wash salad leaves",TaskStatus.DONE,5,"Completed"),
)
