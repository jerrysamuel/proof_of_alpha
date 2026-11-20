# Launch checklist

## Required engineering gates

- [ ] `pnpm install` completes from a clean checkout.
- [ ] `pnpm audit --audit-level low` reports no known vulnerabilities.
- [ ] `pnpm lint`, `pnpm typecheck`, `pnpm test`, and `pnpm build` pass.
- [ ] `pnpm copy:check` passes and the 360/390/768/1280 Playwright suite passes.
- [ ] `forge fmt --check`, `forge build`, `forge test -vvv`, and `contracts/mutation-check.sh` pass.
- [ ] Anvil/Postgres indexer and resolver end-to-end checks pass.
- [ ] README commands have been run from a clean checkout, or the exception is recorded in `BLOCKERS.md`.

## Contract and infrastructure

- [ ] Independent contract review completed.
- [ ] Chainlink feed addresses and decimals verified on the target network.
- [ ] Agent ID address and first-round behavior verified on the target network.
- [ ] Deploy block, confirmation depth, log chunk size, RPC URL, and database URL are set.
- [ ] Contract source is verified and ownership is transferred to the approved multisig.
- [ ] Resolver key is funded only with the required operational balance and is not exposed to the web app.
- [ ] `/api/health` and worker health endpoints are monitored.

## Product and policy

- [ ] Disclaimer and address-only identity rules reviewed.
- [ ] Hackathon, oracle, and data-provider policies confirmed.
- [ ] Production environment has `NEXT_PUBLIC_DEMO=0`.
- [ ] No unresolved item in `BLOCKERS.md` is being treated as verified.
