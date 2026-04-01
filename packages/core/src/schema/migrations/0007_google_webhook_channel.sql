ALTER TABLE "calendar_connections_google" ADD COLUMN "webhook_channel_resource_id" text;
--> statement-breakpoint
ALTER TABLE "calendar_connections_google" ADD COLUMN "webhook_channel_expiry" timestamp with time zone;
