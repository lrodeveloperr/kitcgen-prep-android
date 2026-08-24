package studio.gooduse.kitchenprep.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        BoardEntity::class,
        TaskEntity::class,
        TaskDependencyEntity::class,
        ResourceEntity::class,
        TaskResourceEntity::class,
        TimerEntity::class,
        PrepGapEntity::class,
        ShiftEntity::class,
        TemplateEntity::class,
        TemplateTaskEntity::class,
        TemplatePrepGapTargetEntity::class,
        DurationObservationEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class KitchenDatabase : RoomDatabase() {
    abstract fun dao(): KitchenDao

    companion object {
        @Volatile private var INSTANCE: KitchenDatabase? = null
        fun get(context: Context): KitchenDatabase = INSTANCE ?: synchronized(this) {
            INSTANCE ?: Room.databaseBuilder(
                context.applicationContext,
                KitchenDatabase::class.java,
                "kitchen_prep_board.db"
            ).build().also { INSTANCE = it }
        }
    }
}
