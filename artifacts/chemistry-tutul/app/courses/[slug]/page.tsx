'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { ArrowLeft, Check, RotateCw } from 'lucide-react';
import { getGetPublicCourseQueryKey, useGetPublicCourse } from '@workspace/api-client-react';
import { formatFee } from '../../ui/catalog';

export default function CourseDetailPage() {
  const params = useParams<{ slug: string }>();
  const slug = decodeURIComponent(params.slug);
  const query = useGetPublicCourse(slug, { query: { queryKey: getGetPublicCourseQueryKey(slug) } });
  if (query.isLoading) return <main className="section"><div className="wrap"><div className="skeleton" style={{ height:340, borderRadius:24 }} /></div></main>;
  if (query.isError || !query.data) return <main className="section"><div className="wrap"><div className="error-state"><div className="state-mark"><RotateCw size={18} /></div><h3>We couldn’t find this course</h3><p>It may be unavailable right now. Return to the catalog to explore published courses.</p><button className="button button-light" onClick={() => void query.refetch()}>Try again</button><div style={{ marginTop:14 }}><Link className="button button-quiet" href="/courses"><ArrowLeft size={16} /> Back to courses</Link></div></div></div></main>;
  const course = query.data;
  return <main>
    <section className="detail-hero"><div className="wrap">
      <div className="breadcrumbs"><Link href="/">Home</Link><span>/</span><Link href="/courses">Courses</Link><span>/</span><span>{course.title}</span></div>
      <div className="detail-grid"><div className="detail-main"><div className="eyebrow">Course overview</div><h1>{course.title}</h1><p className="summary">{course.summary}</p><div className="detail-tags">{course.className && <span className="tag">{course.className}</span>}{course.categoryName && <span className="tag">{course.categoryName}</span>}{course.instructorName && <span className="tag">With {course.instructorName}</span>}</div></div>
      <aside className="fee-card" aria-label="Course fees"><div className="eyebrow">Course fees</div>
        {course.monthlyFeePoisha > 0 && <div className="fee-row"><strong className="fee-amount">{formatFee(course.monthlyFeePoisha)}</strong><span className="fee-caption">Monthly fee</span></div>}
        {course.oneTimeFeePoisha > 0 && <div className="fee-row"><strong className="fee-amount">{formatFee(course.oneTimeFeePoisha)}</strong><span className="fee-caption">One-time fee</span></div>}
        {course.monthlyFeePoisha === 0 && course.oneTimeFeePoisha === 0 && <div className="fee-row"><span className="fee-caption">Fee details are not available for this course.</span></div>}
        <Link href="/pricing" className="button button-primary">See all course fees <span>↗</span></Link>
      </aside></div>
    </div></section>
    <section className="content-section"><div className="wrap content-columns">
      <div><h2>About this course</h2><div className="copy">{course.description}</div></div>
      <div><h2>What you’ll learn</h2>{course.learningOutcomes.length ? <ul className="outcome-list">{course.learningOutcomes.map((outcome, i) => <li key={`${i}-${outcome}`}><Check className="check-mark" size={17} /><span>{outcome}</span></li>)}</ul> : <p className="copy">Learning outcomes will be added to this course soon.</p>}</div>
    </div></section>
    <section className="section" style={{ background: '#eeece0' }}><div className="wrap"><div className="section-head"><div><div className="eyebrow">Inside the course</div><h2>Course modules</h2></div><p>Explore the topics included in this course.</p></div>
      {course.modules.length ? <div className="module-list">{course.modules.map((module, i) => <div className="module-row" key={`${i}-${module.title}`}><strong>{String(i + 1).padStart(2,'0')} &nbsp; {module.title}</strong><span>{module.lessonCount} {module.lessonCount === 1 ? 'lesson' : 'lessons'}</span></div>)}</div> : <div className="empty-state"><div className="state-mark">01</div><h3>Modules are being prepared</h3><p>Course topics will be listed here once published.</p></div>}
    </div></section>
    <div className="cta-strip"><div className="wrap cta-inner"><div><h2>Keep exploring.</h2><p>There may be another course that fits your next step.</p></div><Link href="/courses" className="button button-primary">Browse all courses <span>↗</span></Link></div></div>
  </main>;
}
