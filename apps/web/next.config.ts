import type { NextConfig } from 'next';
if (process.env.NODE_ENV === 'production' && process.env.NEXT_PUBLIC_DEMO === '1') throw new Error('Demo mode cannot be enabled in production');
const nextConfig: NextConfig = { output: 'standalone' };
export default nextConfig;
