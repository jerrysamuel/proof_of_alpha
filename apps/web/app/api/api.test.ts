import { beforeAll, describe, expect, it, vi } from 'vitest';

vi.stubEnv('NEXT_PUBLIC_DEMO', '1');
let callsRoute: typeof import('./calls/route');
let callerRoute: typeof import('./callers/[address]/route');
let leaderboardRoute: typeof import('./leaderboard/route');

beforeAll(async () => {
  callsRoute = await import('./calls/route');
  callerRoute = await import('./callers/[address]/route');
  leaderboardRoute = await import('./leaderboard/route');
});

describe('read-only API routes', () => {
  it('returns demo calls and applies status filters', async () => {
    const response = await callsRoute.GET(new Request('http://localhost/api/calls?status=open'));
    expect(response.status).toBe(200);
    const body = await response.json() as { calls: Array<{ status: string }> };
    expect(body.calls.length).toBeGreaterThan(0);
    expect(body.calls.every(call => call.status === 'open')).toBe(true);
  });
  it('returns a cursor for the next calls page', async () => {
    const response = await callsRoute.GET(new Request('http://localhost/api/calls?limit=1'));
    expect(response.status).toBe(200);
    const body = await response.json() as { calls: unknown[]; nextCursor: string | null };
    expect(body.calls).toHaveLength(1);
    expect(body.nextCursor).toBe('1');
  });
  it('rejects names where an address is required', async () => {
    const response = await callerRoute.GET(new Request('http://localhost/api/callers/alice.ai'), { params: Promise.resolve({ address: 'alice.ai' }) });
    expect(response.status).toBe(400);
  });
  it('rejects an unsupported leaderboard window', async () => {
    const response = await leaderboardRoute.GET(new Request('http://localhost/api/leaderboard?window=month'));
    expect(response.status).toBe(400);
  });
  it('returns a ranked demo leaderboard', async () => {
    const response = await leaderboardRoute.GET(new Request('http://localhost/api/leaderboard?window=week'));
    expect(response.status).toBe(200);
    const body = await response.json() as { players: Array<{ score: number }> };
    expect(body.players.length).toBeGreaterThan(0);
  });
});
