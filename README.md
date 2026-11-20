# Proof of Alpha

Proof of Alpha is a read-only, mobile-first record of on-chain market calls. The web app never connects a wallet or sends transactions; worker processes index and resolve records.

## Quick start

```sh
pnpm install
cp .env.example .env.local
pnpm dev
```

Demo mode is enabled by `NEXT_PUBLIC_DEMO=1` and is suitable for local UI work only. Production builds reject that setting. For live data, set `NEXT_PUBLIC_DEMO=0`, `DATABASE_URL`, `RPC_URL`, `NEXT_PUBLIC_POA_ADDRESS`, and `DEPLOY_BLOCK`.

## Verification

```sh
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm copy:check
pnpm test:e2e
pnpm audit --audit-level low
```

The browser gate covers every route at 360, 390, 768, and 1280 CSS pixels. `pnpm copy:check` rejects prohibited promotional copy in web source.

## Live data services

```sh
docker compose up -d
pnpm db:migrate
pnpm worker:indexer
```

The indexer uses `CONFIRMATIONS` and `LOG_CHUNK_BLOCKS`, persists its checkpoint in `indexer_state`, and exposes health on `WORKER_HEALTH_PORT` (default `8787`). The resolver uses `RESOLVER_PRIVATE_KEY`, simulates before sending, retries transient failures, and treats an already-resolved call as success. See [RUNBOOK.md](RUNBOOK.md) for operations and recovery.

## Contract workflow

```sh
cd contracts
forge fmt --check
forge build
forge test -vvv
./mutation-check.sh
```

Set `RPC_URL` and `CHAINLINK_FEED_ADDRESS` to run the fork test; otherwise it skips explicitly.

Before launch, independently review and audit the contract, verify feed and Agent ID addresses, deploy to testnet then mainnet, verify source, transfer ownership to a multisig, confirm hackathon policy, and smoke test with a real Agent ID wallet. Use [LAUNCH_CHECKLIST.md](LAUNCH_CHECKLIST.md).
