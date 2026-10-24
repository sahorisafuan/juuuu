'use client';

import Link from 'next/link';
import { ArrowRight, FlaskConical, RotateCw, Sparkles } from 'lucide-react';
import { getGetPublicOverviewQueryKey, useGetPublicOverview } from '@workspace/api-client-react';
import { CourseCard } from './ui/catalog';

export default function HomePage() {
  const overview = useGetPublicOverview({ query: { queryKey: getGetPublicOverviewQueryKey() } });
  if (overview.isLoading) return <main><section className="hero"><div className="wrap hero-grid"><div><div className="skeleton" style={{ width:190,height:13 }} /><div className="skeleton" style={{ width:'92%',height:180,marginTop:26 }} /><div className="skeleton" style={{ width:'75%',height:48,marginTop:18 }} /></div><div className="skeleton" style={{ width:'100%',aspectRatio:'1',borderRadius:'50%' }} /></div></section><section className="section"><div className="wrap"><div className="course-grid">{[1,2,3].map(i=><div key={i} className="skeleton" style={{ height:300 }} />)}</div></div></section></main>;
  if (overview.isError || !overview.data) return <main className="section"><div className="wrap error-state"><div className="state-mark"><RotateCw size={18} /></div><h3>We couldn’t open the classroom</h3><p>The learning overview is temporarily unavailable. Try again in a moment.</p><button className="button button-light" onClick={() => void overview.refetch()}>Try again</button></div></main>;
  const data = overview.data;
  return <main>
    <section className="hero"><div className="wrap hero-grid">
      <div><div className="hero-kicker"><span className="kicker-dot" /> A better way to understand science</div>
        <h1>{data.tagline || <>Curiosity is the <span>first lesson.</span></>}</h1>
        <p className="hero-intro">{data.introduction}</p>
        <div className="hero-actions"><Link className="button button-primary" href="/courses">Explore courses <ArrowRight size={16} /></Link><Link className="button button-light" href="/classes">Find your class</Link></div>
        <div className="hero-note"><Sparkles size={14} /> For students and families, from class to class</div>
      </div>
      <div className="hero-art" aria-label="Illustration inspired by chemistry"><div className="orbit"><div className="orbit-core"><strong>H₂O</strong><small>Understand it</small></div><span className="atom a1">Na</span><span className="atom a2">O₂</span><span className="atom a3">C</span><span className="atom a4">H</span></div><span className="art-label top">Ideas become clear</span><span className="art-label bottom">Learn at your pace</span></div>
    </div></section>
    <section className="stats-band"><div className="wrap stats-grid">
      <div className="stat"><span className="stat-number">{data.activeStudentCount.toLocaleString('en-BD')}</span><span className="stat-label">active learners<br />on the platform</span></div>
      <div className="stat"><span className="stat-number">{data.publishedCourseCount.toLocaleString('en-BD')}</span><span className="stat-label">published courses<br />ready to explore</span></div>
      <div className="stat"><span className="stat-number">{data.teacherCount.toLocaleString('en-BD')}</span><span className="stat-label">teachers sharing<br />what they know</span></div>
    </div></section>
    <section className="section"><div className="wrap">
      <div className="section-head"><div><div className="eyebrow">Choose your starting point</div><h2>Every class has a next step.</h2></div><p>Browse the class pathways and find learning made for where you are right now.</p></div>
      {data.classes.length ? <div className="class-grid">{data.classes.slice(0,8).map((c,i)=><Link className="class-tile" href={`/courses?class=${encodeURIComponent(c.slug)}`} key={c.id}><span className="class-number">LEVEL {String(i+1).padStart(2,'0')}</span><div><h3>{c.name}</h3><p>{c.publishedCourseCount} published {c.publishedCourseCount===1?'course':'courses'}</p></div><span className="tile-arrow">Explore this class <span>↗</span></span></Link>)}</div> : <div className="empty-state"><div className="state-mark">↗</div><h3>Class pathways are being prepared</h3><p>Published class levels will appear here when they are available.</p></div>}
    </div></section>
    <section className="section" style={{ paddingTop:0 }}><div className="wrap">
      <div className="section-head"><div><div className="eyebrow">A good place to begin</div><h2>Featured learning</h2></div><Link className="button button-quiet" href="/courses">See all courses <ArrowRight size={16} /></Link></div>
      {data.featuredCourses.length ? <div className="course-grid">{data.featuredCourses.slice(0,3).map(c=><CourseCard key={c.id} course={c} />)}</div> : <div className="empty-state"><div className="state-mark"><FlaskConical size={18} /></div><h3>No featured courses just yet</h3><p>Explore the full catalog to see what is currently published.</p><Link className="button button-light" href="/courses">Browse courses</Link></div>}
    </div></section>
    <section className="section value-section"><div className="wrap value-inner"><div><div className="eyebrow">A classroom with room to ask</div><h2>Learn the why,<br />not just the answer.</h2><p>Lessons are built around understanding—so students can connect ideas, practise with purpose and feel ready for what comes next.</p><Link className="button button-light" href="/courses">Find a course <ArrowRight size={16} /></Link></div>
      <div className="value-list"><div className="value-item"><span className="value-index">01</span><div><strong>Clear explanations</strong><span>Take difficult ideas one step at a time, in a way that makes sense.</span></div></div><div className="value-item"><span className="value-index">02</span><div><strong>Made for school learning</strong><span>Find courses aligned with the class level you are studying now.</span></div></div><div className="value-item"><span className="value-index">03</span><div><strong>Learn with confidence</strong><span>Build understanding at a pace that leaves space for questions.</span></div></div></div>
    </div></section>
    <section className="cta-strip"><div className="wrap cta-inner"><div><h2>Ready to find your next lesson?</h2><p>Browse published courses and choose the one that fits.</p></div><Link className="button button-primary" href="/courses">Browse courses <ArrowRight size={16} /></Link></div></section>
  </main>;
}
