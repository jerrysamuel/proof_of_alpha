import { createServer } from 'node:http';
import { createIndexer } from './indexer';

const env = process.env;
const { indexer, close } = createIndexer(env);
let error = '';
async function tick() { try { await indexer.runOnce(); error = ''; } catch (cause) { error = cause instanceof Error ? cause.message : 'Indexer failed'; console.error(error); } }
await indexer.initialize();
await tick();
const timer = setInterval(() => { void tick(); }, indexerConfigInterval(env));
const server = createServer((_request, response) => { response.setHeader('content-type', 'application/json'); response.end(JSON.stringify({ ...indexer.health(), error })); });
server.listen(Number(env.WORKER_HEALTH_PORT ?? 8787));
async function shutdown() { clearInterval(timer); server.close(); await close(); process.exit(0); }
process.on('SIGINT', () => { void shutdown(); }); process.on('SIGTERM', () => { void shutdown(); });
function indexerConfigInterval(values: Readonly<Record<string, string | undefined>>): number { return Number(values.LOG_POLL_MS ?? 5000); }
