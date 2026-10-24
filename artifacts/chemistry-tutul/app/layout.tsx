import type { Metadata } from 'next';
import './globals.css';
import { Providers } from './providers';
import { SiteHeader, SiteFooter } from './ui/site-shell';

export const metadata: Metadata = {
  title: 'Chemistry Tutul | Learn with understanding',
  description: 'A welcoming place for school students to learn, practise and grow.',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body><Providers><SiteHeader />{children}<SiteFooter /></Providers></body></html>;
}
