'use client';

import { SignIn, SignUp } from '@clerk/nextjs';
import { shadcn } from '@clerk/themes';
import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import type { ComponentProps } from 'react';

type AuthMode = 'sign-in' | 'sign-up';
type ClerkAppearance = ComponentProps<typeof SignIn>['appearance'];

export function AuthScreen({ mode }: { mode: AuthMode }) {
  const [origin, setOrigin] = useState('');
  useEffect(() => setOrigin(window.location.origin), []);

  const appearance = useMemo<ClerkAppearance>(() => ({
    theme: shadcn,
    options: {
      logoPlacement: 'inside',
      logoLinkUrl: '/',
      logoImageUrl: origin ? new URL('/logo.svg', origin).toString() : undefined,
      socialButtonsPlacement: 'bottom',
      socialButtonsVariant: 'blockButton',
    },
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
  }), [origin]);

  return (
    <main className="auth-page">
      <section className="auth-panel">
        <div className="auth-copy">
          <Link className="eyebrow auth-back" href="/">Chemistry Tutul</Link>
          <h1>{mode === 'sign-in' ? 'Welcome back to learning.' : 'Start learning with confidence.'}</h1>
          <p>{mode === 'sign-in'
            ? 'Sign in to continue to your learning space.'
            : 'Create a student account to explore lessons, classes and course fees.'}</p>
          <span className="auth-note">A thoughtful classroom for students across Bangladesh.</span>
        </div>
        <div className="auth-form">
          {mode === 'sign-in'
            ? <SignIn routing="path" path="/sign-in" signUpUrl="/sign-up" fallbackRedirectUrl="/student/dashboard" appearance={appearance} />
            : <SignUp routing="path" path="/sign-up" signInUrl="/sign-in" fallbackRedirectUrl="/student/dashboard" appearance={appearance} />}
        </div>
      </section>
    </main>
  );
}
