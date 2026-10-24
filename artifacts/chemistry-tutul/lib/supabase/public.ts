import { createClient } from '@supabase/supabase-js';

export class MissingSupabaseConfigurationError extends Error {
  constructor() {
    super('Supabase public configuration is missing.');
    this.name = 'MissingSupabaseConfigurationError';
  }
}

export function createPublicSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();

  if (!url || !publishableKey) {
    throw new MissingSupabaseConfigurationError();
  }

  return createClient(url, publishableKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
      detectSessionInUrl: false,
    },
  });
}

export function getCourseCoverUrl(
  client: ReturnType<typeof createPublicSupabaseClient>,
  objectKey: string | null | undefined,
) {
  if (!objectKey) return null;
  return client.storage.from('course-covers').getPublicUrl(objectKey).data.publicUrl;
}
