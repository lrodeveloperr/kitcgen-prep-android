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

@Composable fun Mode(s:UiState,vm:KitchenPrepViewModel){Body("Select Mode",true,vm::back){Text("Choose how you want to work.");Choice("Home Mode","Guide for a household cook and family.",Icons.Rounded.Home,s.mode==BoardMode.HOME){vm.selectMode(BoardMode.HOME)};Choice("Station Mode","Step-by-step per station or task area.",Icons.Rounded.Countertops,s.mode==BoardMode.STATION){vm.selectMode(BoardMode.STATION)};Notice("You can change modes anytime in Settings.");Primary("Continue",onClick=vm::modeNext)}}

@Composable fun Setup(s:UiState,vm:KitchenPrepViewModel){Body(if(s.mode==BoardMode.HOME)"Home Mode Setup" else "Station Mode Setup",true,vm::back){Text("Tell us about your plan.");OutlinedTextField("${s.servings}",{vm.setServings(it.filter(Char::isDigit).toIntOrNull()?:1)},label={Text("Servings")},modifier=Modifier.fillMaxWidth());OutlinedTextField(s.serviceType,vm::setServiceType,label={Text(if(s.mode==BoardMode.HOME)"Service Type" else "Station")},modifier=Modifier.fillMaxWidth());CardBox{Text("Date",style=MaterialTheme.typography.labelSmall);Text("Today");HorizontalDivider();Text("Target finish",style=MaterialTheme.typography.labelSmall);Text("Set on the next step")};Primary("Continue",onClick=vm::setupNext)}}

@Composable fun GapScreen(s:UiState,vm:KitchenPrepViewModel){var i by remember{mutableStateOf("")};var tool by remember{mutableStateOf("")};val g=s.board?.gaps.orEmpty();Body("Prep Gap",true,vm::back){Notice("Items to get ready before you cook.");Text("Missing Ingredients",fontWeight=FontWeight.SemiBold);g.filter{it.type==GapType.INGREDIENT}.forEach{CardBox{Row(verticalAlignment=Alignment.CenterVertically){Icon(Icons.Rounded.Inventory2,null);Spacer(Modifier.width(9.dp));Text(it.name)}}};Row(verticalAlignment=Alignment.CenterVertically){OutlinedTextField(i,{i=it},label={Text("Ingredient")},modifier=Modifier.weight(1f));IconButton({vm.addGap(i,GapType.INGREDIENT);i=""}){Icon(Icons.Rounded.Add,null)}};Text("Missing Tools",fontWeight=FontWeight.SemiBold);g.filter{it.type==GapType.TOOL}.forEach{CardBox{Row(verticalAlignment=Alignment.CenterVertically){Icon(Icons.Rounded.Kitchen,null);Spacer(Modifier.width(9.dp));Text(it.name)}}};Row(verticalAlignment=Alignment.CenterVertically){OutlinedTextField(tool,{tool=it},label={Text("Kitchen tool")},modifier=Modifier.weight(1f));IconButton({vm.addGap(tool,GapType.TOOL);tool=""}){Icon(Icons.Rounded.Add,null)}};Primary("All Set, Continue",onClick=vm::gapNext)}}

@Composable fun Timing(s:UiState,vm:KitchenPrepViewModel){Body("Timing Objective",true,vm::back){Text("When do you want everything ready?");Choice("Cook Now","Start as soon as I’m ready.",Icons.Rounded.LocalFireDepartment,s.timing==TimingMode.COOK_NOW){vm.selectTiming(TimingMode.COOK_NOW)};Choice("Serve At","Plan to serve at a set time.",Icons.Rounded.Restaurant,s.timing==TimingMode.SERVE_AT){vm.selectTiming(TimingMode.SERVE_AT)};Choice("Ready By","Everything ready by a deadline.",Icons.Rounded.EventAvailable,s.timing==TimingMode.READY_BY){vm.selectTiming(TimingMode.READY_BY)};Notice("You can adjust times later while working.");Primary("Continue",onClick=vm::timingNext)}}

@Composable fun Ready(s:UiState,vm:KitchenPrepViewModel){val t=s.board?.tasks.orEmpty();Body("Ready Overview",true,vm::back){CardBox{Row(verticalAlignment=Alignment.CenterVertically){Column(Modifier.weight(1f)){Text("Everything will finish together.",fontWeight=FontWeight.SemiBold);Text("Suggested schedule — not a guarantee.",style=MaterialTheme.typography.bodySmall)};Icon(Icons.Rounded.CheckCircle,null,tint=Kpb.success)}};Text("Estimated Finish Time",fontWeight=FontWeight.SemiBold);t.forEachIndexed{n,it->Row(Modifier.fillMaxWidth().padding(vertical=5.dp)){Icon(Icons.Rounded.RestaurantMenu,null,tint=Kpb.sageDark);Spacer(Modifier.width(9.dp));Text(it.text,Modifier.weight(1f));Text("+${(n+1)*it.durationMin}m",style=MaterialTheme.typography.bodySmall)}};Primary("Start Board",Icons.Rounded.PlayArrow,onClick=vm::startBoard)}}
