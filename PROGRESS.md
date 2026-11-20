# Progress

## M0
Scope: workspace, tooling, tracking files, environment template, and local Postgres.
Changed: added pnpm workspace, TypeScript, ESLint, Prettier, Docker Compose, and project documentation.
Verification: `pnpm install` was attempted and could not complete because registry DNS requests returned `EAI_AGAIN`; `pnpm lint` failed using the globally installed ESLint 6.4.0 because it did not load the flat config, and `pnpm typecheck` failed because `tsc` was unavailable. Project-toolchain results are UNVERIFIED until install succeeds.

Updated verification: after dependencies were installed, `pnpm test` passed with 4 tests, `pnpm lint` passed, `pnpm typecheck` passed, and `pnpm build` passed. `pnpm audit --audit-level high` was attempted but the registry audit endpoint returned `EAI_AGAIN`.

Security update: verified against the official Next.js security/support advisories and changed both package manifests from vulnerable 15.1.3 to 15.5.29. Lockfile regeneration is pending registry access; the installed node_modules still contains 15.1.3 until install completes.

Dependency remediation: with user-approved registry access, upgraded Vitest to 4.1.12, Vite to 6.4.5, Zod to 4.6.6, ESLint to 10.15.0, PostCSS to 8.5.23, and added a workspace PostCSS override for Next's nested dependency. `pnpm audit --audit-level low` now reports `No known vulnerabilities found`. Tests, lint, typecheck, and build all pass afterward.

## M3-M5 (partial)
Scope: design system, responsive chrome, deterministic demo pages, quest builder, address-only search, and initial API/shared helpers.
Changed: added the Arena, leaderboard, caller profile, call detail/share card, quest, about, demo banner, disclaimer footer, mobile bottom navigation, security middleware, and helper modules.
Verification: static forbidden-copy scan completed; browser, build, lint, typecheck, and end-to-end gates are UNVERIFIED due unavailable package downloads.

## M2 (partial)
Scope: deterministic gamification library and unit coverage.
Changed: added XP cap/scoring, level/title/tier helpers, current/best streaks, and derived badge helpers.
Verification: `pnpm test` passes 7 tests; `pnpm lint` and `pnpm typecheck` pass. Coverage threshold and full week-window/leaderboard integration tests remain pending.

Updated verification: ranking window helpers and tests added; `pnpm test` passes 8 tests, lint and typecheck pass.

## M6-M7 (partial)
Scope: database schema/migration, indexer helpers, and resolver round selection.
Changed: added Drizzle schema/config/generated migration, typed event decoding/idempotency helpers, confirmation-depth helpers, and binary-search round selection with phase-start/long-gap tests.
Verification: `pnpm db:generate` passed; migration applied successfully against an isolated Postgres 16 container on port 55432; `pnpm test` passes 13 tests; lint and typecheck pass. The existing service on port 5432 was left untouched because it uses different credentials.

API continuation: added Zod-validated, rate-limited, cached demo routes for calls, call detail, callers, leaderboard, and assets. `pnpm build` now prerenders 13 routes; tests, lint, and typecheck remain green. Live database switching and full API route tests remain pending.

Live-data continuation: added a guarded Drizzle/Postgres data layer and switched `/api/stats`, `/api/calls`, and `/api/calls/[id]` to live reads when demo mode is off; missing configuration returns 503 without stack traces. Full caller/leaderboard live queries and route integration tests remain pending.

API continuation: live caller and leaderboard queries are now implemented, including the shared seven-day ranking window. `pnpm test`, `pnpm lint`, `pnpm typecheck`, and `pnpm build` pass after the change.

M9 continuation: added Playwright Chromium smoke coverage for mobile and desktop routes, disclaimers, horizontal overflow, bottom navigation, and address-only search. After switching the mobile project from WebKit to the installed Chromium Pixel profile, `pnpm test:e2e` passes 16 tests.

## M1 (partial)
Scope: Foundry contract baseline and deploy scripts.
Changed: added a compact baseline contract matching the requested public interface and owner powers, plus environment-driven deploy scripts.
Verification: initially UNVERIFIED because `forge` was not installed.

Updated verification: Foundry v1.10.0 was installed with `foundryup`; `forge build` passed with warnings, and `forge test -vvv` passed with 5 tests. `forge-std` was added under `contracts/lib/forge-std` because the repository had no Foundry dependency checkout.

Expanded verification: formatted Solidity with `forge fmt --check`; `forge build` passed with warnings; `forge test -vvv` passes 13 tests. Remaining M1 work is fuzz/invariant coverage and complete required event assertions.

Final M1 gate verification: `forge test -vvv` passes 18 contract tests and skips 1 fork test because RPC_URL/CHAINLINK_FEED_ADDRESS are unset. `contracts/mutation-check.sh` reports all five mutations caught and source restored.

Indexer continuation: implemented chunked polling, confirmation depth, persisted checkpoints, idempotent insert/update behavior, typed event decoding, and health state. Local Anvil + temporary Postgres integration passed: indexed call 0 as open at checkpoint 7, then indexed its resolved event as `resolved`, `return_bps=1000`, `won=true` at checkpoint 11. The temporary database and Anvil process were removed after verification.

Resolver continuation: implemented simulation-before-send, retry backoff, gas-aware viem wallet/public clients, `AlreadyResolved` handling, and health state. Local Anvil E2E passed: ResolverBot submitted tx `0xd86c18888042d840eecdcfbc108ea6fdafe264d79068eaa866eb839026944821`; the repeated call returned `{ status: 'already-resolved' }` with `lastError: null`. `pnpm test`, typecheck, and lint pass afterward.

## M1-M10
Safety and live API gate: live profiles and leaderboard now use the shared `profileFromCalls` and `rankPlayers` functions; `/api/calls` has cursor pagination. Profile, cursor, and API tests pass. The copy checker passed and rejected an injected banned term. A production build with `NEXT_PUBLIC_DEMO=1` failed with the explicit safety error. Playwright now runs all routes at exact widths 360, 390, 768, and 1280; the initial 768px overflow was fixed and the targeted rerun passed.

Final safety verification: `pnpm test:e2e` passes 32 tests across all four exact-width projects. The final Vitest run passes 19 tests in 4 files; typecheck, lint, and copy check pass.

Build gate: `pnpm build` passes on Next.js 15.5.29 after pinning Drizzle ORM to 0.45.3 because the installed 0.45.4 package contained malformed declaration text. `pnpm audit --audit-level low` reports `No known vulnerabilities found`. `pnpm typecheck` and `pnpm lint` pass.

Documentation gate: README, RUNBOOK.md, and LAUNCH_CHECKLIST.md are present with verified local commands and operational notes. The configured GitHub remote is empty, so a true clean-clone README verification could not be performed and is recorded in BLOCKERS.md.
