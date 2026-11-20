import { describe, expect, it } from 'vitest';
import { findFirstRound } from './resolver';

describe('resolver round selection', () => {
  it('finds the first round after a long oracle gap', () => {
    const round = findFirstRound([
      { id: 1n, updatedAt: 100 },
      { id: 2n, updatedAt: 200 },
      { id: 3n, updatedAt: 10_000 },
    ], 500);
    expect(round?.id).toBe(3n);
  });
  it('accepts the first round in a new phase when no previous round exists', () => {
    const phaseStart = (2n << 64n) | 1n;
    const round = findFirstRound([{ id: phaseStart, updatedAt: 1_000 }], 900);
    expect(round?.id).toBe(phaseStart);
  });
  it('returns undefined when no round is at or after expiry', () => {
    expect(findFirstRound([{ id: 1n, updatedAt: 100 }], 101)).toBeUndefined();
  });
});
