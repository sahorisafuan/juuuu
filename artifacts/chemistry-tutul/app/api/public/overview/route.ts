import { NextResponse } from 'next/server';
import { publicApiError } from '@/lib/api/public-route';
import { createPublicSupabaseClient, getCourseCoverUrl } from '@/lib/supabase/public';

export const dynamic = 'force-dynamic';

type JsonRecord = Record<string, unknown>;

export async function GET() {
  try {
    const supabase = createPublicSupabaseClient();
    const [settingsResult, countsResult, classesResult, featuredResult] = await Promise.all([
      supabase
        .from('site_settings')
        .select('setting_key,value')
        .eq('is_public', true)
        .in('setting_key', ['brand', 'homepage']),
      supabase.rpc('public_overview_counts'),
      supabase
        .from('public_class_catalog')
        .select('id,name,slug,sort_order,published_course_count')
        .order('sort_order', { ascending: true })
        .order('name', { ascending: true }),
      supabase
        .from('public_course_catalog')
        .select('id,slug,title,summary,class_name,category_name,cover_object_key,monthly_fee_poisha,one_time_fee_poisha,instructor_name')
        .eq('is_featured', true)
        .order('title', { ascending: true })
        .limit(3),
    ]);

    const failedResult = [settingsResult, countsResult, classesResult, featuredResult]
      .find((result) => result.error);
    if (failedResult?.error) throw failedResult.error;

    const settings = settingsResult.data ?? [];
    const brand = settings.find((entry) => entry.setting_key === 'brand')?.value as JsonRecord | undefined;
    const homepage = settings.find((entry) => entry.setting_key === 'homepage')?.value as JsonRecord | undefined;
    const counts = countsResult.data?.[0];

    if (
      typeof brand?.name !== 'string'
      || typeof homepage?.tagline !== 'string'
      || typeof homepage?.introduction !== 'string'
      || !counts
    ) {
      throw new Error('Public overview settings or aggregate counts are missing.');
    }

    const toCourseSummary = (course: NonNullable<typeof featuredResult.data>[number]) => ({
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
    });

    return NextResponse.json({
      siteName: brand.name,
      tagline: homepage.tagline,
      introduction: homepage.introduction,
      activeStudentCount: Number(counts.active_student_count),
      publishedCourseCount: Number(counts.published_course_count),
      teacherCount: Number(counts.teacher_count),
      classes: (classesResult.data ?? []).map((row) => ({
        id: row.id,
        name: row.name,
        slug: row.slug,
        sortOrder: row.sort_order,
        publishedCourseCount: row.published_course_count,
      })),
      featuredCourses: (featuredResult.data ?? []).map(toCourseSummary),
    });
  } catch (error) {
    return publicApiError(error, 'overview');
  }
}
