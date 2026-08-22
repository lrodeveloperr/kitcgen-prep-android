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

@Composable fun KitchenPrepApp(vm:KitchenPrepViewModel,shared:String?){
    val s by vm.state.collectAsState();var handled by remember{mutableStateOf(false)}
    LaunchedEffect(shared){if(!handled&&!shared.isNullOrBlank()){vm.ingestShared(shared);handled=true}}
    when(s.screen){
        Screen.LANGUAGE->Language(s,vm);Screen.PRIVACY->Privacy(s,vm);Screen.HOME->Home(s,vm);Screen.CREATE->Create(s,vm);Screen.REVIEW->Review(s,vm);Screen.MODE->Mode(s,vm);Screen.SETUP->Setup(s,vm);Screen.PREP_GAP->GapScreen(s,vm);Screen.TIMING->Timing(s,vm);Screen.READY->Ready(s,vm);Screen.RUN->Run(s,vm);Screen.PAUSED->Paused(s,vm);Screen.FINISH->Finish(s,vm);Screen.REUSE->Reuse(s,vm);Screen.SETTINGS->Settings(s,vm);Screen.SETTINGS_DETAIL->SettingsDetail(s,vm)
    }
}
