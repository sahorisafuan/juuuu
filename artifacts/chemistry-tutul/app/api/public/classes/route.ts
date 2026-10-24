import { NextResponse } from 'next/server';
import { publicApiError } from '@/lib/api/public-route';
import { createPublicSupabaseClient } from '@/lib/supabase/public';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const supabase = createPublicSupabaseClient();
    const { data, error } = await supabase
      .from('public_class_catalog')
      .select('id,name,slug,sort_order,published_course_count')
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true });

    if (error) throw error;

    return NextResponse.json((data ?? []).map((row) => ({
      id: row.id,
      name: row.name,
      slug: row.slug,
      sortOrder: row.sort_order,
      publishedCourseCount: row.published_course_count,
    })));
  } catch (error) {
    return publicApiError(error, 'classes');
  }
}
