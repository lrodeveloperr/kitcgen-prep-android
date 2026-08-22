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

@Composable
fun Body(
    title: String,
    back: Boolean,
    onBack: () -> Unit,
    bottom: (@Composable () -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Scaffold(
        topBar = { TopBar(title, back, onBack) },
        bottomBar = { if (bottom != null) bottom() },
        containerColor = MaterialTheme.colorScheme.background
    ) { p ->
        Column(
            Modifier.fillMaxSize().padding(p).verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            content = content
        )
    }
}
