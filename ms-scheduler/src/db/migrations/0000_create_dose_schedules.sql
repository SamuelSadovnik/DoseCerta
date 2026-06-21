CREATE TABLE "dose_schedules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"dose_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"dependent_id" uuid,
	"medication_name" text NOT NULL,
	"dosage" varchar(80) NOT NULL,
	"note" text,
	"scheduled_at" timestamp with time zone NOT NULL,
	"source_status" varchar(20) DEFAULT 'pending' NOT NULL,
	"published" boolean DEFAULT false NOT NULL,
	"published_at" timestamp with time zone,
	"correlation_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "dose_schedules_dose_id_unique" UNIQUE("dose_id")
);
--> statement-breakpoint
CREATE INDEX "dose_schedules_due_idx" ON "dose_schedules" USING btree ("published","scheduled_at");
--> statement-breakpoint
CREATE INDEX "dose_schedules_dose_id_idx" ON "dose_schedules" USING btree ("dose_id");
