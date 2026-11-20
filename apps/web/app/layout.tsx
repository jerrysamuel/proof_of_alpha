import type { Metadata } from 'next';
import './globals.css';
import { Header, BottomNav, DemoBanner, DisclaimerFooter } from '../components/chrome';

export const metadata: Metadata = { title: 'Proof of Alpha', description: 'Your calls. Your record. No deletes.' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body><DemoBanner /><Header /><main>{children}</main><DisclaimerFooter /><BottomNav /></body></html>;
}
