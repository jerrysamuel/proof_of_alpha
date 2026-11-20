# Runbook

## Local demo

```sh
cp .env.example .env.local
pnpm dev
```

The demo path is deterministic and does not require Postgres or an RPC endpoint.

## Live stack

1. Set `NEXT_PUBLIC_DEMO=0`, `DATABASE_URL`, `RPC_URL`, `NEXT_PUBLIC_POA_ADDRESS`, `DEPLOY_BLOCK`, and the correct chain ID.
2. Start Postgres and apply migrations:

```sh
docker compose up -d postgres
pnpm db:migrate
```

3. Start the indexer with `CONFIRMATIONS` and `LOG_CHUNK_BLOCKS` set for the target chain:

```sh
pnpm worker:indexer
curl http://127.0.0.1:8787
```

4. Run the web server with `pnpm dev` locally or `pnpm build && pnpm start` in a deployment environment.

## Recovery

- If the indexer stops, inspect its health endpoint and restart it. The checkpoint is persisted in `indexer_state`; restarting is safe and event inserts are idempotent.
- If an RPC request fails, lower `LOG_CHUNK_BLOCKS`, verify `CONFIRMATIONS`, and check the endpoint's rate limits.
- If Postgres is unavailable, API routes return a bounded 503 response. Restore the database and restart the indexer; do not manually fabricate call rows.
- Resolver failures are recorded in health state. Verify gas, key balance, chain ID, and contract address before retrying. A repeated `AlreadyResolved` result is successful reconciliation.

## Release verification

Run the complete command set in README, then review `BLOCKERS.md`, contract deployment addresses, feed rounds, Agent ID configuration, and the launch checklist.
