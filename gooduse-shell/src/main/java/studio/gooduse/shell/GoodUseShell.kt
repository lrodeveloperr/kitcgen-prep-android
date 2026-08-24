package studio.gooduse.shell

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*

data class GoodUsePalette(
    val canvas: Color, val surface: Color, val raised: Color, val primary: Color,
    val onPrimary: Color, val text: Color, val secondary: Color, val border: Color,
    val success: Color, val warning: Color, val error: Color,
)

private val Light = GoodUsePalette(
    Color(0xFFF5F7F8), Color.White, Color(0xFFEDF3F5), Color(0xFF215B7A),
    Color.White, Color(0xFF13232D), Color(0xFF51636D), Color(0xFFCDD9DE),
    Color(0xFF2E7259), Color(0xFF9A6508), Color(0xFFA74343)
)
private val Dark = GoodUsePalette(
    Color(0xFF0E1519), Color(0xFF162128), Color(0xFF1D2B33), Color(0xFF8FC8E8),
    Color(0xFF08202D), Color(0xFFEDF4F7), Color(0xFFB8C7CE), Color(0xFF40515B),
    Color(0xFF72C19A), Color(0xFFE4B65E), Color(0xFFE08C8C)
)

data class GoodUseRuntime(val palette: GoodUsePalette, val width: Dp, val gutter: Dp, val wideBoard: Boolean)
val LocalGoodUse = staticCompositionLocalOf<GoodUseRuntime> { error("GoodUseFrame missing") }

@Composable
fun GoodUseTheme(content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()
    val p = if (dark) Dark else Light
    val scheme = if (dark) darkColorScheme(
        primary=p.primary, onPrimary=p.onPrimary, background=p.canvas, surface=p.surface,
        surfaceVariant=p.raised, onBackground=p.text, onSurface=p.text, onSurfaceVariant=p.secondary,
        outline=p.border, error=p.error
    ) else lightColorScheme(
        primary=p.primary, onPrimary=p.onPrimary, background=p.canvas, surface=p.surface,
        surfaceVariant=p.raised, onBackground=p.text, onSurface=p.text, onSurfaceVariant=p.secondary,
        outline=p.border, error=p.error
    )
    MaterialTheme(
        colorScheme = scheme,
        typography = Typography(
            headlineLarge = MaterialTheme.typography.headlineLarge.copy(fontSize=30.sp,lineHeight=36.sp,fontWeight=FontWeight.SemiBold),
            titleLarge = MaterialTheme.typography.titleLarge.copy(fontSize=21.sp,lineHeight=27.sp,fontWeight=FontWeight.SemiBold),
            bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontSize=16.sp,lineHeight=23.sp),
            labelLarge = MaterialTheme.typography.labelLarge.copy(fontSize=14.sp,lineHeight=19.sp,fontWeight=FontWeight.Medium),
        ),
        content = content
    )
}

private fun gutterFor(width: Dp): Dp = when {
    width < 360.dp -> 12.dp
    width < 600.dp -> 16.dp
    width < 840.dp -> 24.dp
    width < 1200.dp -> 32.dp
    width < 1600.dp -> 40.dp
    else -> 48.dp
}

@Composable
fun GoodUseFrame(
    modifier: Modifier = Modifier,
    bottomRail: (@Composable () -> Unit)? = null,
    content: @Composable (GoodUseRuntime) -> Unit,
) {
    GoodUseTheme {
        BoxWithConstraints(
            modifier = modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .windowInsetsPadding(WindowInsets.safeDrawing)
                .imePadding()
        ) {
            val gutter = gutterFor(maxWidth)
            val p = if (isSystemInDarkTheme()) Dark else Light
            val rt = GoodUseRuntime(p, maxWidth, gutter, wideBoard = maxWidth >= 840.dp)
            CompositionLocalProvider(LocalGoodUse provides rt) {
                Column(Modifier.fillMaxSize()) {
                    Box(
                        Modifier.weight(1f).fillMaxWidth(),
                        contentAlignment = Alignment.TopCenter
                    ) {
                        Box(
                            Modifier.fillMaxWidth()
                                .widthIn(max = if (maxWidth >= 1600.dp) 1440.dp else maxWidth)
                                .padding(horizontal = gutter)
                        ) { content(rt) }
                    }
                    if (bottomRail != null) bottomRail()
                }
            }
        }
    }
}

