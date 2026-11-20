import { bigint, boolean, index, integer, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const calls = pgTable('calls', {
  id: bigint('id', { mode: 'number' }).primaryKey(),
  caller: text('caller').notNull(),
  asset: text('asset').notNull(),
  isLong: boolean('is_long').notNull(),
  openedAt: timestamp('opened_at', { withTimezone: true }).notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  resolvedAt: timestamp('resolved_at', { withTimezone: true }),
  entryPrice: text('entry_price').notNull(),
  exitPrice: text('exit_price'),
  returnBps: integer('return_bps'),
  status: text('status', { enum: ['open', 'resolved'] }).notNull(),
  won: boolean('won'),
  openTx: text('open_tx').notNull(),
  resolveTx: text('resolve_tx'),
  openBlock: bigint('open_block', { mode: 'number' }).notNull(),
}, (table) => ({
  callerIdx: index('calls_caller_idx').on(table.caller),
  statusIdx: index('calls_status_idx').on(table.status),
  expiresIdx: index('calls_expires_at_idx').on(table.expiresAt),
  resolvedIdx: index('calls_resolved_at_idx').on(table.resolvedAt),
}));

export const indexerState = pgTable('indexer_state', {
  key: text('key').primaryKey(),
  value: text('value').notNull(),
});
