import { sql } from "drizzle-orm";
import {
  boolean,
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";

export const devices = pgTable(
  "devices",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull(),
    token: text("token").notNull(),
    platform: varchar("platform", { length: 20 }).notNull(),
    deviceId: varchar("device_id", { length: 120 }),
    active: boolean("active").notNull().default(true),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tokenIdx: uniqueIndex("devices_token_idx").on(table.token),
    userIdx: index("devices_user_idx").on(table.userId),
  }),
);

export const notifications = pgTable(
  "notifications",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull(),
    type: varchar("type", { length: 60 }).notNull(),
    title: text("title").notNull(),
    body: text("body").notNull(),
    eventType: varchar("event_type", { length: 60 }).notNull(),
    correlationId: uuid("correlation_id").notNull(),
    payload: jsonb("payload").notNull().default(sql`'{}'::jsonb`),
    sentAt: timestamp("sent_at", { withTimezone: true }).notNull(),
    read: boolean("read").notNull().default(false),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    userIdx: index("notifications_user_idx").on(table.userId),
    correlationUserIdx: uniqueIndex("notifications_correlation_user_idx").on(
      table.correlationId,
      table.userId,
    ),
  }),
);

export const processedEvents = pgTable("processed_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  correlationId: uuid("correlation_id").notNull().unique(),
  eventType: varchar("event_type", { length: 60 }).notNull(),
  processedAt: timestamp("processed_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

export type Device = typeof devices.$inferSelect;
export type Notification = typeof notifications.$inferSelect;
export type ProcessedEvent = typeof processedEvents.$inferSelect;
