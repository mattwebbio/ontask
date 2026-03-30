# @ontask/mcp — Hono MCP Worker

## Development

```bash
# From repo root
pnpm install

# Start dev server (from this directory)
pnpm dev
```

## Deploy

```bash
pnpm deploy
```

## Generate Cloudflare bindings types

```bash
pnpm cf-typegen
```

Use the generated `CloudflareBindings` type when instantiating Hono:

```ts
// src/index.ts
const app = new Hono<{ Bindings: CloudflareBindings }>()
```