@Composable
fun GUHeader(title: String, subtitle: String? = null, trailing: (@Composable () -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().padding(top=16.dp,bottom=16.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = MaterialTheme.typography.titleLarge)
            if (subtitle != null) Text(subtitle, style = MaterialTheme.typography.bodyLarge, color=MaterialTheme.colorScheme.onSurfaceVariant)
        }
        trailing?.invoke()
    }
}

@Composable
fun GUSection(
    title: String? = null,
    modifier: Modifier = Modifier,
    emphasis: Boolean = false,
    content: @Composable ColumnScope.() -> Unit
) {
    val bg = if (emphasis) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.surface
    Column(
        modifier.fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(bg)
            .border(1.dp, MaterialTheme.colorScheme.outline.copy(alpha=.55f), RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (title != null) Text(title, style=MaterialTheme.typography.titleLarge)
        content()
    }
}

@Composable
fun GUPrimary(text: String, onClick:()->Unit, enabled:Boolean=true, iconKey:String?=null, modifier: Modifier=Modifier) {
    Button(
        onClick=onClick, enabled=enabled,
        modifier=modifier.fillMaxWidth().heightIn(min=48.dp),
        shape=RoundedCornerShape(12.dp),
        elevation=null,
    ) {
        if (iconKey != null) {
            GoodUseVectorIcon(iconKey, Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text, style=MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun GUSecondary(text:String, onClick:()->Unit, enabled:Boolean=true, iconKey:String?=null, modifier:Modifier=Modifier) {
    OutlinedButton(
        onClick=onClick, enabled=enabled,
        modifier=modifier.fillMaxWidth().heightIn(min=48.dp),
        shape=RoundedCornerShape(12.dp),
    ) {
        if (iconKey != null) {
            GoodUseVectorIcon(iconKey, Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text, style=MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun GUTextAction(text:String, onClick:()->Unit, modifier:Modifier=Modifier) {
    TextButton(onClick=onClick, modifier=modifier.heightIn(min=48.dp)) { Text(text) }
}

@Composable
fun GUStatus(text:String, tone:String="neutral") {
    val rt = LocalGoodUse.current
    val color = when(tone) { "success"->rt.palette.success; "warning"->rt.palette.warning; "error"->rt.palette.error; else->rt.palette.secondary }
    Surface(color=color.copy(alpha=.13f), contentColor=color, shape=RoundedCornerShape(999.dp)) {
        Text(text, Modifier.padding(horizontal=10.dp,vertical=6.dp), style=MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun GoodUseVectorIcon(key:String, modifier:Modifier=Modifier, tint:Color=LocalContentColor.current) {
    Canvas(modifier) {
        val s = size.minDimension / 24f
        fun x(v:Float)=v*s
        fun line(a:Pair<Float,Float>, b:Pair<Float,Float>, sw:Float=1.8f) =
            drawLine(tint, Offset(x(a.first),x(a.second)), Offset(x(b.first),x(b.second)), x(sw), cap=StrokeCap.Round)
        when(key) {
            "play","resume" -> {
                val p=Path().apply { moveTo(x(8f),x(5f)); lineTo(x(19f),x(12f)); lineTo(x(8f),x(19f)); close() }
                drawPath(p,tint)
            }
            "pause" -> { drawRect(tint,Offset(x(7f),x(5f)),Size(x(3.5f),x(14f))); drawRect(tint,Offset(x(13.5f),x(5f)),Size(x(3.5f),x(14f))) }
            "stop" -> drawRect(tint,Offset(x(6f),x(6f)),Size(x(12f),x(12f)))
            "complete","check","save" -> { line(4f to 12f,9.5f to 17.5f); line(9.5f to 17.5f,20f to 6f) }
            "plus" -> { line(12f to 4f,12f to 20f); line(4f to 12f,20f to 12f) }
            "settings" -> {
                line(3f to 6f,21f to 6f); drawCircle(tint, x(2f), Offset(x(8f),x(6f)), style=Stroke(x(1.8f)))
                line(3f to 12f,21f to 12f); drawCircle(tint, x(2f), Offset(x(16f),x(12f)), style=Stroke(x(1.8f)))
                line(3f to 18f,21f to 18f); drawCircle(tint, x(2f), Offset(x(11f),x(18f)), style=Stroke(x(1.8f)))
            }
            "history" -> {
                drawCircle(tint,x(8f),Offset(x(12f),x(12f)),style=Stroke(x(1.8f)))
                line(12f to 7f,12f to 12f); line(12f to 12f,15.5f to 14f)
            }
            else -> {
                drawCircle(tint,x(9f),Offset(x(12f),x(12f)),style=Stroke(x(1.8f)))
            }
        }
    }
}
