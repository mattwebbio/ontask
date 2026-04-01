CREATE TABLE "task_calendar_blocks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"task_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"connection_id" uuid NOT NULL,
	"google_event_id" text NOT NULL,
	"scheduled_start_time" timestamp with time zone NOT NULL,
	"scheduled_end_time" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "task_calendar_blocks_task_connection_unique" UNIQUE("task_id","connection_id")
);
--> statement-breakpoint
ALTER TABLE "task_calendar_blocks" ADD CONSTRAINT "task_calendar_blocks_connection_id_calendar_connections_id_fk" FOREIGN KEY ("connection_id") REFERENCES "public"."calendar_connections"("id") ON DELETE no action ON UPDATE no action;
