package studio.gooduse.kitchenprep.data

import kotlin.math.max

class DependencyCycleException : IllegalStateException("Dependency cycle prevents automatic scheduling")

data class ScheduledTask(val taskId: String, val startAt: Long, val endAt: Long)

object SchedulingEngine {
    private data class Allocation(val start: Long, val end: Long, val units: Int)

    fun schedule(
        tasks: List<TaskEntity>,
        dependencies: List<TaskDependencyEntity>,
        taskResources: List<TaskResourceEntity>,
        resources: List<ResourceEntity>,
        timingMode: String?,
        targetReadyAt: Long?,
        now: Long,
    ): List<ScheduledTask> {
        if (tasks.isEmpty()) return emptyList()
        val taskById = tasks.associateBy { it.id }
        val deps = dependencies.filter { !it.overridden && it.taskId in taskById && it.dependencyTaskId in taskById }
        val order = topologicalOrder(tasks, deps)
        val criticalSeconds = criticalPathSeconds(order, deps, taskById)
        val desiredBase = if (timingMode == "SERVE_AT" || timingMode == "READY_BY") {
            (targetReadyAt ?: now) - criticalSeconds * 1000L
        } else now
        val base = max(now, desiredBase)

        val capacities = resources.associate { it.id to if (it.availability == "AVAILABLE") it.capacity else 0 }
        val reqByTask = taskResources.groupBy { it.taskId }
        val allocations = mutableMapOf<String, MutableList<Allocation>>()
        val result = linkedMapOf<String, ScheduledTask>()
        val depsByTask = deps.groupBy { it.taskId }

        for (task in order) {
            val depEnd = depsByTask[task.id].orEmpty().maxOfOrNull { d -> result[d.dependencyTaskId]?.endAt ?: base } ?: base
            val durationMs = max(0L, task.estimatedDurationSeconds ?: 0L) * 1000L
            var start = max(base, depEnd)
            start = findResourceSlot(start, durationMs, reqByTask[task.id].orEmpty(), capacities, allocations)
            val end = start + durationMs
            result[task.id] = ScheduledTask(task.id, start, end)
            reqByTask[task.id].orEmpty().forEach { r ->
                allocations.getOrPut(r.resourceId) { mutableListOf() }.add(Allocation(start, end, r.capacityUnits))
            }
        }

        if ((timingMode == "SERVE_AT" || timingMode == "READY_BY") && targetReadyAt != null) {
            val latestEnd = result.values.maxOfOrNull { it.endAt } ?: targetReadyAt
            val requestedShift = max(0L, latestEnd - targetReadyAt)
            val earliestStart = result.values.minOfOrNull { it.startAt } ?: now
            val safeShift = minOf(requestedShift, max(0L, earliestStart - now))
            if (safeShift > 0) return result.values.map { it.copy(startAt = it.startAt - safeShift, endAt = it.endAt - safeShift) }
        }
        return result.values.toList()
    }

    fun recomputeAvailability(tasks: List<TaskEntity>, dependencies: List<TaskDependencyEntity>): List<TaskEntity> {
        val terminal = tasks.associate { it.id to (it.status == "DONE" || it.status == "SKIPPED") }
        val depsByTask = dependencies.groupBy { it.taskId }
        return tasks.map { task ->
            if (task.status in setOf("ACTIVE", "WAITING", "DONE", "SKIPPED")) task else {
                val unresolved = depsByTask[task.id].orEmpty().any { d -> !d.overridden && terminal[d.dependencyTaskId] != true }
                task.copy(status = if (unresolved) "BLOCKED" else "AVAILABLE")
            }
        }
    }

    private fun topologicalOrder(tasks: List<TaskEntity>, dependencies: List<TaskDependencyEntity>): List<TaskEntity> {
        val byId = tasks.associateBy { it.id }
        val indegree = tasks.associate { it.id to 0 }.toMutableMap()
        val outgoing = mutableMapOf<String, MutableList<String>>()
        dependencies.forEach { d ->
            if (d.taskId == d.dependencyTaskId) throw DependencyCycleException()
            if (d.taskId in byId && d.dependencyTaskId in byId) {
                indegree[d.taskId] = indegree.getValue(d.taskId) + 1
                outgoing.getOrPut(d.dependencyTaskId) { mutableListOf() }.add(d.taskId)
            }
        }
        val ready = java.util.PriorityQueue<TaskEntity>(compareBy<TaskEntity> { it.sortOrder }.thenBy { it.id })
        tasks.filter { indegree[it.id] == 0 }.forEach(ready::add)
        val out = mutableListOf<TaskEntity>()
        while (ready.isNotEmpty()) {
            val task = ready.remove()
            out += task
            outgoing[task.id].orEmpty().forEach { child ->
                indegree[child] = indegree.getValue(child) - 1
                if (indegree[child] == 0) ready.add(byId.getValue(child))
            }
        }
        if (out.size != tasks.size) throw DependencyCycleException()
        return out
    }

    private fun criticalPathSeconds(order: List<TaskEntity>, deps: List<TaskDependencyEntity>, byId: Map<String, TaskEntity>): Long {
        val incoming = deps.groupBy { it.taskId }
        val longest = mutableMapOf<String, Long>()
        order.forEach { t ->
            val before = incoming[t.id].orEmpty().maxOfOrNull { longest[it.dependencyTaskId] ?: 0L } ?: 0L
            longest[t.id] = before + (byId[t.id]?.estimatedDurationSeconds ?: 0L)
        }
        return longest.values.maxOrNull() ?: 0L
    }

    private fun findResourceSlot(
        earliest: Long,
        durationMs: Long,
        requirements: List<TaskResourceEntity>,
        capacities: Map<String, Int>,
        allocations: Map<String, List<Allocation>>,
    ): Long {
        if (durationMs <= 0 || requirements.isEmpty()) return earliest
        var candidate = earliest
        var attempts = 0
        while (attempts < 1000) {
            attempts++
            var conflict = false
            for (req in requirements) {
                val cap = capacities[req.resourceId] ?: Int.MAX_VALUE
                val overlaps = allocations[req.resourceId].orEmpty()
                    .filter { it.start < candidate + durationMs && it.end > candidate }
                val used = overlaps.sumOf { it.units }
                if (used + req.capacityUnits > cap) {
                    conflict = true
                    val next = overlaps.minOfOrNull { it.end } ?: (candidate + durationMs)
                    candidate = if (next > candidate) next else candidate + 1L
                    break
                }
            }
            if (!conflict) return candidate
        }
        // Safety fallback: preserve liveness if resource contention is pathological.
        return earliest
    }
}
