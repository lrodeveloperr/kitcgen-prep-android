package com.gooduse.kitchenprep.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.gooduse.kitchenprep.ThemeMode

object Kpb {
    val cream = Color(0xFFFAF5EF)
    val surface = Color(0xFFFFFDFC)
    val sage = Color(0xFF4F6F58)
    val sageDark = Color(0xFF36513E)
    val sageSoft = Color(0xFFE4EBE3)
    val ink = Color(0xFF243428)
    val muted = Color(0xFF6F756E)
    val line = Color(0xFFDDD4C9)
    val amber = Color(0xFFB76A24)
    val amberSoft = Color(0xFFFFF0DE)
    val red = Color(0xFFBA4D42)
    val redSoft = Color(0xFFFFECE8)
    val success = Color(0xFF3D7452)
}

private val light = lightColorScheme(
    primary = Kpb.sage, onPrimary = Color.White,
    primaryContainer = Kpb.sageSoft, onPrimaryContainer = Kpb.ink,
    background = Kpb.cream, onBackground = Kpb.ink,
    surface = Kpb.surface, onSurface = Kpb.ink,
    outline = Kpb.line, error = Kpb.red
)
private val dark = darkColorScheme(
    primary = Color(0xFFA8C4AE), onPrimary = Color(0xFF18301F),
    background = Color(0xFF111511), onBackground = Color(0xFFF2EEE8),
    surface = Color(0xFF191E1A), onSurface = Color(0xFFF2EEE8),
    outline = Color(0xFF465149), error = Color(0xFFFFB4AA)
)

@Composable
fun KitchenPrepTheme(mode: ThemeMode, content: @Composable () -> Unit) {
    val useDark = when (mode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }
    MaterialTheme(colorScheme = if (useDark) dark else light, content = content)
}

@Composable
fun TopBar(title: String, back: Boolean, onBack: () -> Unit) {
    Surface(color = MaterialTheme.colorScheme.background) {
        Row(
            Modifier.fillMaxWidth().height(56.dp).padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (back) {
                IconButton(onClick = onBack, modifier = Modifier.size(48.dp)) {
                    Icon(Icons.Rounded.ArrowBack, "Back")
                }
            } else Spacer(Modifier.width(48.dp))
            Text(
                title, Modifier.weight(1f),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1, overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.width(48.dp))
        }
    }
}

@Composable
fun CardBox(content: @Composable ColumnScope.() -> Unit) {
    Surface(
        Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = .8f)),
        shadowElevation = 2.dp
    ) {
        Column(
            Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(9.dp),
            content = content
        )
    }
}

@Composable
fun Primary(
    text: String,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().heightIn(min = 50.dp),
        enabled = enabled,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Kpb.sage)
    ) {
        if (icon != null) {
            Icon(icon, null)
            Spacer(Modifier.width(8.dp))
        }
        Text(text, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun Secondary(text: String, icon: ImageVector? = null, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        if (icon != null) {
            Icon(icon, null)
            Spacer(Modifier.width(8.dp))
        }
        Text(text)
    }
}

@Composable
fun Choice(
    title: String,
    subtitle: String,
    icon: ImageVector,
    selected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        border = BorderStroke(
            if (selected) 2.dp else 1.dp,
            if (selected) Kpb.sage else MaterialTheme.colorScheme.outline
        ),
        color = if (selected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = .45f)
        else MaterialTheme.colorScheme.surface,
        shadowElevation = if (selected) 2.dp else 1.dp
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(12.dp), color = Kpb.sageSoft) {
                Icon(icon, null, Modifier.padding(10.dp).size(26.dp), tint = Kpb.sageDark)
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = Kpb.muted)
            }
            if (selected) Icon(Icons.Rounded.CheckCircle, "Selected", tint = Kpb.sage)
        }
    }
}

@Composable
fun Notice(text: String, error: Boolean = false) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = if (error) Kpb.redSoft else Kpb.amberSoft,
        border = BorderStroke(
            1.dp,
            (if (error) Kpb.red else Kpb.amber).copy(alpha = .35f)
        )
    ) {
        Row(
            Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                if (error) Icons.Rounded.ErrorOutline else Icons.Rounded.Info,
                null,
                tint = if (error) Kpb.red else Kpb.amber
            )
            Spacer(Modifier.width(9.dp))
            Text(text, style = MaterialTheme.typography.bodySmall)
        }
    }
}
