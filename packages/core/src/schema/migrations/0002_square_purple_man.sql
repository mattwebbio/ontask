ALTER TABLE "tasks" ADD COLUMN "recurrence_rule" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "recurrence_interval" integer;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "recurrence_days_of_week" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "recurrence_parent_id" uuid;