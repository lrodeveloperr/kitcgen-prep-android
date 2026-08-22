package com.gooduse.kitchenprep

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import androidx.lifecycle.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID

private val Context.prefs by preferencesDataStore("kitchen_prep")

enum class Screen { LANGUAGE, PRIVACY, HOME, CREATE, REVIEW, MODE, SETUP, PREP_GAP, TIMING, READY, RUN, PAUSED, FINISH, REUSE, SETTINGS, SETTINGS_DETAIL }
enum class BoardMode { HOME, STATION }
enum class BoardStatus { DRAFT, READY, ACTIVE, PAUSED, COMPLETED, ARCHIVED_INCOMPLETE }
enum class TaskStatus { BLOCKED, AVAILABLE, ACTIVE, WAITING, DONE, SKIPPED }
enum class TimingMode { COOK_NOW, SERVE_AT, READY_BY }
enum class ThemeMode { SYSTEM, LIGHT, DARK }
enum class GapType { INGREDIENT, TOOL }

data class Task(
    val id:String=UUID.randomUUID().toString(),
    val text:String,
    val status:TaskStatus=TaskStatus.AVAILABLE,
    val durationMin:Int=5,
    val deadline:Long?=null
)
data class Gap(val id:String=UUID.randomUUID().toString(),val name:String,val type:GapType)
data class Board(
    val id:String=UUID.randomUUID().toString(),
    val title:String,
    val note:String="",
    val mode:BoardMode?=null,
    val status:BoardStatus=BoardStatus.DRAFT,
    val timing:TimingMode?=null,
    val tasks:List<Task> = emptyList(),
    val gaps:List<Gap> = emptyList()
)
data class UiState(
    val screen:Screen=Screen.LANGUAGE,
    val language:String="English",
    val region:String="United States (US)",
    val theme:ThemeMode=ThemeMode.SYSTEM,
    val adsEnabled:Boolean=true,
    val board:Board?=null,
    val draftName:String="",
    val draftNote:String="",
    val draftText:String="",
    val mode:BoardMode=BoardMode.HOME,
    val timing:TimingMode=TimingMode.COOK_NOW,
    val servings:Int=4,
    val serviceType:String="Dinner",
    val settingsReturn:Screen=Screen.HOME
)

