import { NextResponse } from 'next/server';
import { MissingSupabaseConfigurationError } from '@/lib/supabase/public';

export function publicApiError(error: unknown, context: string) {
  if (error instanceof MissingSupabaseConfigurationError) {
    return NextResponse.json(
      { error: 'The public catalog is not configured yet.' },
      { status: 503 },
    );
  }

  console.error(`[public-api:${context}]`, error instanceof Error ? error.message : 'Unknown error');
  return NextResponse.json(
    { error: 'Unable to load the public catalog right now.' },
    { status: 500 },
  );
}

export function isValidSlug(value: string) {
  return /^[a-z0-9](?:[a-z0-9-]{0,98}[a-z0-9])?$/.test(value);
}
