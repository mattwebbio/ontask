# Deferred Work

## Deferred from: code review of 1-1-monorepo-project-scaffold (2026-03-29)

- **tsconfig.base.json NodeNext/ESNext tension** — Base config sets `module: NodeNext` / `moduleResolution: NodeNext` which all app tsconfigs override with `ESNext` / `Bundler`. Packages inherit NodeNext. Matches spec today but will create real type-resolution tension when packages get actual code in Story 1.3. Revisit when adding imports to packages/core.
- **Stub CI/CD workflows always pass** — ci.yml, deploy-staging.yml, deploy-production.yml are live and trivially succeed (echo only), giving false green in branch protection. Intentional per Story 1.1 scope; full implementation in Story 1.2.
- **`/static/style.css` 404 in admin renderer** — `apps/admin/src/renderer.tsx` references `/static/style.css` which does not exist. Silent 404 in dev/prod. Stub app; addressed when admin SPA is developed in a later story.
- **`ci.yml` only triggers on `pull_request`** — Direct pushes to `main` (squash-merges) bypass CI entirely while staging deploy triggers. Stub workflow; correct triggers implemented in Story 1.2.
