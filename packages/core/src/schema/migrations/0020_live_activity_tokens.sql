-- Live Activity tokens table (Story 12.1, ARCH-28)
-- ActivityKit push tokens for server-initiated Dynamic Island + Lock Screen updates.
-- Distinct from device_tokens (APNs) — each Live Activity instance has its own token.
CREATE TABLE "live_activity_tokens" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "task_id" uuid,
  "activity_type" text NOT NULL,
  "push_token" text NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL
);
