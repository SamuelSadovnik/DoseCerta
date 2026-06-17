CREATE TABLE "appointment_schedules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"appointment_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"dependent_id" uuid,
	"doctor_name" text NOT NULL,
	"specialty" text,
	"location" text,
	"scheduled_at" timestamp with time zone NOT NULL,
	"source_status" varchar(20) DEFAULT 'scheduled' NOT NULL,
	"reminder_published" boolean DEFAULT false NOT NULL,
	"reminder_published_at" timestamp with time zone,
	"reminder_correlation_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "appointment_schedules_appointment_id_unique" UNIQUE("appointment_id")
);
--> statement-breakpoint
CREATE INDEX "appointment_schedules_reminder_due_idx" ON "appointment_schedules" USING btree ("reminder_published","scheduled_at");
--> statement-breakpoint
CREATE INDEX "appointment_schedules_appointment_id_idx" ON "appointment_schedules" USING btree ("appointment_id");
