import Link from 'next/link';
import { AuthScreen } from '@/app/ui/auth-screen';

export const dynamic = 'force-dynamic';

export default function SignInPage() {
  const clerkConfigured = Boolean(
    process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY && process.env.CLERK_SECRET_KEY,
  );

  if (clerkConfigured) return <AuthScreen mode="sign-in" />;

  return (
    <main className="auth-page">
      <section className="auth-panel auth-setup-panel">
        <div className="auth-copy">
          <Link className="eyebrow auth-back" href="/">Chemistry Tutul</Link>
          <h1>Account access is being set up.</h1>
          <p>Sign-in is not available in this environment until its Clerk app configuration is connected.</p>
          <Link className="button button-primary" href="/">Back to the home page</Link>
        </div>
      </section>
    </main>
  );
}
