ALTER TABLE "tasks" ADD COLUMN "time_window" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "time_window_start" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "time_window_end" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "energy_requirement" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "priority" text DEFAULT 'normal';