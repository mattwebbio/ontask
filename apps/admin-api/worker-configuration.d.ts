// Minimal Cloudflare Worker bindings for admin-api.
// Generated via `wrangler types --env-interface CloudflareBindings` when secrets are configured.
// Workers Secrets (not committed): DATABASE_URL, ADMIN_JWT_SECRET
interface CloudflareBindings {
  DATABASE_URL?: string
  ADMIN_JWT_SECRET?: string
}
