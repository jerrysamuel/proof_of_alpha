import { parseAbi } from 'viem';

export const poaAbi = parseAbi([
  'error AlreadyResolved()',
  'event CallPosted(uint256 indexed id, address indexed caller, bytes32 indexed asset, bool isLong, int256 entryPrice, uint64 expiresAt)',
  'event CallResolved(uint256 indexed id, address indexed caller, int256 exitPrice, int256 returnBps, bool won)',
  'function postCall(bytes32 asset, bool isLong, uint64 duration) returns (uint256)',
  'function resolve(uint256 id, uint80 roundId)',
  'function totalCalls() view returns (uint256)',
]);
export const NETWORK_LABEL='network';
