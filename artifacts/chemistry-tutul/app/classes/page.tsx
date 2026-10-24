'use client';

import Link from 'next/link';
import { ArrowRight, GraduationCap, RotateCw } from 'lucide-react';
import { getGetPublicClassesQueryKey, useGetPublicClasses } from '@workspace/api-client-react';

export default function ClassesPage() {
  const query = useGetPublicClasses({ query: { queryKey: getGetPublicClassesQueryKey() } });
  return <main className="wrap">
    <section className="page-hero"><div className="eyebrow">Your learning pathway</div><h1>Find your class.</h1><p>Start with the level you are studying. Each pathway leads to the courses currently published for that class.</p></section>
    <section className="catalog-layout">
      {query.isLoading ? <div className="class-grid">{[1,2,3,4].map(n => <div className="skeleton" style={{ height:155 }} key={n} />)}</div> :
        query.isError ? <div className="error-state"><div className="state-mark"><RotateCw size={18} /></div><h3>Class pathways are unavailable</h3><p>We couldn’t load the published class levels. Please try again.</p><button className="button button-light" onClick={() => void query.refetch()}>Try again</button></div> :
        query.data?.length ? <div>{query.data.map((c, index) => <article className="class-pathway" key={c.id}><span className="pathway-no">{String(index + 1).padStart(2,'0')}</span><div className="pathway-info"><h2>{c.name}</h2><p>Choose this pathway to see the published courses for your class.</p></div><div className="pathway-count">{c.publishedCourseCount} {c.publishedCourseCount === 1 ? 'course' : 'courses'} <Link href={`/courses?class=${encodeURIComponent(c.slug)}`} aria-label={`Explore courses for ${c.name}`} style={{ display:'inline-flex', marginLeft:8 }}><ArrowRight size={16} /></Link></div></article>)}</div> :
        <div className="empty-state"><div className="state-mark"><GraduationCap size={20} /></div><h3>No class pathways published yet</h3><p>Published class levels will be listed here when they are ready.</p></div>}
    </section>
    <section className="cta-strip" style={{ marginBottom:70, borderRadius:20 }}><div className="cta-inner"><div><h2>Want to browse by subject?</h2><p>Explore the full published course catalog.</p></div><Link className="button button-primary" href="/courses">Explore courses <ArrowRight size={16} /></Link></div></section>
  </main>;
}
