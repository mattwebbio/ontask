-- Migration: 0011_shared_proof_visibility
-- Story 5.5: Shared Proof Visibility
-- Adds proof_retained and proof_media_url to tasks table (FR21, NFR-S4).

ALTER TABLE "tasks" ADD COLUMN "proof_retained" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "proof_media_url" text;