class KitchenPrepViewModel(private val context:Context):ViewModel(){
    private val _s=MutableStateFlow(UiState())
    val state=_s.asStateFlow()
    private object K{val onboarded=booleanPreferencesKey("onboarded");val lang=stringPreferencesKey("lang");val region=stringPreferencesKey("region");val theme=stringPreferencesKey("theme")}
    init{viewModelScope.launch{
        val p=context.prefs.data.first()
        _s.update{it.copy(
            screen=if(p[K.onboarded]==true) Screen.HOME else Screen.LANGUAGE,
            language=p[K.lang]?:"English",region=p[K.region]?:"United States (US)",
            theme=runCatching{ThemeMode.valueOf(p[K.theme]?:"SYSTEM")}.getOrDefault(ThemeMode.SYSTEM)
        )}
    }}
    fun setLanguage(v:String)=_s.update{it.copy(language=v)}
    fun setRegion(v:String)=_s.update{it.copy(region=v)}
    fun localeNext(){_s.update{it.copy(screen=Screen.PRIVACY)}}
    fun setAds(v:Boolean)=_s.update{it.copy(adsEnabled=v)}
    fun privacyNext(){val x=_s.value;viewModelScope.launch{context.prefs.edit{it[K.onboarded]=true;it[K.lang]=x.language;it[K.region]=x.region}};_s.update{it.copy(screen=Screen.HOME)}}
    fun create(prefill:String="")=_s.update{it.copy(screen=Screen.CREATE,draftText=prefill)}
    fun setDraftName(v:String)=_s.update{it.copy(draftName=v.take(80))}
    fun setDraftNote(v:String)=_s.update{it.copy(draftNote=v.take(400))}
    fun setDraftText(v:String)=_s.update{it.copy(draftText=v)}
    fun capture(){
        val x=_s.value
        val tasks=x.draftText.lineSequence().map { it.trim() }.filter { it.isNotEmpty() }.map{Task(text=it)}.toList()
        _s.update{it.copy(board=Board(title=x.draftName.trim().ifBlank{"Prep Board"},note=x.draftNote,tasks=tasks),screen=Screen.REVIEW)}
    }
    fun addTask(v:String){if(v.isBlank())return;_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(tasks=b.tasks+Task(text=v.trim())))}}
    fun reviewNext()=go(Screen.MODE)
    fun selectMode(v:BoardMode)=_s.update{it.copy(mode=v)}
    fun modeNext(){_s.update{u->u.copy(board=(u.board?:Board(title="Prep Board")).copy(mode=u.mode),screen=Screen.SETUP)}}
    fun setServings(v:Int)=_s.update{it.copy(servings=v.coerceIn(1,1000))}
    fun setServiceType(v:String)=_s.update{it.copy(serviceType=v.take(60))}
    fun setupNext()=go(if(_s.value.mode==BoardMode.STATION)Screen.PREP_GAP else Screen.TIMING)
    fun addGap(v:String,type:GapType){if(v.isBlank())return;_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(gaps=b.gaps+Gap(name=v.trim(),type=type)))}}
    fun gapNext()=go(Screen.TIMING)
    fun selectTiming(v:TimingMode)=_s.update{it.copy(timing=v)}
    fun timingNext(){_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(timing=u.timing,status=BoardStatus.READY),screen=Screen.READY)}}
    fun startBoard(){_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(status=BoardStatus.ACTIVE),screen=Screen.RUN)}}
    fun startTask(id:String)=mutate(id){it.copy(status=TaskStatus.ACTIVE,deadline=System.currentTimeMillis()+it.durationMin*60000L)}
    fun doneTask(id:String)=mutate(id){it.copy(status=TaskStatus.DONE,deadline=null)}
    fun skipTask(id:String)=mutate(id){it.copy(status=TaskStatus.SKIPPED,deadline=null)}
    fun addMin(id:String,m:Int)=mutate(id){it.copy(deadline=(it.deadline?:System.currentTimeMillis())+m*60000L)}
    private fun mutate(id:String,f:(Task)->Task){_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(tasks=b.tasks.map{if(it.id==id)f(it)else it}))}}
    fun pause(){_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(status=BoardStatus.PAUSED),screen=Screen.PAUSED)}}
    fun resume(){_s.update{u->val b=u.board?:return@update u;u.copy(board=b.copy(status=BoardStatus.ACTIVE),screen=Screen.RUN)}}
    fun openFinish()=go(Screen.FINISH)
    fun finishAnyway(){_s.update{u->val b=u.board?:return@update u;val incomplete=b.tasks.any{it.status !in listOf(TaskStatus.DONE,TaskStatus.SKIPPED)};u.copy(board=b.copy(status=if(incomplete)BoardStatus.ARCHIVED_INCOMPLETE else BoardStatus.COMPLETED),screen=Screen.REUSE)}}
    fun home()=go(Screen.HOME)
    fun settings(detail:Boolean=false){_s.update{it.copy(settingsReturn=it.screen,screen=if(detail)Screen.SETTINGS_DETAIL else Screen.SETTINGS)}}
    fun closeSettings()=_s.update{it.copy(screen=it.settingsReturn)}
    fun setTheme(v:ThemeMode){_s.update{it.copy(theme=v)};viewModelScope.launch{context.prefs.edit{it[K.theme]=v.name}}}
    fun back(){go(when(_s.value.screen){
        Screen.PRIVACY->Screen.LANGUAGE; Screen.CREATE->Screen.HOME; Screen.REVIEW->Screen.CREATE; Screen.MODE->Screen.REVIEW; Screen.SETUP->Screen.MODE
        Screen.PREP_GAP->Screen.SETUP; Screen.TIMING->if(_s.value.mode==BoardMode.STATION)Screen.PREP_GAP else Screen.SETUP; Screen.READY->Screen.TIMING
        Screen.SETTINGS_DETAIL->Screen.SETTINGS; Screen.SETTINGS->_s.value.settingsReturn; Screen.FINISH->if(_s.value.board?.status==BoardStatus.PAUSED)Screen.PAUSED else Screen.RUN
        else->Screen.HOME
    })}
    fun ingestShared(v:String){if(v.isNotBlank())create(v)}
    private fun go(v:Screen)=_s.update{it.copy(screen=v)}
    companion object{fun factory(c:Context)=object:ViewModelProvider.Factory{@Suppress("UNCHECKED_CAST")override fun<T:ViewModel>create(mc:Class<T>):T=KitchenPrepViewModel(c.applicationContext)as T}}
}
