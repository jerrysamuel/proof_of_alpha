import { describe, expect, it } from 'vitest';
import { idempotentIds, indexerConfig, nextBlock, normalizeAddress } from './indexer';

describe('indexer helpers', () => {
  it('normalizes addresses and keeps event upserts idempotent', () => {
    expect(normalizeAddress('0xABC')).toBe('0xabc');
    expect(idempotentIds(new Set([1]), [1, 2, 2, 3])).toEqual([2, 3]);
  });
  it('respects confirmation depth and environment defaults', () => {
    expect(nextBlock(100n, 5)).toBe(95n);
    expect(indexerConfig({ DEPLOY_BLOCK: '42' })).toEqual({ deployBlock: 42, confirmations: 5, chunk: 2000, pollMs: 5000 });
  });
});
