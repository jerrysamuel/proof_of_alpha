import postgres from 'postgres';
import { eq } from 'drizzle-orm';
import { drizzle, type PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { createPublicClient, http, parseAbiItem, type Address, type PublicClient } from 'viem';
import * as schema from '../../db/schema';
import { decodeEventLog, type Hex } from 'viem';
import { poaAbi } from '../../packages/shared/abi';

export type IndexerConfig = { deployBlock: number; confirmations: number; chunk: number; pollMs: number };
export function indexerConfig(env: Readonly<Record<string, string | undefined>>): IndexerConfig { return { deployBlock: Number(env.DEPLOY_BLOCK ?? 0), confirmations: Number(env.CONFIRMATIONS ?? 5), chunk: Number(env.LOG_CHUNK_BLOCKS ?? 2000), pollMs: 5000 }; }
export function normalizeAddress(address: string): string { return address.toLowerCase(); }
export function nextBlock(head: bigint, confirmations: number): bigint { return head > BigInt(confirmations) ? head - BigInt(confirmations) : 0n; }
export function idempotentIds(existing: ReadonlySet<number>, incoming: readonly number[]): number[] { return incoming.filter((id, index) => !existing.has(id) && incoming.indexOf(id) === index); }

const postedEvent = parseAbiItem('event CallPosted(uint256 indexed id, address indexed caller, bytes32 indexed asset, bool isLong, int256 entryPrice, uint64 expiresAt)');
const resolvedEvent = parseAbiItem('event CallResolved(uint256 indexed id, address indexed caller, int256 exitPrice, int256 returnBps, bool won)');
type AppDatabase = PostgresJsDatabase<typeof schema>;
export type PostedEvent = { id: number; caller: string; asset: string; isLong: boolean; entryPrice: string; expiresAt: Date; openTx: string; openBlock: number };
export type ResolvedEvent = { id: number; exitPrice: string; returnBps: number; won: boolean; resolvedAt: Date; resolveTx: string };

export function decodePostedLog(log: { data: Hex; topics: readonly Hex[]; transactionHash?: Hex; blockNumber?: bigint }): PostedEvent {
  const topics = [...log.topics] as [`0x${string}`, ...`0x${string}`[]]; const decoded = decodeEventLog({ abi: poaAbi, data: log.data, topics }); if (decoded.eventName !== 'CallPosted') throw new Error('Unexpected event'); const args = decoded.args;
  return { id: Number(args.id), caller: normalizeAddress(args.caller), asset: args.asset, isLong: args.isLong, entryPrice: args.entryPrice.toString(), expiresAt: new Date(Number(args.expiresAt) * 1000), openTx: log.transactionHash ?? '0x', openBlock: Number(log.blockNumber ?? 0n) };
}
export function mergeResolved(open: PostedEvent, resolved: ResolvedEvent) { return { ...open, ...resolved, status: 'resolved' as const }; }

export class ContractIndexer {
  private lastIndexedBlock = 0n;
  public constructor(private readonly client: PublicClient, private readonly db: AppDatabase, private readonly address: Address, private readonly config: IndexerConfig) {}
  public async initialize(): Promise<void> { const state = await this.db.select().from(schema.indexerState).where(eq(schema.indexerState.key, 'lastProcessedBlock')).limit(1); this.lastIndexedBlock = state[0] ? BigInt(state[0].value) : BigInt(this.config.deployBlock - 1); }
  public health(): { lastIndexedBlock: number } { return { lastIndexedBlock: Number(this.lastIndexedBlock) }; }
  public async runOnce(): Promise<void> { const head = await this.client.getBlockNumber(); const safeHead = nextBlock(head, this.config.confirmations); if (safeHead <= this.lastIndexedBlock) return; let from = this.lastIndexedBlock + 1n; while (from <= safeHead) { const to = from + BigInt(this.config.chunk - 1) > safeHead ? safeHead : from + BigInt(this.config.chunk - 1); await this.indexRange(from, to); this.lastIndexedBlock = to; await this.db.insert(schema.indexerState).values({ key: 'lastProcessedBlock', value: to.toString() }).onConflictDoUpdate({ target: schema.indexerState.key, set: { value: to.toString() } }); from = to + 1n; } }
  private async indexRange(fromBlock: bigint, toBlock: bigint): Promise<void> { const [posted, resolved] = await Promise.all([this.client.getLogs({ address: this.address, event: postedEvent, fromBlock, toBlock }), this.client.getLogs({ address: this.address, event: resolvedEvent, fromBlock, toBlock })]); for (const log of posted) { if (log.args.id === undefined || log.args.caller === undefined || log.args.asset === undefined || log.args.isLong === undefined || log.args.entryPrice === undefined || log.args.expiresAt === undefined || log.transactionHash === undefined || log.blockNumber === undefined) continue; await this.db.insert(schema.calls).values({ id: Number(log.args.id), caller: normalizeAddress(log.args.caller), asset: log.args.asset, isLong: log.args.isLong, openedAt: new Date(), expiresAt: new Date(Number(log.args.expiresAt) * 1000), entryPrice: log.args.entryPrice.toString(), status: 'open', openTx: log.transactionHash, openBlock: Number(log.blockNumber) }).onConflictDoNothing(); } for (const log of resolved) { if (log.args.id === undefined || log.args.caller === undefined || log.args.exitPrice === undefined || log.args.returnBps === undefined || log.args.won === undefined || log.transactionHash === undefined || log.blockNumber === undefined) continue; const block = await this.client.getBlock({ blockNumber: log.blockNumber }); await this.db.update(schema.calls).set({ exitPrice: log.args.exitPrice.toString(), returnBps: Number(log.args.returnBps), won: log.args.won, status: 'resolved', resolvedAt: new Date(Number(block.timestamp) * 1000), resolveTx: log.transactionHash }).where(eq(schema.calls.id, Number(log.args.id))); } }
}

export function createIndexer(env: Readonly<Record<string, string | undefined>>): { indexer: ContractIndexer; close: () => Promise<void> } { const rpc = env.RPC_URL; const address = env.NEXT_PUBLIC_POA_ADDRESS as Address | undefined; if (!rpc || !address) throw new Error('RPC_URL and NEXT_PUBLIC_POA_ADDRESS are required'); const sql = postgres(env.DATABASE_URL ?? '', { max: 2 }); const db = drizzle(sql, { schema }); const client = createPublicClient({ transport: http(rpc), chain: { id: Number(env.NEXT_PUBLIC_CHAIN_ID ?? 56), name: env.NEXT_PUBLIC_NETWORK_LABEL ?? 'configured network', nativeCurrency: { name: 'native', symbol: 'native', decimals: 18 }, rpcUrls: { default: { http: [rpc] } } } }); return { indexer: new ContractIndexer(client, db, address, indexerConfig(env)), close: () => sql.end() }; }
