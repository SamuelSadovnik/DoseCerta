ALTER TABLE "dose_schedules" ADD COLUMN "reminder_published" boolean DEFAULT false NOT NULL;
--> statement-breakpoint
ALTER TABLE "dose_schedules" ADD COLUMN "reminder_published_at" timestamp with time zone;
--> statement-breakpoint
ALTER TABLE "dose_schedules" ADD COLUMN "reminder_correlation_id" uuid DEFAULT gen_random_uuid() NOT NULL;
--> statement-breakpoint
CREATE INDEX "dose_schedules_reminder_due_idx" ON "dose_schedules" USING btree ("reminder_published","scheduled_at");
