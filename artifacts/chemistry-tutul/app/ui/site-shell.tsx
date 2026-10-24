'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import { BookOpen, GraduationCap, Menu, X } from 'lucide-react';

const links = [
  { href: '/', label: 'Home' },
  { href: '/courses', label: 'Courses' },
  { href: '/classes', label: 'Classes' },
  { href: '/pricing', label: 'Fees' },
];

export function SiteHeader() {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  return <header className="site-header">
    <div className="wrap header-inner">
      <Link href="/" className="brand" aria-label="Chemistry Tutul home" onClick={() => setOpen(false)}>
        <span className="brand-mark">Ct</span>
        <span className="brand-copy"><span className="brand-name">Chemistry Tutul</span><span className="brand-caption">Learn with understanding</span></span>
      </Link>
      <nav className="nav-links" aria-label="Main navigation">
        {links.map(link => <Link href={link.href} key={link.href} aria-current={pathname === link.href || (link.href !== '/' && pathname.startsWith(link.href)) ? 'page' : undefined}>{link.label}</Link>)}
      </nav>
      <div className="header-actions"><Link className="button button-quiet sign-in-link" href="/sign-in">Sign in</Link><Link className="button button-primary" href="/sign-up">Join the classroom <span className="icon-arrow">↗</span></Link>
        <button className="mobile-menu" type="button" aria-label={open ? 'Close navigation menu' : 'Open navigation menu'} aria-expanded={open} onClick={() => setOpen(!open)}>{open ? <X size={19} /> : <Menu size={19} />}</button>
      </div>
      {open && <nav className="mobile-nav" aria-label="Mobile navigation">{links.map(link => <Link href={link.href} key={link.href} onClick={() => setOpen(false)} aria-current={pathname === link.href ? 'page' : undefined}>{link.label}</Link>)}<Link href="/sign-in" onClick={() => setOpen(false)}>Sign in</Link><Link href="/sign-up" onClick={() => setOpen(false)}>Create student account</Link></nav>}
    </div>
  </header>;
}

export function SiteFooter() {
  return <>
    <nav className="mobile-bottom-nav" aria-label="Quick navigation">
      <Link href="/courses"><BookOpen /><span>Courses</span></Link>
      <Link href="/classes"><GraduationCap /><span>Classes</span></Link>
      <Link href="/pricing"><span style={{ fontWeight: 800, fontSize: 17 }}>৳</span><span>Fees</span></Link>
    </nav>
    <footer className="footer">
      <div className="wrap">
        <div className="footer-top">
          <div><Link href="/" className="brand"><span className="brand-mark">Ct</span><span className="brand-copy"><span className="brand-name">Chemistry Tutul</span><span className="brand-caption">Learn with understanding</span></span></Link><p className="footer-about">A thoughtful learning space for school students and the families cheering them on.</p></div>
          <div className="footer-nav">
            <div className="footer-col"><strong>Explore</strong><Link href="/courses">All courses</Link><Link href="/classes">Class pathways</Link><Link href="/pricing">Fees</Link></div>
            <div className="footer-col"><strong>Start here</strong><Link href="/courses">Find a course</Link><Link href="/classes">Choose your class</Link></div>
          </div>
        </div>
        <div className="footer-bottom"><span>© {new Date().getFullYear()} Chemistry Tutul</span><span>Made for curious minds in Bangladesh</span></div>
      </div>
    </footer>
  </>;
}
