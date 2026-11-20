import { describe, expect, it } from 'vitest';
import { alphaScore, badgeNames, bestStreak, callsInWindow, currentStreak, dailyXp, levelForXp, profileFromCalls, rankPlayers, tierForScore, titleForLevel, wilsonLower, xpForDay } from './gamify';

describe('gamification primitives', () => {
  it('caps daily XP at 100', () => expect(dailyXp([5, 10, 15, 80])).toBe(100));
  it('calculates level thresholds and titles', () => {
    expect(levelForXp(0)).toBe(1);
    expect(levelForXp(20)).toBe(2);
    expect(titleForLevel(10)).toBe('Oracle');
  });
  it('calculates Wilson scores without floating output in the ranking number', () => {
    expect(wilsonLower(5, 5)).toBeGreaterThan(0.56);
    expect(alphaScore(10, 10)).toBeGreaterThan(700);
    expect(alphaScore(7, 10)).toBeGreaterThan(350);
  });
  it('keeps tier boundaries deterministic', () => {
    expect(tierForScore(249)).toBe('Bronze');
    expect(tierForScore(250)).toBe('Silver');
    expect(tierForScore(400)).toBe('Gold');
    expect(tierForScore(700)).toBe('Diamond');
  });
  it('caps post XP and adds quality-weighted resolution bonuses', () => {
    expect(xpForDay(20, 5, 3, [2])).toBe(100);
    expect(xpForDay(3, 1, 1, [2])).toBe(45);
  });
  it('computes current and best streaks with a loss in the middle', () => {
    const calls = [
      { openedAt: 0, expiresAt: 10, resolvedAt: 40, won: true },
      { openedAt: 0, expiresAt: 10, resolvedAt: 30, won: true },
      { openedAt: 0, expiresAt: 10, resolvedAt: 20, won: false },
      { openedAt: 0, expiresAt: 10, resolvedAt: 10, won: true },
    ];
    expect(currentStreak(calls)).toBe(2); expect(bestStreak(calls)).toBe(2);
  });
  it('derives every badge condition', () => {
    const calls = Array.from({ length: 10 }, (_, i) => ({ openedAt: 0, expiresAt: i === 1 ? 7 * 24 * 60 * 60 : 10, resolvedAt: i + 1, won: i % 4 !== 0 }));
    expect(badgeNames(calls, true)).toEqual(expect.arrayContaining(['First Call','First Blood','Honest Record','Hot Streak I','Patient','Founding Caller']));
  });
  it('uses the same ranking function for all-time and a seven-day window', () => {
    const calls = (wins: number, start: number) => Array.from({ length: 5 }, (_, i) => ({ openedAt: start - 100, expiresAt: start - 50, resolvedAt: start + i, won: i < wins }));
    const players = [
      { address: '0x1', wins: 0, resolved: 0, cumulativeReturnBps: 10, firstCallAt: 1, calls: calls(5, 100) },
      { address: '0x2', wins: 0, resolved: 0, cumulativeReturnBps: 5, firstCallAt: 2, calls: calls(4, 100) },
    ];
    expect(rankPlayers(players).map(p => p.address)).toEqual(['0x1', '0x2']);
    expect(rankPlayers(players, 90)).toHaveLength(2);
    expect(callsInWindow(players[0].calls, 100)).toHaveLength(5);
  });
  it('derives live profile totals, XP, level, tier, streak, and badges', () => {
    const calls = [
      { openedAt: 1_700_000_000, expiresAt: 1_700_000_100, resolvedAt: 1_700_000_200, won: true, returnBps: 100 },
      { openedAt: 1_700_000_000, expiresAt: 1_700_000_100 },
    ];
    expect(profileFromCalls(calls)).toMatchObject({ total: 2, wins: 1, losses: 0, open: 1, xp: 35, level: 2, currentStreak: 1, bestStreak: 1, badges: ['First Call', 'First Blood'] });
  });
});
