'use client';

import Link from 'next/link';
import { useMemo, useState, type ReactNode } from 'react';
import { Search, ArrowUpRight, RotateCw } from 'lucide-react';
import {
  getGetPublicCategoriesQueryKey, getGetPublicClassesQueryKey, getGetPublicCoursesQueryKey,
  useGetPublicCategories, useGetPublicClasses, useGetPublicCourses,
} from '@workspace/api-client-react';
import type { PublicCourseSummary } from '@workspace/api-client-react';

export function formatFee(poisha: number) {
  const taka = poisha / 100;
  return new Intl.NumberFormat('en-BD', { style: 'currency', currency: 'BDT', maximumFractionDigits: taka % 1 === 0 ? 0 : 2 }).format(taka);
}

export function CourseCard({ course }: { course: PublicCourseSummary }) {
  return <Link className="course-card" href={`/courses/${encodeURIComponent(course.slug)}`}>
    <div className="course-cover">{course.coverImageUrl ? <img src={course.coverImageUrl} alt="" /> : <span className="cover-glyph">Ct</span>}</div>
    <div className="course-body">
      <div className="course-meta"><span>{course.className || 'School course'}</span><span className="meta-sep" /><span>{course.categoryName || 'Learning'}</span></div>
      <h3>{course.title}</h3><p>{course.summary}</p>
      <div className="course-foot"><span className="teacher">{course.instructorName || 'Chemistry Tutul'}</span><span className="price">{course.monthlyFeePoisha > 0 ? `${formatFee(course.monthlyFeePoisha)} / month` : course.oneTimeFeePoisha > 0 ? formatFee(course.oneTimeFeePoisha) : 'See course'}</span></div>
    </div>
  </Link>;
}

export function CourseGrid({ courses, isLoading, isError, onRetry, emptyTitle = 'No courses to show yet', emptyText = 'Published courses will appear here when they are ready.' }: {
  courses?: PublicCourseSummary[]; isLoading: boolean; isError: boolean; onRetry: () => void; emptyTitle?: string; emptyText?: string;
}) {
  if (isLoading) return <div className="course-grid" aria-label="Loading courses">{[1,2,3].map(n => <div className="course-card" key={n}><div className="skeleton" style={{ height:145, borderRadius:0 }} /><div style={{ padding:20 }}><div className="skeleton" style={{ height:12, width:'42%', marginBottom:16 }} /><div className="skeleton" style={{ height:23, width:'75%', marginBottom:12 }} /><div className="skeleton" style={{ height:36 }} /></div></div>)}</div>;
  if (isError) return <div className="error-state"><div className="state-mark"><RotateCw size={18} /></div><h3>We couldn’t load the courses</h3><p>Please check your connection and try again.</p><button className="button button-light" onClick={onRetry}>Try again</button></div>;
  if (!courses?.length) return <div className="empty-state"><div className="state-mark">↗</div><h3>{emptyTitle}</h3><p>{emptyText}</p></div>;
  return <div className="course-grid">{courses.map(course => <CourseCard key={course.id} course={course} />)}</div>;
}

export function CourseCatalog({ initialSearch = '', classSlug }: { initialSearch?: string; classSlug?: string }) {
  const [search, setSearch] = useState(initialSearch);
  const [categorySlug, setCategorySlug] = useState('');
  const [selectedClass, setSelectedClass] = useState(classSlug || '');
  const params = useMemo(() => ({
    ...(selectedClass ? { classSlug: selectedClass } : {}),
    ...(categorySlug ? { categorySlug } : {}),
    ...(search.trim() ? { search: search.trim() } : {}),
  }), [selectedClass, categorySlug, search]);
  const categoriesQuery = useGetPublicCategories({ query: { queryKey: getGetPublicCategoriesQueryKey() } });
  const classesQuery = useGetPublicClasses({ query: { queryKey: getGetPublicClassesQueryKey() } });
  const coursesQuery = useGetPublicCourses(params, { query: { queryKey: getGetPublicCoursesQueryKey(params) } });
  return <section className="catalog-layout">
    <div className="filter-bar">
      <label className="field-wrap"><Search size={17} aria-hidden="true" /><input className="field" type="search" placeholder="Search by subject or course name" aria-label="Search courses" value={search} onChange={e => setSearch(e.target.value)} /></label>
      <select className="select" aria-label="Filter by category" value={categorySlug} onChange={e => setCategorySlug(e.target.value)}><option value="">All subjects</option>{categoriesQuery.data?.map(c => <option key={c.id} value={c.slug}>{c.name}</option>)}</select>
      <select className="select" aria-label="Filter by class" value={selectedClass} onChange={e => setSelectedClass(e.target.value)}><option value="">All classes</option>{classesQuery.data?.map(c => <option key={c.id} value={c.slug}>{c.name}</option>)}</select>
    </div>
    <p className="catalog-count">{coursesQuery.data?.length ?? 0} published {coursesQuery.data?.length === 1 ? 'course' : 'courses'}</p>
    <CourseGrid courses={coursesQuery.data} isLoading={coursesQuery.isLoading} isError={coursesQuery.isError} onRetry={() => void coursesQuery.refetch()} />
  </section>;
}

export function CourseLink({ href, children }: { href: string; children: ReactNode }) {
  return <Link className="button button-quiet" href={href}>{children}<ArrowUpRight size={16} /></Link>;
}
