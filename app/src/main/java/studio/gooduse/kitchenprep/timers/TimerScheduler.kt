package studio.gooduse.kitchenprep.timers

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import studio.gooduse.kitchenprep.R
import studio.gooduse.kitchenprep.data.KitchenDatabase
import studio.gooduse.kitchenprep.data.TimerEntity
import kotlinx.coroutines.*

class TimerScheduler(private val context: Context) {
    private val alarms = context.getSystemService(AlarmManager::class.java)

    fun schedule(timer: TimerEntity) {
        val intent = PendingIntent.getBroadcast(
            context,
            timer.id.hashCode(),
            Intent(context, TimerAlarmReceiver::class.java).putExtra(EXTRA_TIMER_ID, timer.id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        when {
            Build.VERSION.SDK_INT >= 31 && alarms.canScheduleExactAlarms() -> alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timer.deadlineAt, intent)
            Build.VERSION.SDK_INT >= 23 -> alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timer.deadlineAt, intent)
            else -> alarms.set(AlarmManager.RTC_WAKEUP, timer.deadlineAt, intent)
        }
    }

    fun cancel(timerId: String) {
        val intent = PendingIntent.getBroadcast(
            context,
            timerId.hashCode(),
            Intent(context, TimerAlarmReceiver::class.java).putExtra(EXTRA_TIMER_ID, timerId),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        alarms.cancel(intent)
        intent.cancel()
    }

    companion object { const val EXTRA_TIMER_ID = "timer_id" }
}

class TimerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val timerId = intent.getStringExtra(TimerScheduler.EXTRA_TIMER_ID) ?: return
        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val dao = KitchenDatabase.get(context).dao()
                val timer = dao.timer(timerId) ?: return@launch
                if (timer.state != "RUNNING") return@launch
                val now = System.currentTimeMillis()
                if (timer.deadlineAt <= now) {
                    dao.upsertTimer(timer.copy(state = "EXPIRED_ATTENTION_REQUIRED", expiredAt = now))
                    showTimerNotification(context, timer)
                } else {
                    TimerScheduler(context).schedule(timer)
                }
            } finally { pending.finish() }
        }
    }
}

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        reconcile(context, goAsync())
    }
}

class ClockChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_TIME_CHANGED && intent.action != Intent.ACTION_TIMEZONE_CHANGED) return
        reconcile(context, goAsync())
    }
}

private fun reconcile(context: Context, pending: BroadcastReceiver.PendingResult) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val dao = KitchenDatabase.get(context).dao()
            val scheduler = TimerScheduler(context)
            val now = System.currentTimeMillis()
            dao.runningTimers().forEach { timer ->
                if (timer.deadlineAt <= now) {
                    dao.upsertTimer(timer.copy(state = "EXPIRED_ATTENTION_REQUIRED", expiredAt = now))
                } else scheduler.schedule(timer)
            }
        } finally { pending.finish() }
    }
}

private fun showTimerNotification(context: Context, timer: TimerEntity) {
    if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
    val manager = context.getSystemService(NotificationManager::class.java)
    val channelId = "kitchen_timers"
    if (Build.VERSION.SDK_INT >= 26) {
        manager.createNotificationChannel(NotificationChannel(channelId, "Kitchen timers", NotificationManager.IMPORTANCE_HIGH))
    }
    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    val contentIntent = launchIntent?.let {
        PendingIntent.getActivity(context, 1, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    val notification = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId) else Notification.Builder(context)
    notification
        .setSmallIcon(R.drawable.ic_timer_notification)
        .setContentTitle("Attention required")
        .setContentText(timer.label)
        .setAutoCancel(true)
        .setContentIntent(contentIntent)
    manager.notify(timer.id.hashCode(), notification.build())
}
