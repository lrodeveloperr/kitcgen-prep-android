package studio.gooduse.kitchenprep.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "boards", indices = [Index("status"), Index("updatedAt")])
data class BoardEntity(
    @PrimaryKey val id: String,
    val title: String,
    val mode: String? = null,
    val status: String = "DRAFT",
    val sourceType: String = "MANUAL",
    val originalText: String? = null,
    val draftText: String = "",
    val referenceUrl: String? = null,
    val sourceBoardId: String? = null,
    val sourceTemplateId: String? = null,
    val timingMode: String? = null,
    val targetReadyAt: Long? = null,
    val targetTimeZoneId: String,
    val shiftId: String? = null,
    val note: String? = null,
    val createdAt: Long,
    val updatedAt: Long,
)

@Entity(tableName = "tasks", indices = [Index("boardId"), Index("status"), Index("sortOrder")])
data class TaskEntity(
    @PrimaryKey val id: String,
    val boardId: String,
    val canonicalActionId: String,
    val displayText: String,
    val kind: String,
    val status: String,
    val estimatedDurationSeconds: Long? = null,
    val priority: String = "NONE",
    val timerId: String? = null,
    val sortOrder: Long,
    val previousStatus: String? = null,
    val actualStartedAt: Long? = null,
    val actualEndedAt: Long? = null,
    val actualDurationSeconds: Long? = null,
    val waitingDeadlineAt: Long? = null,
    val suggestedStartAt: Long? = null,
    val suggestedEndAt: Long? = null,
)

@Entity(tableName = "task_dependencies", primaryKeys = ["taskId", "dependencyTaskId"], indices = [Index("dependencyTaskId")])
data class TaskDependencyEntity(
    val taskId: String,
    val dependencyTaskId: String,
    val overridden: Boolean = false,
)

@Entity(tableName = "resources")
data class ResourceEntity(
    @PrimaryKey val id: String,
    val name: String,
    val capacity: Int = 1,
    val availability: String = "AVAILABLE",
)

@Entity(tableName = "task_resources", primaryKeys = ["taskId", "resourceId"], indices = [Index("resourceId")])
data class TaskResourceEntity(
    val taskId: String,
    val resourceId: String,
    val capacityUnits: Int = 1,
)

@Entity(tableName = "timers", indices = [Index("boardId"), Index(value = ["taskId"], unique = true), Index("state")])
data class TimerEntity(
    @PrimaryKey val id: String,
    val boardId: String,
    val taskId: String,
    val label: String,
    val state: String,
    val durationSeconds: Long,
    val startedAt: Long,
    val deadlineAt: Long,
    val lastAdjustedAt: Long? = null,
    val expiredAt: Long? = null,
)

@Entity(tableName = "prep_gaps", indices = [Index("boardId")])
data class PrepGapEntity(
    @PrimaryKey val id: String,
    val boardId: String,
    val taskId: String,
    val targetValue: Double,
    val targetUnit: String,
    val onHandValue: Double,
    val onHandUnit: String,
    val makeValue: Double,
    val makeUnit: String,
    val verified: Boolean,
    val onHandResetForShiftId: String? = null,
)

@Entity(tableName = "shifts", indices = [Index("isActive")])
data class ShiftEntity(
    @PrimaryKey val id: String,
    val startAt: Long,
    val endAt: Long? = null,
    val isActive: Boolean = true,
)

@Entity(tableName = "templates", indices = [Index("updatedAt")])
data class TemplateEntity(
    @PrimaryKey val id: String,
    val title: String,
    val mode: String,
    val defaultTimingMode: String? = null,
    val createdAt: Long,
    val updatedAt: Long,
)

@Entity(tableName = "template_tasks", indices = [Index("templateId"), Index("sortOrder")])
data class TemplateTaskEntity(
    @PrimaryKey val id: String,
    val templateId: String,
    val canonicalActionId: String,
    val displayText: String,
    val kind: String,
    val estimatedDurationSeconds: Long? = null,
    val dependencyCanonicalIds: String = "",
    val resourceRequirements: String = "",
    val priority: String = "NONE",
    val sortOrder: Long,
)

@Entity(tableName = "template_prep_gap_targets", indices = [Index("templateId")])
data class TemplatePrepGapTargetEntity(
    @PrimaryKey val id: String,
    val templateId: String,
    val canonicalActionId: String,
    val targetValue: Double,
    val targetUnit: String,
)

@Entity(tableName = "duration_observations", indices = [Index("canonicalActionId"), Index("createdAt")])
data class DurationObservationEntity(
    @PrimaryKey val id: String,
    val canonicalActionId: String,
    val boardId: String,
    val templateId: String? = null,
    val observedDurationSeconds: Long,
    val source: String,
    val createdAt: Long,
)
