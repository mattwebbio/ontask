-- Migration: 0008_list_sharing
-- Story 5.1: List Sharing & Invitations
-- Creates list_members and list_invitations tables for FR15/FR16 sharing flow.

CREATE TABLE "list_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"list_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" text DEFAULT 'member' NOT NULL,
	"joined_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "list_members_list_id_lists_id_fk" FOREIGN KEY ("list_id") REFERENCES "lists"("id") ON DELETE cascade,
	CONSTRAINT "list_members_list_id_user_id_unique" UNIQUE ("list_id", "user_id")
);
--> statement-breakpoint

CREATE TABLE "list_invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"list_id" uuid NOT NULL,
	"invited_by_user_id" uuid NOT NULL,
	"invitee_email" text NOT NULL,
	"token" text NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "list_invitations_list_id_lists_id_fk" FOREIGN KEY ("list_id") REFERENCES "lists"("id") ON DELETE cascade,
	CONSTRAINT "list_invitations_token_unique" UNIQUE("token")
);
--> statement-breakpoint

-- TODO(impl): Add partial unique index to prevent duplicate pending invitations:
-- CREATE UNIQUE INDEX "list_invitations_list_id_invitee_email_pending_unique"
--   ON "list_invitations" ("list_id", "invitee_email")
--   WHERE "status" = 'pending';
-- Partial unique indexes are not supported by Drizzle Kit schema inference;
-- enforce at API level until a raw SQL migration is added.
