import {
  boolean,
  index,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

export const activationCodes = pgTable(
  "activation_codes",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    code: varchar("code", { length: 12 }).notNull().unique(),
    caregiverId: uuid("caregiver_id").notNull(),
    dependentId: uuid("dependent_id").notNull(),
    dependentName: text("dependent_name").notNull(),
    caregiverName: text("caregiver_name").notNull(),
    used: boolean("used").notNull().default(false),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    usedAt: timestamp("used_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => ({
    codeIdx: uniqueIndex("activation_codes_code_idx").on(table.code),
    caregiverDependentIdx: index("activation_codes_caregiver_dependent_idx").on(
      table.caregiverId,
      table.dependentId,
    ),
  }),
);

export const links = pgTable(
  "links",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    caregiverId: uuid("caregiver_id").notNull(),
    dependentId: uuid("dependent_id").notNull(),
    dependentName: text("dependent_name").notNull(),
    caregiverName: text("caregiver_name").notNull(),
    active: boolean("active").notNull().default(true),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    deactivatedAt: timestamp("deactivated_at", { withTimezone: true }),
  },
  (table) => ({
    activeLinkIdx: uniqueIndex("links_active_caregiver_dependent_idx")
      .on(table.caregiverId, table.dependentId)
      .where(sql`${table.active} = true`),
    caregiverIdx: index("links_caregiver_idx").on(table.caregiverId),
    dependentIdx: index("links_dependent_idx").on(table.dependentId),
  }),
);

export type ActivationCode = typeof activationCodes.$inferSelect;
export type Link = typeof links.$inferSelect;
