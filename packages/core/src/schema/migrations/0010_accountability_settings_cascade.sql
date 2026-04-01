-- Migration: 0010_accountability_settings_cascade
-- Story 5.4: Accountability Settings Cascade
-- Adds proof_requirement to lists and sections,
-- and proof_mode / proof_mode_is_custom to tasks (FR20).

ALTER TABLE "lists" ADD COLUMN "proof_requirement" text;--> statement-breakpoint
ALTER TABLE "sections" ADD COLUMN "proof_requirement" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "proof_mode" text;--> statement-breakpoint
ALTER TABLE "tasks" ADD COLUMN "proof_mode_is_custom" boolean DEFAULT false NOT NULL;
