package studio.gooduse.kitchenprep.data

import java.util.Locale
import java.util.UUID

object DraftTaskParser {
    fun parse(boardId: String, text: String): List<TaskEntity> {
        val lines = text.lineSequence().map { it.trim() }.filter { it.isNotEmpty() }.toList()
        val used = mutableMapOf<String, Int>()
        return lines.mapIndexed { index, line ->
            val base = canonical(line)
            val count = used.getOrDefault(base, 0) + 1
            used[base] = count
            val canonical = if (count == 1) base else "${base}_$count"
            val kind = inferKind(line)
            TaskEntity(
                id = UUID.randomUUID().toString(),
                boardId = boardId,
                canonicalActionId = canonical,
                displayText = line,
                kind = kind,
                status = "AVAILABLE",
                estimatedDurationSeconds = inferDurationSeconds(line, kind),
                sortOrder = index.toLong() * 1000L,
            )
        }
    }

    private fun canonical(text: String): String {
        val normalized = text.lowercase(Locale.ROOT)
            .replace(Regex("[^a-z0-9]+"), "_")
            .trim('_')
            .take(56)
        return normalized.ifBlank { "task" }
    }

    private fun inferKind(text: String): String {
        val t = text.lowercase(Locale.ROOT)
        return when {
            listOf("rest", "wait", "hold", "cool", "marinate", "proof", "rise").any(t::contains) -> "WAITING_PERIOD"
            listOf("serve", "plate", "garnish").any(t::contains) -> "SERVE"
            listOf("cook", "roast", "bake", "boil", "simmer", "grill", "fry", "sear", "steam").any(t::contains) -> "COOK"
            else -> "PREP"
        }
    }

    private fun inferDurationSeconds(text: String, kind: String): Long {
        val explicit = Regex("(?i)\\b(\\d{1,3})\\s*(?:min|mins|minute|minutes)\\b")
            .find(text)?.groupValues?.getOrNull(1)?.toLongOrNull()
        if (explicit != null) return explicit.coerceIn(1, 360) * 60L
        return when (kind) {
            "WAITING_PERIOD" -> 6L * 60L
            "COOK" -> 18L * 60L
            "SERVE" -> 4L * 60L
            else -> 8L * 60L
        }
    }
}
