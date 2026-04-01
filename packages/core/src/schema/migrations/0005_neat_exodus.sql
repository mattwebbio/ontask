CREATE TABLE "calendar_connections_apple" (
	"connection_id" uuid PRIMARY KEY NOT NULL
);
--> statement-breakpoint
CREATE TABLE "calendar_connections_google" (
	"connection_id" uuid PRIMARY KEY NOT NULL,
	"account_email" text NOT NULL,
	"access_token" text NOT NULL,
	"refresh_token" text NOT NULL,
	"token_expiry" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "calendar_connections_outlook" (
	"connection_id" uuid PRIMARY KEY NOT NULL
);
--> statement-breakpoint
CREATE TABLE "calendar_connections" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"provider" text NOT NULL,
	"calendar_id" text NOT NULL,
	"display_name" text NOT NULL,
	"is_read" boolean DEFAULT true NOT NULL,
	"is_write" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "calendar_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"connection_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"google_event_id" text NOT NULL,
	"start_time" timestamp with time zone NOT NULL,
	"end_time" timestamp with time zone NOT NULL,
	"is_all_day" boolean NOT NULL,
	"summary" text,
	"synced_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "calendar_connections_apple" ADD CONSTRAINT "calendar_connections_apple_connection_id_calendar_connections_id_fk" FOREIGN KEY ("connection_id") REFERENCES "public"."calendar_connections"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "calendar_connections_google" ADD CONSTRAINT "calendar_connections_google_connection_id_calendar_connections_id_fk" FOREIGN KEY ("connection_id") REFERENCES "public"."calendar_connections"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "calendar_connections_outlook" ADD CONSTRAINT "calendar_connections_outlook_connection_id_calendar_connections_id_fk" FOREIGN KEY ("connection_id") REFERENCES "public"."calendar_connections"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_connection_id_calendar_connections_id_fk" FOREIGN KEY ("connection_id") REFERENCES "public"."calendar_connections"("id") ON DELETE no action ON UPDATE no action;