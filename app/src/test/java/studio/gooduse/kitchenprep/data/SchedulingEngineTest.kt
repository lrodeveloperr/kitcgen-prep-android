package studio.gooduse.kitchenprep.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SchedulingEngineTest {
    @Test
    fun serializesMoreThanLegacy512ContendedTasks() {
        val now = 1_000_000L
        val tasks = (0 until 600).map { index ->
            TaskEntity(
                id = "task-$index",
                boardId = "board",
                canonicalActionId = "task_$index",
                displayText = "Task $index",
                kind = "PREP",
                status = "AVAILABLE",
                estimatedDurationSeconds = 1L,
                sortOrder = index * 1000L,
            )
        }
        val requirements = tasks.map { TaskResourceEntity(it.id, "oven", 1) }

        val scheduled = SchedulingEngine.schedule(
            tasks = tasks,
            dependencies = emptyList(),
            taskResources = requirements,
            resources = listOf(ResourceEntity("oven", "Oven", capacity = 1)),
            timingMode = "COOK_NOW",
            targetReadyAt = null,
            now = now,
        )

        assertEquals(tasks.size, scheduled.size)
        scheduled.zipWithNext().forEach { (first, second) ->
            assertTrue("Capacity-1 resource allocations must not overlap", second.startAt >= first.endAt)
        }
    }

    @Test
    fun recomputeBlocksTaskUntilDependencyIsTerminal() {
        val parent = TaskEntity(
            id = "parent", boardId = "board", canonicalActionId = "parent", displayText = "Parent",
            kind = "PREP", status = "AVAILABLE", sortOrder = 0L,
        )
        val child = TaskEntity(
            id = "child", boardId = "board", canonicalActionId = "child", displayText = "Child",
            kind = "PREP", status = "AVAILABLE", sortOrder = 1000L,
        )
        val dependency = TaskDependencyEntity(taskId = child.id, dependencyTaskId = parent.id)

        val blocked = SchedulingEngine.recomputeAvailability(listOf(parent, child), listOf(dependency))
        assertEquals("BLOCKED", blocked.first { it.id == child.id }.status)

        val available = SchedulingEngine.recomputeAvailability(
            listOf(parent.copy(status = "DONE"), child.copy(status = "BLOCKED")),
            listOf(dependency),
        )
        assertEquals("AVAILABLE", available.first { it.id == child.id }.status)
    }
}
