package com.gooduse.kitchenprep.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.gooduse.kitchenprep.*
import com.gooduse.kitchenprep.R

@Composable fun Run(s:UiState,vm:KitchenPrepViewModel){val b=s.board?:return;BoxWithConstraints(Modifier.fillMaxSize()){val expanded=maxWidth>=840.dp;Scaffold(topBar={TopBar(b.title,false,vm::home)},containerColor=MaterialTheme.colorScheme.background){p->if(expanded)LanesWide(b,vm,Modifier.padding(p))else LanesCompact(b,vm,Modifier.padding(p))}}}

@Composable fun LanesCompact(b:Board,vm:KitchenPrepViewModel,m:Modifier){val lanes=listOf("NOW" to b.tasks.filter{it.status==TaskStatus.ACTIVE},"NEXT" to b.tasks.filter{it.status in listOf(TaskStatus.AVAILABLE,TaskStatus.BLOCKED)},"WAITING" to b.tasks.filter{it.status==TaskStatus.WAITING},"DONE" to b.tasks.filter{it.status in listOf(TaskStatus.DONE,TaskStatus.SKIPPED)});var sel by remember{mutableIntStateOf(lanes.indexOfFirst{it.second.isNotEmpty()}.coerceAtLeast(0))};Column(m.fillMaxSize()){ScrollableTabRow(sel,edgePadding=8.dp){lanes.forEachIndexed{n,(name,list)->Tab(sel==n,{sel=n},text={Text("$name  ${list.size}")})}};LazyColumn(Modifier.fillMaxSize().padding(12.dp),verticalArrangement=Arrangement.spacedBy(10.dp)){items(lanes[sel].second,key={it.id}){TaskCard(it,vm)};item{Spacer(Modifier.height(20.dp));Secondary("Pause Board",Icons.Rounded.Pause,vm::pause);Spacer(Modifier.height(8.dp));Secondary("Finish Board",Icons.Rounded.Flag,vm::openFinish);Spacer(Modifier.height(80.dp))}}}}

@Composable fun LanesWide(b:Board,vm:KitchenPrepViewModel,m:Modifier){val lanes=listOf("NOW" to b.tasks.filter{it.status==TaskStatus.ACTIVE},"NEXT" to b.tasks.filter{it.status in listOf(TaskStatus.AVAILABLE,TaskStatus.BLOCKED)},"WAITING" to b.tasks.filter{it.status==TaskStatus.WAITING},"DONE" to b.tasks.filter{it.status in listOf(TaskStatus.DONE,TaskStatus.SKIPPED)});Row(m.fillMaxSize().padding(12.dp),horizontalArrangement=Arrangement.spacedBy(10.dp)){lanes.forEach{(name,list)->Column(Modifier.weight(1f)){Text("$name  ${list.size}",fontWeight=FontWeight.SemiBold);Spacer(Modifier.height(8.dp));LazyColumn(verticalArrangement=Arrangement.spacedBy(8.dp)){items(list,key={it.id}){TaskCard(it,vm)}}}}}}

@Composable fun TaskCard(t:Task,vm:KitchenPrepViewModel){CardBox{Text(t.text,fontWeight=FontWeight.SemiBold);Text("${t.durationMin} min",style=MaterialTheme.typography.bodySmall,color=Kpb.muted);when(t.status){TaskStatus.AVAILABLE,TaskStatus.BLOCKED->Primary("Start",Icons.Rounded.PlayArrow){vm.startTask(t.id)};TaskStatus.ACTIVE,TaskStatus.WAITING->{Row(horizontalArrangement=Arrangement.spacedBy(6.dp)){AssistChip({vm.addMin(t.id,1)},{Text("+1 min")});AssistChip({vm.addMin(t.id,5)},{Text("+5 min")})};Primary("Done",Icons.Rounded.Check){vm.doneTask(t.id)};TextButton({vm.skipTask(t.id)}){Text("Skip")}};else->Row{Icon(Icons.Rounded.Check,null,tint=Kpb.success);Spacer(Modifier.width(6.dp));Text(t.status.name.lowercase().replaceFirstChar(Char::uppercase))}}}}

@Composable fun Paused(s:UiState,vm:KitchenPrepViewModel){Body(s.board?.title?:"Paused Board",false,vm::home){Notice("Paused. Timers are not frozen; resume when ready.");Primary("Resume Board",Icons.Rounded.PlayArrow,onClick=vm::resume);Secondary("Finish Board",Icons.Rounded.Flag,vm::openFinish);Secondary("Go Home",Icons.Rounded.Home,vm::home)}}

@Composable fun Finish(s:UiState,vm:KitchenPrepViewModel){val u=s.board?.tasks?.count{it.status !in listOf(TaskStatus.DONE,TaskStatus.SKIPPED)}?:0;Body("Finish Board",true,vm::back){Icon(if(u==0)Icons.Rounded.CheckCircle else Icons.Rounded.WarningAmber,null,Modifier.size(70.dp).align(Alignment.CenterHorizontally),tint=if(u==0)Kpb.success else Kpb.amber);Text(if(u==0)"You’re all set!" else "$u item(s) are unfinished.",style=MaterialTheme.typography.titleLarge,fontWeight=FontWeight.SemiBold,modifier=Modifier.align(Alignment.CenterHorizontally));if(u>0)Secondary("Continue Board",onClick=vm::back);Primary(if(u>0)"Finish Anyway" else "Finish Board",onClick=vm::finishAnyway)}}

@Composable fun Reuse(s:UiState,vm:KitchenPrepViewModel){Body("Board Complete",false,vm::home){Icon(Icons.Rounded.AssignmentTurnedIn,null,Modifier.size(68.dp).align(Alignment.CenterHorizontally),tint=Kpb.sageDark);Text("What would you like to do?",style=MaterialTheme.typography.titleMedium,modifier=Modifier.align(Alignment.CenterHorizontally));CardBox{Text("Save as Template",fontWeight=FontWeight.SemiBold);Text("Reuse this board next time.",style=MaterialTheme.typography.bodySmall)};CardBox{Text("Add Note",fontWeight=FontWeight.SemiBold);Text("Save notes for next time.",style=MaterialTheme.typography.bodySmall)};Primary("Go to Home",Icons.Rounded.Home,vm::home)}}
