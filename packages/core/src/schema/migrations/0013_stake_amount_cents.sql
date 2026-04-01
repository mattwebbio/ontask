ALTER TABLE "commitment_contracts" ALTER COLUMN "setup_session_expires_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "commitment_contracts" ALTER COLUMN "created_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "commitment_contracts" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "commitment_contracts" ALTER COLUMN "updated_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "commitment_contracts" ALTER COLUMN "updated_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "stake_amount_cents" integer;
