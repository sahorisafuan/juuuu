import { NextRequest, NextResponse } from 'next/server';
import { isValidSlug, publicApiError } from '@/lib/api/public-route';
import { createPublicSupabaseClient, getCourseCoverUrl } from '@/lib/supabase/public';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  const params = request.nextUrl.searchParams;
  const classSlug = params.get('classSlug')?.trim() || null;
  const categorySlug = params.get('categorySlug')?.trim() || null;
  const search = params.get('search')?.trim() || null;

  if (
    (classSlug && !isValidSlug(classSlug))
    || (categorySlug && !isValidSlug(categorySlug))
    || (search && (search.length > 100 || /[\u0000-\u001f]/.test(search)))
  ) {
    return NextResponse.json({ error: 'One or more search filters are invalid.' }, { status: 400 });
  }

  try {
    const supabase = createPublicSupabaseClient();
    const { data, error } = await supabase.rpc('search_public_courses', {
      p_class_slug: classSlug,
      p_category_slug: categorySlug,
      p_search: search,
    });

    if (error) throw error;

    return NextResponse.json((data ?? []).map((course) => ({
      id: course.id,
      slug: course.slug,
      title: course.title,
      summary: course.summary,
      className: course.class_name,
      categoryName: course.category_name,
      coverImageUrl: getCourseCoverUrl(supabase, course.cover_object_key),
      monthlyFeePoisha: course.monthly_fee_poisha,
      oneTimeFeePoisha: course.one_time_fee_poisha,
      instructorName: course.instructor_name,
    })));
  } catch (error) {
    return publicApiError(error, 'courses');
  }
}
