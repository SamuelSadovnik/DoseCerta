CREATE TABLE "activation_codes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(12) NOT NULL,
	"caregiver_id" uuid NOT NULL,
	"dependent_id" uuid NOT NULL,
	"dependent_name" text NOT NULL,
	"caregiver_name" text NOT NULL,
	"used" boolean DEFAULT false NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"used_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "activation_codes_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "links" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"caregiver_id" uuid NOT NULL,
	"dependent_id" uuid NOT NULL,
	"dependent_name" text NOT NULL,
	"caregiver_name" text NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deactivated_at" timestamp with time zone
);
--> statement-breakpoint
CREATE UNIQUE INDEX "activation_codes_code_idx" ON "activation_codes" USING btree ("code");
--> statement-breakpoint
CREATE INDEX "activation_codes_caregiver_dependent_idx" ON "activation_codes" USING btree ("caregiver_id","dependent_id");
--> statement-breakpoint
CREATE UNIQUE INDEX "links_active_caregiver_dependent_idx" ON "links" USING btree ("caregiver_id","dependent_id") WHERE "links"."active";
--> statement-breakpoint
CREATE INDEX "links_caregiver_idx" ON "links" USING btree ("caregiver_id");
--> statement-breakpoint
CREATE INDEX "links_dependent_idx" ON "links" USING btree ("dependent_id");
