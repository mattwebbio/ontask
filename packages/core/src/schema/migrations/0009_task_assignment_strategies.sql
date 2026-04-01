-- Migration: 0009_task_assignment_strategies
-- Story 5.2: Task Assignment Strategies
-- Adds assignment_strategy to lists, assigned_to_user_id to tasks,
-- and round_robin_index to list_members (FR17, FR18).

ALTER TABLE "lists" ADD COLUMN "assignment_strategy" text;
--> statement-breakpoint

ALTER TABLE "tasks" ADD COLUMN "assigned_to_user_id" uuid;
--> statement-breakpoint

ALTER TABLE "list_members" ADD COLUMN "round_robin_index" integer DEFAULT 0 NOT NULL;
