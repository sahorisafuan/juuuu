'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ClerkProvider } from '@clerk/nextjs';
import { shadcn } from '@clerk/themes';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [client] = useState(() => new QueryClient({
    defaultOptions: { queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false } },
  }));
  const content = <QueryClientProvider client={client}>{children}</QueryClientProvider>;
  const publishableKey = process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY;

  if (!publishableKey) return content;

  return (
    <ClerkProvider
      publishableKey={publishableKey}
      signInUrl="/sign-in"
      signUpUrl="/sign-up"
      appearance={{
        theme: shadcn,
        variables: {
          colorPrimary: '#176b57',
          colorForeground: '#18342d',
          colorMutedForeground: '#66776f',
          colorBackground: '#fffdf7',
          colorInput: '#fffdf7',
          colorInputForeground: '#18342d',
          colorDanger: '#b64840',
          colorNeutral: '#d8e1d9',
          fontFamily: 'Manrope, Hind Siliguri, sans-serif',
          borderRadius: '1rem',
        },
      }}
    >
      {content}
    </ClerkProvider>
  );
}
