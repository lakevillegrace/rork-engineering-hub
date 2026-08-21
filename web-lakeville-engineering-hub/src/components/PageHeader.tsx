import type { ReactNode } from "react";

/** Shared page masthead: eyebrow, title, one-line summary, optional actions. */
export function PageHeader({
  eyebrow,
  title,
  summary,
  actions,
}: {
  eyebrow?: string;
  title: string;
  summary?: string;
  actions?: ReactNode;
}) {
  return (
    <div className="border-b border-border bg-navy px-5 py-6 sm:px-8">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="min-w-0">
          {eyebrow ? (
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-amber">
              {eyebrow}
            </p>
          ) : null}
          <h1 className="mt-1 text-2xl font-semibold text-white sm:text-[28px]">{title}</h1>
          {summary ? (
            <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-white/70">{summary}</p>
          ) : null}
        </div>
        {actions ? <div className="flex shrink-0 items-center gap-2">{actions}</div> : null}
      </div>
    </div>
  );
}
