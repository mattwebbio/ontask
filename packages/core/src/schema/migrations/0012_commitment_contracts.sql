CREATE TABLE "commitment_contracts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"stripe_customer_id" text,
	"stripe_payment_method_id" text,
	"payment_method_last4" text,
	"payment_method_brand" text,
	"has_active_stakes" boolean DEFAULT false NOT NULL,
	"setup_session_token" text,
	"setup_session_expires_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
