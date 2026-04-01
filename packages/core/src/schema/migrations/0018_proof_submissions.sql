CREATE TABLE "proof_submissions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"task_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"proof_path" text NOT NULL,
	"media_url" text,
	"verified" boolean,
	"verification_reason" text,
	"client_timestamp" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
