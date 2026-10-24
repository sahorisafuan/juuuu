'use client';

import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { CourseCatalog } from '../ui/catalog';

function CoursesContent() {
  const searchParams = useSearchParams();
  const classSlug = searchParams.get('class') || undefined;
  return <main className="wrap">
    <section className="page-hero"><div className="eyebrow">Published learning</div><h1>Courses for curious minds.</h1><p>Search the catalog, explore subjects and find a course for the class you are in.</p></section>
    <CourseCatalog classSlug={classSlug} />
  </main>;
}

export default function CoursesPage() {
  return <Suspense fallback={<main className="wrap"><section className="page-hero"><div className="skeleton" style={{ width:150,height:12 }} /><div className="skeleton" style={{ width:'70%',height:58,marginTop:18 }} /></section><div className="loading-state">Loading the course catalog…</div></main>}><CoursesContent /></Suspense>;
}
