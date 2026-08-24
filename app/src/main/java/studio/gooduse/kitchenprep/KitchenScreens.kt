package studio.gooduse.kitchenprep

import android.app.TimePickerDialog
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.*
import studio.gooduse.shell.*
import java.util.Calendar
import java.util.Date
import kotlin.math.max

@Composable
fun OnboardingScreen(page:Int, next:()->Unit) {
    Column(
        Modifier.fillMaxSize().padding(vertical=24.dp),
        verticalArrangement=Arrangement.SpaceBetween
    ) {
        Column(verticalArrangement=Arrangement.spacedBy(16.dp)) {
            Text(if(page==0) "Kitchen Prep Board" else "A board in three moves", style=MaterialTheme.typography.headlineLarge)
            if(page==0) {
                Text("Prep without the scramble", style=MaterialTheme.typography.titleLarge)
                Text("See what to do now, what comes next, and what needs attention—without turning your station into restaurant software.")
                GUSection {
                    Text("Local-first. No account. Your boards stay on this device.", color=MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else {
                Step(1,"Add or paste your tasks")
                Step(2,"Choose Home or Station mode")
                Step(3,"Choose Cook now, Serve at, or Ready by, then run the board")
            }
        }
        GUPrimary(if(page==0) "Continue" else "Start", next)
    }
}

@Composable private fun Step(n:Int,text:String) {
    Row(verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(12.dp)) {
        Surface(shape=RoundedCornerShape(999.dp),color=MaterialTheme.colorScheme.primary.copy(alpha=.12f)) {
            Text("$n",Modifier.padding(horizontal=12.dp,vertical=8.dp),fontWeight=FontWeight.SemiBold,color=MaterialTheme.colorScheme.primary)
        }
        Text(text,style=MaterialTheme.typography.bodyLarge)
    }
}

@Composable
fun KitchenScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    when(s.backendState) {
        BackendState.HOME -> HomeScreen(s,dispatch)
        BackendState.CREATE_BOARD -> CreateScreen(s,dispatch)
        BackendState.QUICK_REVIEW -> ReviewScreen(s,dispatch)
        BackendState.SELECT_MODE -> ModeScreen(s,dispatch)
        BackendState.MODE_SPECIFIC_SETUP -> ModeSetupScreen(s,dispatch)
        BackendState.PREP_GAP -> PrepGapScreen(s,dispatch)
        BackendState.TIMING_OBJECTIVE -> TimingScreen(s,dispatch)
        BackendState.BUILD_EXECUTION_GRAPH -> BuildScreen()
        BackendState.READY_OVERVIEW -> ReadyScreen(s,dispatch)
        BackendState.RUN_BOARD -> RunBoardScreen(s,false,dispatch)
        BackendState.PAUSED_BOARD -> RunBoardScreen(s,true,dispatch)
        BackendState.FINISH -> FinishScreen(s,dispatch)
        BackendState.REUSE_OR_HOME -> ReuseScreen(s,dispatch)
        BackendState.SETTINGS -> SettingsScreen(s,dispatch)
    }
}

@Composable private fun SettingsButton(onClick:()->Unit) {
    IconButton(onClick=onClick,modifier=Modifier.size(48.dp)) {
        GoodUseVectorIcon("settings",Modifier.size(24.dp))
    }
}

@Composable
private fun HomeScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    LazyColumn(verticalArrangement=Arrangement.spacedBy(16.dp),contentPadding=PaddingValues(bottom=24.dp)) {
        item {
            GUHeader("Kitchen Prep Board","Tell the cook what to do now, what comes next, and how to get everything ready together.") {
                SettingsButton { dispatch("SETTINGS",null) }
            }
        }
        s.userMessage?.let { message -> item { GUStatus(message,"success") } }
        item {
            GUSection(emphasis=true) {
                Text("Start a board",style=MaterialTheme.typography.titleLarge)
                Text("Build from scratch or bring in task text. Nothing is uploaded.")
                GUPrimary("New prep board",{ dispatch("NEW_BOARD",null) },iconKey="plus")
            }
        }
        item {
            Text("Start from",style=MaterialTheme.typography.titleLarge)
            ActionRow("Paste task text","Split non-empty lines into editable tasks") { dispatch("CREATE_PASTE",null) }
            ActionRow("Use latest template","Create a fresh board from your most recently saved template") { dispatch("DUPLICATE_TEMPLATE",null) }
            ActionRow("Duplicate latest board","Reuse structure without carrying live timers or task status") { dispatch("DUPLICATE_BOARD",null) }
            ActionRow("Reference URL","Store a URL as a reference only. The app does not fetch or scrape it.") { dispatch("CREATE_REFERENCE",null) }
        }
        item {
            Text("Recent",style=MaterialTheme.typography.titleLarge)
            if (s.recentBoards.isEmpty()) {
                GUSection { Text("No finished boards yet.",color=MaterialTheme.colorScheme.onSurfaceVariant) }
            } else {
                s.recentBoards.take(3).forEach { recent ->
                    GUSection {
                        Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(recent.title,fontWeight=FontWeight.SemiBold)
                                Text(recent.status.replace('_',' ').lowercase().replaceFirstChar { it.uppercase() },color=MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            GoodUseVectorIcon("history",Modifier.size(22.dp),MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
private fun ActionRow(title:String,body:String,onClick:()->Unit,enabled:Boolean=true) {
    Surface(onClick=onClick,enabled=enabled,color=Color.Transparent,modifier=Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(vertical=12.dp),horizontalArrangement=Arrangement.spacedBy(12.dp)) {
            Column(Modifier.weight(1f)) {
                Text(title,fontWeight=FontWeight.SemiBold,color=if(enabled) LocalContentColor.current else MaterialTheme.colorScheme.onSurfaceVariant)
                if(body.isNotBlank()) Text(body,color=MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text("›",fontSize=24.sp,color=MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun CreateScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    var text by remember(s.sourceText) { mutableStateOf(s.sourceText) }
    var url by remember(s.referenceUrl) { mutableStateOf(s.referenceUrl) }
    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader(
            if(s.sourceType=="REFERENCE_URL") "Add reference and prep tasks" else "Add prep tasks",
            if(s.sourceType=="REFERENCE_URL") "The URL is stored only; enter the tasks you want on the board." else "Paste a list or type one task per line."
        )
        if(s.safetyDisclosureNeeded) {
            GUSection("Before your first board") {
                Text("This app is an organizational aid only. It does not guarantee food safety or doneness.")
                GUPrimary("I understand",{dispatch("SAFETY_ACK",null)})
            }
        }
        if(s.sourceType=="REFERENCE_URL") {
            OutlinedTextField(url,{url=it},modifier=Modifier.fillMaxWidth(),label={Text("Reference URL")},supportingText={Text("Stored locally. Never fetched or scraped by the app.")})
        }
        OutlinedTextField(
            text,{text=it},modifier=Modifier.fillMaxWidth().heightIn(min=220.dp),label={Text("Tasks")},
            supportingText={Text(if(s.sourceType in setOf("PASTE_TEXT","ANDROID_SHARE_TEXT")) "Original pasted/shared text is preserved." else "One task per non-empty line.")}
        )
        GUPrimary(
            "Review tasks",
            {
                if(s.sourceType=="REFERENCE_URL") dispatch("REFERENCE_INPUT_CAPTURED","$url\u0000$text")
                else dispatch("INPUT_CAPTURED",text)
            },
            enabled=text.lines().any { it.isNotBlank() }
        )
    }
}

@Composable
private fun ReviewScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    LazyColumn(verticalArrangement=Arrangement.spacedBy(12.dp),contentPadding=PaddingValues(bottom=24.dp)) {
        item { GUHeader("Quick review","Confirm the task list and rough duration suggestions before the board is scheduled.") }
        if(s.referenceUrl.isNotBlank()) item { GUSection("Reference") { Text(s.referenceUrl); Text("Storage only • not fetched",color=MaterialTheme.colorScheme.onSurfaceVariant) } }
        itemsIndexed(s.tasks) { i,t ->
            GUSection {
                Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
                    Text("${i+1}",Modifier.width(28.dp),color=MaterialTheme.colorScheme.onSurfaceVariant)
                    Column(Modifier.weight(1f)) {
                        Text(t.text,fontWeight=FontWeight.SemiBold)
                        Text(t.minutes?.let { "Suggested duration • $it min" } ?: "No duration suggestion",color=MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
        item { GUSecondary("Edit task list",{dispatch("EDIT_INPUT",null)}) }
        item { GUPrimary("Choose mode",{dispatch("REVIEW_CONFIRMED",null)},enabled=s.tasks.isNotEmpty()) }
    }
}

@Composable
private fun ModeScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    Column(Modifier.padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader("Where are you cooking?","This changes the setup flow, not your task text.")
        GUSection {
            Text("Home",style=MaterialTheme.typography.titleLarge)
            Text("A focused cooking board without station prep-gap tracking.")
            GUSecondary("Use Home mode",{dispatch("MODE_HOME",null)})
        }
        GUSection(emphasis=true) {
            Text("Station",style=MaterialTheme.typography.titleLarge)
            Text("Track target, on-hand and make quantities before running the station.")
            GUPrimary("Use Station mode",{dispatch("MODE_STATION",null)})
        }
    }
}

@Composable
private fun ModeSetupScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    Column(Modifier.padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader(if(s.mode==BoardMode.STATION) "Station board" else "Home board","Your task text stays unchanged. You can override suggestions later.")
        GUSection {
            Text(if(s.mode==BoardMode.STATION) "Prep-gap tracking is available for this board." else "No station inventory or procurement layer is added.")
        }
        GUPrimary("Continue",{dispatch("MODE_CONFIRMED",null)})
    }
}

@Composable
private fun PrepGapScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    LazyColumn(verticalArrangement=Arrangement.spacedBy(12.dp),contentPadding=PaddingValues(bottom=24.dp)) {
        item { GUHeader("Prep gap","Set what you need, what you have on hand, and what must be made. Quantities are local to this board.") }
        items(s.tasks,key={it.id}) { task ->
            val existing=s.prepGaps.firstOrNull{it.taskId==task.id}
            var target by remember(task.id,existing?.target) { mutableStateOf(existing?.target?.takeIf{it!=0.0}?.toString().orEmpty()) }
            var onHand by remember(task.id,existing?.onHand) { mutableStateOf(existing?.onHand?.takeIf{it!=0.0}?.toString().orEmpty()) }
            var unit by remember(task.id,existing?.unit) { mutableStateOf(existing?.unit ?: "count") }
            var verified by remember(task.id,existing?.verified) { mutableStateOf(existing?.verified ?: false) }
            val targetN=target.toDoubleOrNull()
            val onHandN=onHand.toDoubleOrNull()
            val make=if(targetN!=null&&onHandN!=null) max(targetN-onHandN,0.0) else null
            GUSection {
                Text(task.text,fontWeight=FontWeight.SemiBold)
                Row(horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(target,{target=it},Modifier.weight(1f),label={Text("Target")},singleLine=true,keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal))
                    OutlinedTextField(onHand,{onHand=it},Modifier.weight(1f),label={Text("On hand")},singleLine=true,keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal))
                }
                OutlinedTextField(unit,{unit=it},Modifier.fillMaxWidth(),label={Text("Unit")},singleLine=true,supportingText={Text("Examples: count, g, kg, ml, l, tsp, tbsp, cup, oz, lb")})
                if(make!=null) Text("Make ${formatQuantity(make)} $unit",fontWeight=FontWeight.SemiBold)
                Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.SpaceBetween) {
                    Column(Modifier.weight(1f)) {
                        Text("On-hand verified")
                        Text("Unverified values remain visibly flagged.",color=MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Switch(checked=verified,onCheckedChange={verified=it})
                }
                if(!verified) GUStatus("On-hand not verified","warning")
                GUSecondary("Save quantities",{
                    if(targetN!=null&&onHandN!=null&&unit.isNotBlank()) dispatch("PREP_GAP_SET","${task.id}|$targetN|${unit.trim()}|$onHandN|$verified")
                },enabled=targetN!=null&&onHandN!=null&&unit.isNotBlank())
            }
        }
        item { Text("On-hand resets per shift. This is not an inventory ledger.",color=MaterialTheme.colorScheme.onSurfaceVariant) }
        item { GUPrimary("Set timing",{dispatch("PREP_GAP_CONFIRMED",null)}) }
    }
}

private fun formatQuantity(v:Double):String = if(v%1.0==0.0) v.toLong().toString() else "%.2f".format(v).trimEnd('0').trimEnd('.')

@Composable
private fun TimingScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    val context=LocalContext.current
    fun pick(action:String) {
        val now=Calendar.getInstance()
        TimePickerDialog(context,{_,hour,minute ->
            val target=Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY,hour); set(Calendar.MINUTE,minute); set(Calendar.SECOND,0); set(Calendar.MILLISECOND,0)
                if(timeInMillis<=System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR,1)
            }
            dispatch(action,target.timeInMillis.toString())
        },now.get(Calendar.HOUR_OF_DAY),now.get(Calendar.MINUTE),android.text.format.DateFormat.is24HourFormat(context)).show()
    }
    Column(Modifier.padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader("Timing objective","The schedule is a suggestion. Your overrides always win.")
        Choice("Cook now","Start from the current time.") { dispatch("TIMING_COOK_NOW",null) }
        Choice("Serve at","Choose a serving time; the app schedules backward from it.") { pick("TIMING_SERVE_AT") }
        Choice("Ready by","Choose a deadline; the app schedules backward from it.") { pick("TIMING_READY_BY") }
        s.targetReadyAt?.let { Text("Current target: ${android.text.format.DateFormat.getTimeFormat(context).format(Date(it))}",color=MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}

@Composable
private fun Choice(title:String,body:String,onClick:()->Unit) {
    Surface(onClick=onClick,modifier=Modifier.fillMaxWidth(),shape=RoundedCornerShape(16.dp),border=BorderStroke(1.dp,MaterialTheme.colorScheme.outline),color=MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(6.dp)) { Text(title,fontWeight=FontWeight.SemiBold); Text(body,color=MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}

@Composable
private fun BuildScreen() {
    Column(verticalArrangement=Arrangement.spacedBy(16.dp)) { GUHeader("Building suggested schedule"); LinearProgressIndicator(Modifier.fillMaxWidth()); Text("Checking dependencies, durations and available resources.") }
}

@Composable
private fun ReadyScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    LazyColumn(verticalArrangement=Arrangement.spacedBy(12.dp),contentPadding=PaddingValues(bottom=24.dp)) {
        item { GUHeader("Ready to run","Suggested schedule • ${if(s.timing==TimingMode.COOK_NOW) "Cook now" else "Target time set"}") { SettingsButton{dispatch("SETTINGS",null)} } }
        items(s.tasks.filter{it.status!=TaskStatus.DONE}) { t -> TaskRow(t) }
        item { Text("Suggestions are not guarantees. Reorder or override when reality changes.",color=MaterialTheme.colorScheme.onSurfaceVariant) }
        item { GUPrimary("Start board",{dispatch("BOARD_STARTED",null)},iconKey="play",enabled=s.tasks.isNotEmpty()) }
    }
}

@Composable
private fun RunBoardScreen(s:KitchenUiState, paused:Boolean, dispatch:(String,String?)->Unit) {
    val rt=LocalGoodUse.current
    val now=s.tasks.filter{it.status==TaskStatus.ACTIVE}
    val next=s.tasks.filter{it.status==TaskStatus.AVAILABLE || it.status==TaskStatus.BLOCKED}
    val waiting=s.tasks.filter{it.status==TaskStatus.WAITING}
    val done=s.tasks.filter{it.status==TaskStatus.DONE || it.status==TaskStatus.SKIPPED}

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader(s.boardTitle, if(paused) "Paused • timers continue" else "Board running") { SettingsButton{dispatch("SETTINGS",null)} }
        if(paused) {
            GUSection(emphasis=true) {
                GUStatus("Paused","warning")
                Text("Pausing the board does not pause or extend existing timer deadlines.")
                GUPrimary("Resume board",{dispatch("RESUME",null)},iconKey="resume")
            }
        }
        if(rt.wideBoard) {
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(16.dp),verticalAlignment=Alignment.Top) {
                Lane("Now",now,Modifier.weight(1.1f),active=true,paused=paused,dispatch=dispatch)
                Lane("Next",next,Modifier.weight(1f),paused=paused,dispatch=dispatch)
                Lane("Waiting",waiting,Modifier.weight(1f),waiting=true,paused=paused,dispatch=dispatch)
            }
        } else {
            Lane("Now",now,active=true,paused=paused,dispatch=dispatch)
            if(waiting.isNotEmpty()) Lane("Waiting",waiting,waiting=true,paused=paused,dispatch=dispatch)
            Lane("Next",next,paused=paused,dispatch=dispatch)
        }
        if(done.isNotEmpty()) Lane("Done",done,paused=paused,dispatch=dispatch)
        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {
            if(!paused) GUSecondary("Pause",{dispatch("PAUSE",null)},iconKey="pause",modifier=Modifier.weight(1f))
            GUSecondary("Finish",{dispatch("OPEN_FINISH",null)},modifier=Modifier.weight(1f))
        }
    }
}

@Composable
private fun Lane(title:String,tasks:List<PrepTask>,modifier:Modifier=Modifier,active:Boolean=false,waiting:Boolean=false,paused:Boolean=false,dispatch:(String,String?)->Unit) {
    var overrideTask by remember { mutableStateOf<PrepTask?>(null) }
    GUSection(title,modifier=modifier,emphasis=active) {
        if(tasks.isEmpty()) Text("Nothing here",color=MaterialTheme.colorScheme.onSurfaceVariant)
        tasks.forEach { t ->
            Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)) {
                    Column(Modifier.weight(1f)) {
                        Text(t.text,fontWeight=FontWeight.SemiBold)
                        t.detail?.let { Text(it,color=MaterialTheme.colorScheme.onSurfaceVariant) }
                    }
                    t.minutes?.let { Text("${it}m",fontWeight=FontWeight.SemiBold) }
                }
                when {
                    active -> {
                        if(t.attention) GUStatus("Attention required","warning")
                        GUPrimary("Complete",{dispatch("TASK_COMPLETE",t.id)},iconKey="complete")
                        Row(horizontalArrangement=Arrangement.spacedBy(2.dp)) {
                            GUTextAction("+1",{dispatch("TIMER_ADD_1",t.id)})
                            GUTextAction("+2",{dispatch("TIMER_ADD_2",t.id)})
                            GUTextAction("+5",{dispatch("TIMER_ADD_5",t.id)})
                            GUTextAction("Skip",{dispatch("TASK_SKIP",t.id)})
                        }
                    }
                    waiting -> {
                        if(t.attention) GUStatus("Attention required","warning") else GUStatus("Timer running")
                        GUSecondary("Complete",{dispatch("TASK_COMPLETE",t.id)},iconKey="complete")
                        Row(horizontalArrangement=Arrangement.spacedBy(2.dp)) {
                            GUTextAction("+1",{dispatch("TIMER_ADD_1",t.id)})
                            GUTextAction("+2",{dispatch("TIMER_ADD_2",t.id)})
                            GUTextAction("+5",{dispatch("TIMER_ADD_5",t.id)})
                            GUTextAction("Skip",{dispatch("TASK_SKIP",t.id)})
                        }
                    }
                    t.status==TaskStatus.AVAILABLE -> {
                        GUPrimary("Start task",{dispatch("TASK_START",t.id)},iconKey="play",enabled=!paused)
                        if(!paused) Row(horizontalArrangement=Arrangement.spacedBy(4.dp)) {
                            GUTextAction("Do next instead",{dispatch("TASK_PRIORITIZE",t.id)})
                            GUTextAction("Skip",{dispatch("TASK_SKIP",t.id)})
                        }
                    }
                    t.status==TaskStatus.BLOCKED -> {
                        GUStatus("Blocked")
                        GUSecondary("Start anyway",{overrideTask=t},enabled=!paused)
                        if(!paused) GUTextAction("Skip",{dispatch("TASK_SKIP",t.id)})
                    }
                    t.status==TaskStatus.DONE || t.status==TaskStatus.SKIPPED -> {
                        GUStatus(if(t.status==TaskStatus.DONE) "Done" else "Skipped",if(t.status==TaskStatus.DONE) "success" else "neutral")
                        GUSecondary("Undo",{dispatch("TASK_UNDO",t.id)})
                    }
                }
                HorizontalDivider(color=MaterialTheme.colorScheme.outline.copy(alpha=.5f))
            }
        }
    }
    overrideTask?.let { task ->
        AlertDialog(
            onDismissRequest={overrideTask=null},
            title={Text("Override dependencies?")},
            text={Text("${task.text} is blocked by unfinished dependencies. Starting anyway records an explicit override for this task.")},
            confirmButton={TextButton(onClick={dispatch("TASK_START_OVERRIDE",task.id);overrideTask=null}){Text("Start anyway")}},
            dismissButton={TextButton(onClick={overrideTask=null}){Text("Cancel")}}
        )
    }
}

@Composable private fun TaskRow(t:PrepTask) {
    GUSection {
        Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) { Text(t.text,fontWeight=FontWeight.SemiBold); t.detail?.let{Text(it,color=MaterialTheme.colorScheme.onSurfaceVariant)} }
            t.minutes?.let{Text("${it} min",fontWeight=FontWeight.Medium)}
        }
    }
}

@Composable
private fun FinishScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    val unfinished=s.tasks.count{it.status!=TaskStatus.DONE && it.status!=TaskStatus.SKIPPED}
    Column(Modifier.padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader("Finish board","$unfinished tasks are unfinished.")
        GUSection { Text("Finish anyway archives the board as incomplete. It does not mark remaining tasks done.") }
        GUPrimary("Continue board",{dispatch("FINISH_CONTINUE",null)})
        GUSecondary("Finish anyway",{dispatch("FINISH_ANYWAY",null)})
    }
}

@Composable
private fun ReuseScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    var noteOpen by remember { mutableStateOf(false) }
    var note by remember { mutableStateOf("") }
    Column(Modifier.padding(bottom=24.dp),verticalArrangement=Arrangement.spacedBy(16.dp)) {
        GUHeader("Board saved","Reuse the structure without carrying live task state or timers.")
        s.userMessage?.let { GUStatus(it,"success") }
        GUSecondary("Save as template",{dispatch("SAVE_TEMPLATE",null)},iconKey="save")
        GUSecondary("Add note",{noteOpen=true})
        GUPrimary("Return home",{dispatch("RETURN_HOME",null)})
    }
    if(noteOpen) AlertDialog(
        onDismissRequest={noteOpen=false},
        title={Text("Board note")},
        text={OutlinedTextField(note,{note=it},label={Text("Note")},modifier=Modifier.fillMaxWidth())},
        confirmButton={TextButton(onClick={dispatch("ADD_NOTE",note);noteOpen=false}){Text("Save")}},
        dismissButton={TextButton(onClick={noteOpen=false}){Text("Cancel")}}
    )
}

@Composable
private fun SettingsScreen(s:KitchenUiState, dispatch:(String,String?)->Unit) {
    var deleteConfirm by remember { mutableStateOf(false) }
    var helpOpen by remember { mutableStateOf(false) }
    LazyColumn(verticalArrangement=Arrangement.spacedBy(16.dp),contentPadding=PaddingValues(bottom=24.dp)) {
        item { GUHeader("Settings","Local-first controls and support.") }
        s.userMessage?.let { item { GUStatus(it,"success") } }
        item {
            Text("Preferences",style=MaterialTheme.typography.titleLarge)
            GUSection {
                ActionRow("Language","Uses the device/app locale in this build",{},enabled=false)
                HorizontalDivider()
                ActionRow("Locale","Uses the current Android locale in this build",{},enabled=false)
                HorizontalDivider()
                ActionRow("Units","Task quantities preserve the unit you enter",{},enabled=false)
                HorizontalDivider()
                ActionRow("Temperature","No automatic food-safety temperature logic is performed",{},enabled=false)
            }
        }
        item {
            Text("Privacy & data",style=MaterialTheme.typography.titleLarge)
            GUSection {
                ActionRow("Privacy choices",if(s.privacyChoicesRequired) "Open Google UMP privacy options" else "No privacy-options form is required for this session",{dispatch("PRIVACY_CHOICES",null)},enabled=s.privacyChoicesRequired)
                HorizontalDivider()
                ActionRow("Export local data","Versioned export endpoint is backend-ready; Android document picker UI is not configured in this skin",{},enabled=false)
                HorizontalDivider()
                ActionRow("Import local data","Import validation is backend-defined; Android document picker UI is not configured in this skin",{},enabled=false)
                HorizontalDivider()
                ActionRow("Delete local data","Deletes local boards, tasks, templates, timers and learning history",{deleteConfirm=true})
            }
        }
        item {
            Text("Help",style=MaterialTheme.typography.titleLarge)
            GUSection {
                ActionRow("Help","Food-safety boundary and app behavior",{helpOpen=true})
                HorizontalDivider()
                ActionRow("Privacy policy","Set the published release URL before store submission",{},enabled=false)
                HorizontalDivider()
                ActionRow("Terms","Set the published release URL before store submission",{},enabled=false)
                HorizontalDivider()
                ActionRow("Support","Set the support destination before store submission",{},enabled=false)
            }
        }
        item {
            Text("Subscription",style=MaterialTheme.typography.titleLarge)
            GUSection {
                if(s.entitlementState=="SUBSCRIBER_ACTIVE") {
                    ActionRow("Remove ads","Active subscription • ads are removed",{},enabled=false)
                } else {
                    ActionRow("Remove ads — $1.49/month base price","Google Play subscription • removes ads only",{dispatch("REMOVE_ADS",null)})
                }
            }
        }
        item { GUPrimary("Done",{dispatch("CLOSE_SETTINGS",null)}) }
    }
    if(deleteConfirm) AlertDialog(
        onDismissRequest={deleteConfirm=false},
        title={Text("Delete local data?")},
        text={Text("This deletes app data stored on this device. It does not cancel a Google Play subscription.")},
        confirmButton={TextButton(onClick={dispatch("DELETE_LOCAL_DATA",null);deleteConfirm=false}){Text("Delete")}},
        dismissButton={TextButton(onClick={deleteConfirm=false}){Text("Cancel")}}
    )
    if(helpOpen) AlertDialog(
        onDismissRequest={helpOpen=false},
        title={Text("Kitchen Prep Board")},
        text={Text("This app is an organizational aid only. Timers and task completion do not prove food safety, doneness, safe internal temperature, allergen control, storage safety, or freedom from cross-contamination.")},
        confirmButton={TextButton(onClick={helpOpen=false}){Text("Done")}}
    )
}
