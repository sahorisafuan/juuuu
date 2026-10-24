import { NextResponse } from 'next/server';
import { isValidSlug, publicApiError } from '@/lib/api/public-route';
import { createPublicSupabaseClient, getCourseCoverUrl } from '@/lib/supabase/public';

export const dynamic = 'force-dynamic';

export async function GET(
  _request: Request,
  context: { params: Promise<{ slug: string }> },
) {
  const { slug } = await context.params;
  if (!isValidSlug(slug)) {
    return NextResponse.json({ error: 'Course not found.' }, { status: 404 });
  }

  try {
    const supabase = createPublicSupabaseClient();
    const { data: course, error } = await supabase
      .from('public_course_catalog')
      .select('id,slug,title,summary,description,learning_outcomes,class_name,category_name,cover_object_key,monthly_fee_poisha,one_time_fee_poisha,instructor_name')
      .eq('slug', slug)
      .maybeSingle();

    if (error) throw error;
    if (!course) {
      return NextResponse.json({ error: 'Course not found.' }, { status: 404 });
    }

    const { data: modules, error: modulesError } = await supabase
      .from('public_course_module_previews')
      .select('title,lesson_count,sort_order')
      .eq('course_id', course.id)
      .order('sort_order', { ascending: true });

    if (modulesError) throw modulesError;

    const learningOutcomes = Array.isArray(course.learning_outcomes)
      ? course.learning_outcomes.filter((item): item is string => typeof item === 'string')
      : [];

    return NextResponse.json({
      id: course.id,
      slug: course.slug,
      title: course.title,
      summary: course.summary,
      description: course.description,
      className: course.class_name,
      categoryName: course.category_name,
      coverImageUrl: getCourseCoverUrl(supabase, course.cover_object_key),
      monthlyFeePoisha: course.monthly_fee_poisha,
      oneTimeFeePoisha: course.one_time_fee_poisha,
      instructorName: course.instructor_name,
      learningOutcomes,
      modules: (modules ?? []).map((module) => ({
        title: module.title,
        lessonCount: module.lesson_count,
      })),
    });
  } catch (error) {
    return publicApiError(error, 'course-detail');
  }
}
