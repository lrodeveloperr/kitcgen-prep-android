package studio.gooduse.kitchenprep.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface KitchenDao {
    @Query("SELECT * FROM boards WHERE status IN ('DRAFT','READY','ACTIVE','PAUSED') ORDER BY updatedAt DESC LIMIT 1")
    fun observeCurrentBoard(): Flow<BoardEntity?>

    @Query("SELECT * FROM boards WHERE status IN ('DRAFT','READY','ACTIVE','PAUSED') ORDER BY updatedAt DESC LIMIT 1")
    suspend fun currentBoard(): BoardEntity?

    @Query("SELECT * FROM boards WHERE id=:id LIMIT 1")
    suspend fun board(id: String): BoardEntity?

    @Query("SELECT * FROM boards WHERE status IN ('DRAFT','READY','ACTIVE','PAUSED')")
    suspend fun openBoards(): List<BoardEntity>

    @Query("SELECT * FROM boards ORDER BY updatedAt DESC LIMIT 1")
    suspend fun latestBoard(): BoardEntity?

    @Query("SELECT * FROM boards WHERE status IN ('COMPLETED','ARCHIVED_INCOMPLETE') ORDER BY updatedAt DESC LIMIT 1")
    suspend fun latestFinishedBoard(): BoardEntity?

    @Query("SELECT * FROM boards ORDER BY updatedAt DESC LIMIT :limit")
    fun observeRecentBoards(limit: Int = 5): Flow<List<BoardEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertBoard(board: BoardEntity)

    @Query("UPDATE boards SET status=:status, updatedAt=:updatedAt WHERE id=:boardId")
    suspend fun updateBoardStatus(boardId: String, status: String, updatedAt: Long)

    @Query("SELECT * FROM tasks WHERE boardId=:boardId ORDER BY sortOrder ASC")
    fun observeTasks(boardId: String): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE boardId=:boardId ORDER BY sortOrder ASC")
    suspend fun tasks(boardId: String): List<TaskEntity>

    @Query("SELECT * FROM tasks WHERE id=:taskId LIMIT 1")
    suspend fun task(taskId: String): TaskEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTasks(tasks: List<TaskEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTask(task: TaskEntity)

    @Query("DELETE FROM tasks WHERE boardId=:boardId")
    suspend fun deleteTasksForBoard(boardId: String)

    @Query("SELECT * FROM task_dependencies WHERE taskId IN (SELECT id FROM tasks WHERE boardId=:boardId)")
    suspend fun dependenciesForBoard(boardId: String): List<TaskDependencyEntity>

    @Query("SELECT * FROM task_dependencies WHERE taskId=:taskId")
    suspend fun dependenciesForTask(taskId: String): List<TaskDependencyEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertDependencies(items: List<TaskDependencyEntity>)

    @Query("DELETE FROM task_dependencies WHERE taskId IN (SELECT id FROM tasks WHERE boardId=:boardId)")
    suspend fun deleteDependenciesForBoard(boardId: String)

    @Query("UPDATE task_dependencies SET overridden=1 WHERE taskId=:taskId AND dependencyTaskId IN (:dependencyIds)")
    suspend fun overrideDependencies(taskId: String, dependencyIds: List<String>)

    @Query("SELECT * FROM task_resources WHERE taskId IN (SELECT id FROM tasks WHERE boardId=:boardId)")
    suspend fun taskResourcesForBoard(boardId: String): List<TaskResourceEntity>

    @Query("SELECT * FROM resources")
    suspend fun resources(): List<ResourceEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertResource(resource: ResourceEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTaskResources(items: List<TaskResourceEntity>)

    @Query("SELECT * FROM timers WHERE boardId=:boardId ORDER BY deadlineAt ASC")
    fun observeTimers(boardId: String): Flow<List<TimerEntity>>

    @Query("SELECT * FROM timers WHERE boardId=:boardId")
    suspend fun timers(boardId: String): List<TimerEntity>

    @Query("SELECT * FROM timers WHERE id=:timerId LIMIT 1")
    suspend fun timer(timerId: String): TimerEntity?

    @Query("SELECT * FROM timers WHERE taskId=:taskId LIMIT 1")
    suspend fun timerForTask(taskId: String): TimerEntity?

    @Query("SELECT * FROM timers WHERE state='RUNNING'")
    suspend fun runningTimers(): List<TimerEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTimer(timer: TimerEntity)

    @Query("DELETE FROM timers WHERE boardId=:boardId")
    suspend fun deleteTimersForBoard(boardId: String)

    @Query("SELECT * FROM prep_gaps WHERE boardId=:boardId ORDER BY taskId")
    fun observePrepGaps(boardId: String): Flow<List<PrepGapEntity>>

    @Query("SELECT * FROM prep_gaps WHERE boardId=:boardId")
    suspend fun prepGaps(boardId: String): List<PrepGapEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertPrepGap(item: PrepGapEntity)

    @Query("DELETE FROM prep_gaps WHERE boardId=:boardId")
    suspend fun deletePrepGapsForBoard(boardId: String)

    @Query("SELECT * FROM templates ORDER BY updatedAt DESC LIMIT 1")
    suspend fun latestTemplate(): TemplateEntity?

    @Query("SELECT * FROM template_tasks WHERE templateId=:templateId ORDER BY sortOrder")
    suspend fun templateTasks(templateId: String): List<TemplateTaskEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTemplate(template: TemplateEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTemplateTasks(tasks: List<TemplateTaskEntity>)

    @Query("SELECT * FROM template_prep_gap_targets WHERE templateId=:templateId")
    suspend fun templatePrepGapTargets(templateId: String): List<TemplatePrepGapTargetEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTemplatePrepGapTargets(items: List<TemplatePrepGapTargetEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertObservation(item: DurationObservationEntity)

    @Query("SELECT * FROM duration_observations WHERE canonicalActionId=:canonicalActionId ORDER BY createdAt DESC LIMIT 5")
    suspend fun latestObservations(canonicalActionId: String): List<DurationObservationEntity>

    @Query("DELETE FROM boards") suspend fun deleteBoards()
    @Query("DELETE FROM tasks") suspend fun deleteTasks()
    @Query("DELETE FROM task_dependencies") suspend fun deleteDependencies()
    @Query("DELETE FROM task_resources") suspend fun deleteTaskResources()
    @Query("DELETE FROM timers") suspend fun deleteTimers()
    @Query("DELETE FROM shifts") suspend fun deleteShifts()
    @Query("DELETE FROM resources") suspend fun deleteResources()
    @Query("DELETE FROM prep_gaps") suspend fun deletePrepGaps()
    @Query("DELETE FROM templates") suspend fun deleteTemplates()
    @Query("DELETE FROM template_tasks") suspend fun deleteTemplateTasks()
    @Query("DELETE FROM template_prep_gap_targets") suspend fun deleteTemplatePrepGapTargets()
    @Query("DELETE FROM duration_observations") suspend fun deleteObservations()
}
