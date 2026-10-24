import { NextResponse } from 'next/server';
import { publicApiError } from '@/lib/api/public-route';
import { createPublicSupabaseClient } from '@/lib/supabase/public';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabase = createPublicSupabaseClient();
    const { data, error } = await supabase
      .from('public_category_catalog')
      .select('id,name,slug')
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true });

    if (error) throw error;
    return NextResponse.json(data ?? []);
  } catch (error) {
    return publicApiError(error, 'categories');
  }
}
