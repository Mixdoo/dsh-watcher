---
name: dsh-watcher
description: Change the Watcher DeepSeek Harness plugin without breaking its source-locked UI tests. Use when editing the work picture, pricing, session projection, or plugin packaging.
---

# Watcher

Read `AGENTS.md` and `docs/architecture.md` before editing.

Run `pnpm test` after a logic change. Run `pnpm build` when `src/dsh-watcher.ts` or `src/client/` changes, and keep the committed `lib/*.js` in sync. Do not reformat `src/` or `tests/`; `tests/presentation-contract.test.mjs` matches JSX and CSS text.

The load marker string `[my-plugins/dsh-watcher] loaded` must stay. Session text is local. Log host errors through `logError` in `src/log.ts`.

A live check needs an existing local Host. Follow the interactive steps in `AGENTS.md`. Do not invent a session or print `DSH_TEST_URL`.
