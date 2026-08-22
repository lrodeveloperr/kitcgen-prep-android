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

@Composable fun Settings(s:UiState,vm:KitchenPrepViewModel){Body("Settings",true,vm::closeSettings,bottom={Nav(3,vm)}){Text("Preferences",style=MaterialTheme.typography.labelMedium,color=Kpb.muted);CardBox{SettingLine(Icons.Rounded.Language,"Language",s.language){};HorizontalDivider();SettingLine(Icons.Rounded.Public,"Locale",s.region){};HorizontalDivider();SettingLine(Icons.Rounded.Straighten,"Units","System"){};HorizontalDivider();SettingLine(Icons.Rounded.DeviceThermostat,"Temperature","°F"){}};Text("Appearance",style=MaterialTheme.typography.labelMedium,color=Kpb.muted);CardBox{Row(verticalAlignment=Alignment.CenterVertically){Icon(Icons.Rounded.DarkMode,null);Spacer(Modifier.width(9.dp));Text("Theme",Modifier.weight(1f));TextButton({vm.setTheme(when(s.theme){ThemeMode.SYSTEM->ThemeMode.LIGHT;ThemeMode.LIGHT->ThemeMode.DARK;ThemeMode.DARK->ThemeMode.SYSTEM})}){Text(s.theme.name.lowercase().replaceFirstChar(Char::uppercase))}}};Secondary("Data, Privacy & Support"){vm.settings(true)}}}

@Composable fun SettingLine(icon:androidx.compose.ui.graphics.vector.ImageVector,title:String,value:String,onClick:()->Unit){Row(Modifier.fillMaxWidth().heightIn(min=56.dp).clickable(onClick=onClick),verticalAlignment=Alignment.CenterVertically){Icon(icon,null,tint=Kpb.sageDark);Spacer(Modifier.width(10.dp));Text(title,Modifier.weight(1f));Text(value,style=MaterialTheme.typography.bodySmall,color=Kpb.muted);Icon(Icons.Rounded.ChevronRight,null)}}

@Composable fun SettingsDetail(s:UiState,vm:KitchenPrepViewModel){Body("Settings",true,vm::back){Text("Data & Privacy",style=MaterialTheme.typography.labelMedium,color=Kpb.muted);CardBox{SettingLine(Icons.Rounded.PrivacyTip,"Privacy Choices",""){};HorizontalDivider();SettingLine(Icons.Rounded.IosShare,"Export Local Data",""){};HorizontalDivider();SettingLine(Icons.Rounded.Download,"Import Local Data",""){};HorizontalDivider();SettingLine(Icons.Rounded.DeleteOutline,"Delete Local Data",""){}};Text("Help & Support",style=MaterialTheme.typography.labelMedium,color=Kpb.muted);CardBox{SettingLine(Icons.Rounded.HelpOutline,"Help Center",""){};HorizontalDivider();SettingLine(Icons.Rounded.Policy,"Privacy Policy",""){};HorizontalDivider();SettingLine(Icons.Rounded.Description,"Terms of Service",""){};HorizontalDivider();SettingLine(Icons.Rounded.SupportAgent,"Support",""){}};Primary("Remove Ads",Icons.Rounded.Block){};Text("Organizational aid only. It does not prove food safety or doneness.",style=MaterialTheme.typography.bodySmall,color=Kpb.muted)}}

@Composable fun Nav(sel:Int,vm:KitchenPrepViewModel){NavigationBar{listOf("Home" to Icons.Rounded.Home,"Boards" to Icons.Rounded.ViewKanban,"Templates" to Icons.Rounded.ContentCopy,"Settings" to Icons.Rounded.Settings).forEachIndexed{n,(label,icon)->NavigationBarItem(sel==n,{if(n==3)vm.settings()else vm.home()},{Icon(icon,label)},label={Text(label)})}}}
