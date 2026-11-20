import { z } from 'zod';

const hits = new Map<string, { count: number; reset: number }>();
export const addressSchema = z.string().regex(/^0x[a-fA-F0-9]{40}$/, 'Enter a valid 0x address');
export const statusSchema = z.enum(['open', 'resolved']).optional();
export function limited(request: Request): boolean { const key = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'local'; const now = Date.now(); const entry = hits.get(key); if (!entry || entry.reset < now) { hits.set(key, { count: 1, reset: now + 60_000 }); return false; } entry.count += 1; return entry.count > 120; }
export function jsonHeaders(maxAge = 10): HeadersInit { return { 'Cache-Control': `public, s-maxage=${maxAge}, stale-while-revalidate=${maxAge * 6}` }; }
export function bad(message: string): Response { return Response.json({ error: message }, { status: 400 }); }
export function unavailable(): Response { return Response.json({ error: 'Live data is not configured.' }, { status: 503 }); }
