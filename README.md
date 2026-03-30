# On Task

Intelligent task scheduling with commitment contracts — iOS and macOS app.

## Monorepo Structure

```
ontask/
├── apps/
│   ├── api/          Hono REST API Worker  (api.ontaskhq.com/v1/*)
│   ├── admin-api/    Hono Operator API     (api.ontaskhq.com/admin/v1/*)
│   ├── mcp/          Hono MCP Worker       (mcp.ontaskhq.com)
│   ├── flutter/      Flutter iOS/macOS app (com.ontaskhq.ontask)
│   └── admin/        Cloudflare Pages SPA  (admin.ontaskhq.com)
└── packages/
    ├── core/         Shared types + Drizzle schema
    ├── scheduling/   Scheduling engine (pure function)
    └── ai/           AI pipeline abstraction
```

## Prerequisites

- Node.js ≥ 20
- pnpm ≥ 10 (`npm install -g pnpm`)
- Flutter 3.41 stable (`asdf install flutter 3.41.0` or https://flutter.dev/docs/get-started/install)
- Wrangler CLI (`pnpm add -g wrangler`)

## Getting Started

```bash
pnpm install
```

## Tech Stack

- **API & MCP:** Hono 4.12.9 on Cloudflare Workers
- **Database:** Neon serverless Postgres + Drizzle ORM
- **Mobile/Desktop:** Flutter 3.41 (iOS + macOS)
- **Admin SPA:** Vite + React (Cloudflare Pages)
