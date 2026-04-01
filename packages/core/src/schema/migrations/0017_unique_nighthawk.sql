CREATE TABLE "group_commitment_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"group_commitment_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"stake_amount_cents" integer,
	"approved" boolean DEFAULT false NOT NULL,
	"pool_mode_opt_in" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "group_commitment_members_commitment_user_unique" UNIQUE("group_commitment_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "group_commitments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"list_id" uuid NOT NULL,
	"task_id" uuid NOT NULL,
	"proposed_by_user_id" uuid NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "group_commitment_members" ADD CONSTRAINT "group_commitment_members_group_commitment_id_group_commitments_id_fk" FOREIGN KEY ("group_commitment_id") REFERENCES "public"."group_commitments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "group_commitments" ADD CONSTRAINT "group_commitments_list_id_lists_id_fk" FOREIGN KEY ("list_id") REFERENCES "public"."lists"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "group_commitments" ADD CONSTRAINT "group_commitments_task_id_tasks_id_fk" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE cascade ON UPDATE no action;