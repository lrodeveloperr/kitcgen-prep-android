package studio.gooduse.kitchenprep.data

import androidx.room.withTransaction
import kotlinx.coroutines.flow.*
import studio.gooduse.kitchenprep.timers.TimerScheduler
import java.time.ZoneId
import java.util.UUID
import kotlin.math.max

data class BoardSnapshot(
    val board: BoardEntity? = null,
    val tasks: List<TaskEntity> = emptyList(),
    val timers: List<TimerEntity> = emptyList(),
    val prepGaps: List<PrepGapEntity> = emptyList(),
    val recentBoards: List<BoardEntity> = emptyList(),
)

enum class StartTaskResult {
    STARTED,
    NOT_FOUND,
    ALREADY_RUNNING,
    NOT_STARTABLE,
    DEPENDENCIES_UNRESOLVED,
}

class KitchenRepository(
    private val db: KitchenDatabase,
    private val timerScheduler: TimerScheduler,
) {
    private val dao = db.dao()

    val snapshot: Flow<BoardSnapshot> = combine(
        dao.observeCurrentBoard().flatMapLatest { board ->
            if (board == null) flowOf(BoardSnapshot()) else combine(
                dao.observeTasks(board.id),
                dao.observeTimers(board.id),
                dao.observePrepGaps(board.id),
            ) { tasks, timers, gaps -> BoardSnapshot(board, tasks, timers, gaps) }
        },
        dao.observeRecentBoards(5),
    ) { current, recent -> current.copy(recentBoards = recent) }

    suspend fun beginBoard(sourceType: String, initialText: String? = null): BoardEntity = db.withTransaction {
        archiveOpenDrafts()
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val board = BoardEntity(
            id = id,
            title = "Dinner prep",
            sourceType = sourceType,
            originalText = if (sourceType == "ANDROID_SHARE_TEXT") initialText else null,
            draftText = initialText.orEmpty(),
            referenceUrl = if (sourceType == "REFERENCE_URL") initialText else null,
            targetTimeZoneId = ZoneId.systemDefault().id,
            createdAt = now,
            updatedAt = now,
        )
        dao.upsertBoard(board)
        if (!initialText.isNullOrBlank() && sourceType != "REFERENCE_URL") {
            dao.upsertTasks(DraftTaskParser.parse(id, initialText))
        }
        board
    }

    suspend fun duplicateLatestBoard(): BoardEntity? = db.withTransaction {
        val candidate = dao.latestFinishedBoard() ?: return@withTransaction null
        archiveOpenDrafts()
        val now = System.currentTimeMillis()
        val newId = UUID.randomUUID().toString()
        val copy = candidate.copy(
            id = newId,
            status = "DRAFT",
            sourceType = "DUPLICATE_BOARD",
            sourceBoardId = candidate.id,
            sourceTemplateId = null,
            timingMode = null,
            targetReadyAt = null,
            shiftId = null,
            note = null,
            createdAt = now,
            updatedAt = now,
        )
        dao.upsertBoard(copy)
        val oldTasks = dao.tasks(candidate.id)
        val idMap = oldTasks.associate { it.id to UUID.randomUUID().toString() }
        dao.upsertTasks(oldTasks.map { t ->
            t.copy(
                id = idMap.getValue(t.id),
                boardId = newId,
                status = "AVAILABLE",
                timerId = null,
                previousStatus = null,
                actualStartedAt = null,
                actualEndedAt = null,
                actualDurationSeconds = null,
                waitingDeadlineAt = null,
                suggestedStartAt = null,
                suggestedEndAt = null,
            )
        })
        val deps = dao.dependenciesForBoard(candidate.id).mapNotNull { d ->
            val child = idMap[d.taskId] ?: return@mapNotNull null
            val dep = idMap[d.dependencyTaskId] ?: return@mapNotNull null
            TaskDependencyEntity(child, dep, false)
        }
        dao.upsertDependencies(deps)

        dao.prepGaps(candidate.id).forEach { gap ->
            val copiedTaskId = idMap[gap.taskId] ?: return@forEach
            dao.upsertPrepGap(
                gap.copy(
                    id = "$newId:$copiedTaskId",
                    boardId = newId,
                    taskId = copiedTaskId,
                    onHandResetForShiftId = null,
                )
            )
        }

        val resources = dao.taskResourcesForBoard(candidate.id)
        dao.upsertTaskResources(resources.mapNotNull { res ->
            val copiedTaskId = idMap[res.taskId] ?: return@mapNotNull null
            res.copy(taskId = copiedTaskId)
        })
        copy
    }

    suspend fun duplicateLatestTemplate(): BoardEntity? = db.withTransaction {
        val template = dao.latestTemplate() ?: return@withTransaction null
        archiveOpenDrafts()
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val board = BoardEntity(
            id = id,
            title = template.title,
            mode = template.mode,
            status = "DRAFT",
            sourceType = "DUPLICATE_TEMPLATE",
            sourceTemplateId = template.id,
            draftText = "",
            timingMode = template.defaultTimingMode,
            targetTimeZoneId = ZoneId.systemDefault().id,
            createdAt = now,
            updatedAt = now,
        )
        dao.upsertBoard(board)
        val blueprints = dao.templateTasks(template.id)
        val idsByCanonical = blueprints.associate { it.canonicalActionId to UUID.randomUUID().toString() }
        val tasks = blueprints.map { b ->
            TaskEntity(
                id = idsByCanonical.getValue(b.canonicalActionId),
                boardId = id,
                canonicalActionId = b.canonicalActionId,
                displayText = b.displayText,
                kind = b.kind,
                status = "AVAILABLE",
                estimatedDurationSeconds = b.estimatedDurationSeconds,
                priority = b.priority,
                sortOrder = b.sortOrder,
            )
        }
        dao.upsertTasks(tasks)
        val deps = blueprints.flatMap { b ->
            b.dependencyCanonicalIds.split(',').filter { it.isNotBlank() }.mapNotNull { depCanonical ->
                val child = idsByCanonical[b.canonicalActionId]
                val dep = idsByCanonical[depCanonical]
                if (child != null && dep != null) TaskDependencyEntity(child, dep) else null
            }
        }
        dao.upsertDependencies(deps)
        val taskIdByCanonical = tasks.associate { it.canonicalActionId to it.id }
        val gapTargets = dao.templatePrepGapTargets(template.id).mapNotNull { target ->
            val taskId = taskIdByCanonical[target.canonicalActionId] ?: return@mapNotNull null
            PrepGapEntity(
                id = "$id:$taskId",
                boardId = id,
                taskId = taskId,
                targetValue = target.targetValue,
                targetUnit = target.targetUnit,
                onHandValue = 0.0,
                onHandUnit = target.targetUnit,
                makeValue = target.targetValue.coerceAtLeast(0.0),
                makeUnit = target.targetUnit,
                verified = false,
            )
        }
        gapTargets.forEach { dao.upsertPrepGap(it) }
        dao.upsertBoard(board.copy(draftText = tasks.joinToString("\n") { it.displayText }))
        board
    }

    suspend fun captureReferenceInput(referenceUrl: String, taskText: String) = db.withTransaction {
        val board = dao.currentBoard() ?: return@withTransaction
        dao.deleteDependenciesForBoard(board.id)
        dao.deleteTimersForBoard(board.id)
        dao.deleteTasksForBoard(board.id)
        dao.upsertTasks(DraftTaskParser.parse(board.id, taskText))
        dao.upsertBoard(board.copy(
            sourceType = "REFERENCE_URL",
            referenceUrl = referenceUrl.trim().ifBlank { null },
            draftText = taskText,
            updatedAt = System.currentTimeMillis(),
        ))
    }

    suspend fun captureInput(text: String) = db.withTransaction {
        val board = dao.currentBoard() ?: return@withTransaction
        val original = when {
            board.sourceType == "PASTE_TEXT" && board.originalText == null -> text
            else -> board.originalText
        }
        dao.deleteDependenciesForBoard(board.id)
        dao.deleteTimersForBoard(board.id)
        dao.deleteTasksForBoard(board.id)
        dao.upsertTasks(DraftTaskParser.parse(board.id, text))
        dao.upsertBoard(board.copy(originalText = original, draftText = text, updatedAt = System.currentTimeMillis()))
    }

    suspend fun setMode(mode: String) {
        val b = dao.currentBoard() ?: return
        dao.upsertBoard(b.copy(mode = mode, updatedAt = System.currentTimeMillis()))
    }

    suspend fun setTiming(mode: String, targetReadyAt: Long?) {
        val b = dao.currentBoard() ?: return
        dao.upsertBoard(b.copy(timingMode = mode, targetReadyAt = targetReadyAt, updatedAt = System.currentTimeMillis()))
    }

    suspend fun buildExecutionGraph() = db.withTransaction {
        val board = dao.currentBoard() ?: return@withTransaction
        val tasks = dao.tasks(board.id)
        val deps = dao.dependenciesForBoard(board.id)
        val withAvailability = SchedulingEngine.recomputeAvailability(tasks, deps)
        dao.upsertTasks(withAvailability)
        applySchedule(board, withAvailability, deps)
        dao.updateBoardStatus(board.id, "READY", System.currentTimeMillis())
    }

    suspend fun startBoard() {
        val b = dao.currentBoard() ?: return
        if (b.status == "READY") dao.updateBoardStatus(b.id, "ACTIVE", System.currentTimeMillis())
    }

    suspend fun pauseBoard() {
        val b = dao.currentBoard() ?: return
        if (b.status == "ACTIVE") dao.updateBoardStatus(b.id, "PAUSED", System.currentTimeMillis())
    }

    suspend fun resumeBoard() = db.withTransaction {
        val b = dao.currentBoard() ?: return@withTransaction
        if (b.status == "PAUSED") {
            dao.updateBoardStatus(b.id, "ACTIVE", System.currentTimeMillis())
            recompute(b.id)
        }
    }

    suspend fun finishBoard() = db.withTransaction {
        val b = dao.currentBoard() ?: return@withTransaction
        val unfinished = dao.tasks(b.id).any { it.status != "DONE" && it.status != "SKIPPED" }
        cancelLiveTimersForBoard(b.id)
        dao.updateBoardStatus(b.id, if (unfinished) "ARCHIVED_INCOMPLETE" else "COMPLETED", System.currentTimeMillis())
    }

    suspend fun cancelBoard() = db.withTransaction {
        val b = dao.currentBoard() ?: return@withTransaction
        cancelLiveTimersForBoard(b.id)
        dao.updateBoardStatus(b.id, "ARCHIVED_INCOMPLETE", System.currentTimeMillis())
    }

    suspend fun startTask(taskId: String, allowDependencyOverride: Boolean = false): StartTaskResult = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction StartTaskResult.NOT_FOUND
        if (task.status in setOf("ACTIVE", "WAITING")) return@withTransaction StartTaskResult.ALREADY_RUNNING
        if (task.status !in setOf("AVAILABLE", "BLOCKED")) return@withTransaction StartTaskResult.NOT_STARTABLE
        val deps = dao.dependenciesForTask(taskId)
        val boardTasks = dao.tasks(task.boardId).associateBy { it.id }
        val unresolved = deps.filter { !it.overridden && boardTasks[it.dependencyTaskId]?.status !in setOf("DONE", "SKIPPED") }
        if (unresolved.isNotEmpty() && !allowDependencyOverride) return@withTransaction StartTaskResult.DEPENDENCIES_UNRESOLVED
        if (unresolved.isNotEmpty()) dao.overrideDependencies(taskId, unresolved.map { it.dependencyTaskId })
        val now = System.currentTimeMillis()
        val newStatus = if (task.kind == "WAITING_PERIOD" || task.kind == "HOLD") "WAITING" else "ACTIVE"
        var timerId = task.timerId
        if ((task.estimatedDurationSeconds ?: 0L) > 0L) {
            val timer = TimerEntity(
                id = UUID.randomUUID().toString(),
                boardId = task.boardId,
                taskId = task.id,
                label = task.displayText,
                state = "RUNNING",
                durationSeconds = task.estimatedDurationSeconds!!,
                startedAt = now,
                deadlineAt = now + task.estimatedDurationSeconds * 1000L,
            )
            dao.upsertTimer(timer)
            timerId = timer.id
            timerScheduler.schedule(timer)
        }
        dao.upsertTask(task.copy(
            status = newStatus,
            actualStartedAt = task.actualStartedAt ?: now,
            timerId = timerId,
            waitingDeadlineAt = if (newStatus == "WAITING") now + (task.estimatedDurationSeconds ?: 0L) * 1000L else null,
        ))
        recompute(task.boardId)
        StartTaskResult.STARTED
    }

    suspend fun completeTask(taskId: String) = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction
        if (task.status !in setOf("ACTIVE", "WAITING")) return@withTransaction
        val now = System.currentTimeMillis()
        val duration = task.actualStartedAt?.let { max(0L, (now - it) / 1000L) }
        val timer = dao.timerForTask(task.id)
        if (timer != null && timer.state in setOf("RUNNING", "EXPIRED_ATTENTION_REQUIRED")) {
            dao.upsertTimer(timer.copy(state = "COMPLETED"))
            timerScheduler.cancel(timer.id)
        }
        dao.upsertTask(task.copy(
            previousStatus = task.status,
            status = "DONE",
            actualEndedAt = now,
            actualDurationSeconds = duration,
        ))
        if (duration != null && duration > 0) {
            dao.insertObservation(DurationObservationEntity(
                id = UUID.randomUUID().toString(),
                canonicalActionId = task.canonicalActionId,
                boardId = task.boardId,
                observedDurationSeconds = duration,
                source = "ACTUAL_COMPLETION",
                createdAt = now,
            ))
        }
        recompute(task.boardId)
    }

    suspend fun skipTask(taskId: String) = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction
        if (task.status !in setOf("AVAILABLE", "ACTIVE", "WAITING", "BLOCKED")) return@withTransaction
        val timer = dao.timerForTask(task.id)
        if (timer != null && timer.state == "RUNNING") {
            dao.upsertTimer(timer.copy(state = "CANCELLED"))
            timerScheduler.cancel(timer.id)
        }
        dao.upsertTask(task.copy(previousStatus = task.status, status = "SKIPPED", actualEndedAt = System.currentTimeMillis()))
        recompute(task.boardId)
    }

    suspend fun undoTask(taskId: String) = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction
        if (task.status !in setOf("DONE", "SKIPPED")) return@withTransaction
        dao.upsertTask(task.copy(status = "BLOCKED", actualEndedAt = null, actualDurationSeconds = null, timerId = null))
        recompute(task.boardId)
    }

    suspend fun extendTaskTimer(taskId: String, seconds: Long) = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction
        if (task.status !in setOf("ACTIVE", "WAITING")) return@withTransaction
        val timer = dao.timerForTask(taskId) ?: return@withTransaction
        val now = System.currentTimeMillis()
        val extended = timer.copy(
            state = "RUNNING",
            deadlineAt = max(now, timer.deadlineAt) + seconds * 1000L,
            lastAdjustedAt = now,
            expiredAt = null,
        )
        dao.upsertTimer(extended)
        timerScheduler.schedule(extended)
    }

    suspend fun prioritizeTask(taskId: String) = db.withTransaction {
        val task = dao.task(taskId) ?: return@withTransaction
        val tasks = dao.tasks(task.boardId)
        val minimum = tasks.minOfOrNull { it.sortOrder } ?: 0L
        dao.upsertTask(task.copy(sortOrder = minimum - 1000L))
        recompute(task.boardId)
    }

    suspend fun saveTemplate() = db.withTransaction {
        val board = latestFinishedBoard() ?: return@withTransaction
        val now = System.currentTimeMillis()
        val templateId = UUID.randomUUID().toString()
        val tasks = dao.tasks(board.id)
        val deps = dao.dependenciesForBoard(board.id).groupBy { it.taskId }
        val canonicalById = tasks.associate { it.id to it.canonicalActionId }
        dao.upsertTemplate(TemplateEntity(
            id = templateId,
            title = board.title,
            mode = board.mode ?: "HOME",
            defaultTimingMode = board.timingMode,
            createdAt = now,
            updatedAt = now,
        ))
        dao.upsertTemplateTasks(tasks.map { t ->
            TemplateTaskEntity(
                id = UUID.randomUUID().toString(),
                templateId = templateId,
                canonicalActionId = t.canonicalActionId,
                displayText = t.displayText,
                kind = t.kind,
                estimatedDurationSeconds = t.estimatedDurationSeconds,
                dependencyCanonicalIds = deps[t.id].orEmpty().mapNotNull { canonicalById[it.dependencyTaskId] }.joinToString(","),
                priority = t.priority,
                sortOrder = t.sortOrder,
            )
        })
        val canonicalByTaskId = tasks.associate { it.id to it.canonicalActionId }
        dao.upsertTemplatePrepGapTargets(dao.prepGaps(board.id).mapNotNull { gap ->
            val canonical = canonicalByTaskId[gap.taskId] ?: return@mapNotNull null
            TemplatePrepGapTargetEntity(
                id = UUID.randomUUID().toString(),
                templateId = templateId,
                canonicalActionId = canonical,
                targetValue = gap.targetValue,
                targetUnit = gap.targetUnit,
            )
        })
    }

    suspend fun addNote(note: String) {
        val board = latestFinishedBoard() ?: return
        dao.upsertBoard(board.copy(note = note, updatedAt = System.currentTimeMillis()))
    }

    suspend fun setPrepGap(taskId: String, target: Double, unit: String, onHand: Double, verified: Boolean) = db.withTransaction {
        val b = dao.currentBoard() ?: return@withTransaction
        val make = max(target - onHand, 0.0)
        dao.upsertPrepGap(PrepGapEntity(
            id = "${b.id}:$taskId",
            boardId = b.id,
            taskId = taskId,
            targetValue = target,
            targetUnit = unit,
            onHandValue = onHand,
            onHandUnit = unit,
            makeValue = make,
            makeUnit = unit,
            verified = verified,
        ))
    }

    suspend fun deleteAllLocalData() = db.withTransaction {
        dao.runningTimers().forEach { timerScheduler.cancel(it.id) }
        dao.deleteTimers()
        dao.deleteShifts()
        dao.deleteResources()
        dao.deleteDependencies()
        dao.deleteTaskResources()
        dao.deletePrepGaps()
        dao.deleteTemplatePrepGapTargets()
        dao.deleteTemplateTasks()
        dao.deleteTemplates()
        dao.deleteObservations()
        dao.deleteTasks()
        dao.deleteBoards()
    }

    private suspend fun cancelLiveTimersForBoard(boardId: String) {
        dao.timers(boardId).filter { it.state in setOf("RUNNING", "EXPIRED_ATTENTION_REQUIRED") }.forEach { timer ->
            if (timer.state == "RUNNING") timerScheduler.cancel(timer.id)
            dao.upsertTimer(timer.copy(state = "CANCELLED"))
        }
    }

    private suspend fun recompute(boardId: String) {
        val board = dao.board(boardId) ?: return
        val current = dao.tasks(boardId)
        val deps = dao.dependenciesForBoard(boardId)
        val normalized = SchedulingEngine.recomputeAvailability(current, deps)
        dao.upsertTasks(normalized)
        applySchedule(board, normalized, deps)
    }

    private suspend fun applySchedule(board: BoardEntity, tasks: List<TaskEntity>, deps: List<TaskDependencyEntity>) {
        val scheduled = SchedulingEngine.schedule(
            tasks = tasks,
            dependencies = deps,
            taskResources = dao.taskResourcesForBoard(board.id),
            resources = dao.resources(),
            timingMode = board.timingMode,
            targetReadyAt = board.targetReadyAt,
            now = System.currentTimeMillis(),
        ).associateBy { it.taskId }
        dao.upsertTasks(tasks.map { t -> scheduled[t.id]?.let { t.copy(suggestedStartAt = it.startAt, suggestedEndAt = it.endAt) } ?: t })
    }

    private suspend fun archiveOpenDrafts() {
        val now = System.currentTimeMillis()
        dao.openBoards().forEach { board ->
            cancelLiveTimersForBoard(board.id)
            dao.updateBoardStatus(board.id, "ARCHIVED_INCOMPLETE", now)
        }
    }

    private suspend fun latestFinishedBoard(): BoardEntity? = dao.latestFinishedBoard()
}
