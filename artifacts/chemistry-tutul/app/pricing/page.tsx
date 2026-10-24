'use client';

import Link from 'next/link';
import { ArrowRight, RotateCw } from 'lucide-react';
import { getGetPublicCoursesQueryKey, useGetPublicCourses } from '@workspace/api-client-react';
import { formatFee } from '../ui/catalog';

export default function PricingPage() {
  const query = useGetPublicCourses({}, { query: { queryKey: getGetPublicCoursesQueryKey({}) } });
  return <main className="wrap">
    <section className="page-hero"><div className="eyebrow">Clear course fees</div><h1>Know the fee before you begin.</h1><p>Fees shown here come directly from published courses. Choose a course to see its details and learning plan.</p></section>
    <section className="catalog-layout">
      {query.isLoading ? <div className="course-grid">{[1,2,3].map(i => <div className="skeleton" key={i} style={{ height:245 }} />)}</div> :
        query.isError ? <div className="error-state"><div className="state-mark"><RotateCw size={18} /></div><h3>Fees could not be loaded</h3><p>We couldn’t retrieve published course fees. Please try again.</p><button className="button button-light" onClick={() => void query.refetch()}>Try again</button></div> :
        query.data?.length ? <div className="course-grid">{query.data.map(course => <article className="course-card" key={course.id}><div className="course-body"><div className="course-meta"><span>{course.className || 'School course'}</span>{course.categoryName && <><span className="meta-sep" /><span>{course.categoryName}</span></>}</div><h3>{course.title}</h3><p>{course.summary}</p>
          <div className="fee-row"><strong className="fee-amount">{course.monthlyFeePoisha > 0 ? formatFee(course.monthlyFeePoisha) : course.oneTimeFeePoisha > 0 ? formatFee(course.oneTimeFeePoisha) : 'Not listed'}</strong><span className="fee-caption">{course.monthlyFeePoisha > 0 ? 'Monthly fee' : course.oneTimeFeePoisha > 0 ? 'One-time fee' : 'Fee details are not available'}</span></div>
          {course.monthlyFeePoisha > 0 && course.oneTimeFeePoisha > 0 && <div style={{ color:'var(--muted)',fontSize:12,marginTop:10 }}>One-time fee: {formatFee(course.oneTimeFeePoisha)}</div>}
          <Link className="button button-primary" style={{ width:'100%', marginTop:18 }} href={`/courses/${encodeURIComponent(course.slug)}`}>Course details <ArrowRight size={16} /></Link>
        </div></article>)}</div> :
        <div className="empty-state"><div className="state-mark">৳</div><h3>No published fees yet</h3><p>Course fees will be listed here when published courses are available.</p></div>}
      <div className="pricing-note">Prices are displayed in Bangladeshi taka (BDT) and reflect the fee information attached to each published course.</div>
    </section>
  </main>;
}
