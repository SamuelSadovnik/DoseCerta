import {
  boolean,
  index,
  pgTable,
  text,
  timestamp,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";

export const doseSchedules = pgTable(
  "dose_schedules",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    doseId: uuid("dose_id").notNull().unique(),
    userId: uuid("user_id").notNull(),
    dependentId: uuid("dependent_id"),
    medicationName: text("medication_name").notNull(),
    dosage: varchar("dosage", { length: 80 }).notNull(),
    note: text("note"),
    scheduledAt: timestamp("scheduled_at", { withTimezone: true }).notNull(),
    sourceStatus: varchar("source_status", { length: 20 })
      .notNull()
      .default("pending"),
    reminderPublished: boolean("reminder_published").notNull().default(false),
    reminderPublishedAt: timestamp("reminder_published_at", { withTimezone: true }),
    reminderCorrelationId: uuid("reminder_correlation_id")
      .notNull()
      .defaultRandom(),
    published: boolean("published").notNull().default(false),
    publishedAt: timestamp("published_at", { withTimezone: true }),
    correlationId: uuid("correlation_id").notNull().defaultRandom(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    dueIdx: index("dose_schedules_due_idx").on(
      table.published,
      table.scheduledAt,
    ),
    reminderDueIdx: index("dose_schedules_reminder_due_idx").on(
      table.reminderPublished,
      table.scheduledAt,
    ),
    doseIdIdx: index("dose_schedules_dose_id_idx").on(table.doseId),
  }),
);

export type DoseSchedule = typeof doseSchedules.$inferSelect;
