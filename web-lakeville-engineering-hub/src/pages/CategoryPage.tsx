import { Navigate, useParams } from "react-router-dom";
import { Info } from "lucide-react";

import { PageHeader } from "@/components/PageHeader";
import { ResourceRow } from "@/components/ResourceRow";
import { categoryByID } from "@/data/hub-content";
import { useHubStore } from "@/lib/hub-store";

export default function CategoryPage() {
  const { categoryID } = useParams<{ categoryID: string }>();
  const category = categoryByID(categoryID);
  const { hasURL } = useHubStore();

  if (!category) return <Navigate to="/" replace />;

  const webLinks = category.sections
    .flatMap((section) => section.links)
    .filter((link) => link.action.kind === "web");
  const missing = webLinks.filter((link) => !hasURL(link)).length;

  return (
    <>
      <PageHeader eyebrow="Resources" title={category.title} summary={category.summary} />

      <div className="mx-auto max-w-4xl space-y-5 px-5 py-6 sm:px-8">
        {missing > 0 ? (
          <div className="flex items-start gap-2.5 rounded-lg border border-border bg-card px-4 py-3">
            <Info className="mt-0.5 h-4 w-4 shrink-0 text-steel" />
            <p className="text-xs leading-relaxed text-ink-secondary">
              <span className="font-semibold text-ink">
                {missing} of {webLinks.length} rows
              </span>{" "}
              don't have a destination yet. Hover a row and choose the pencil to set one, or
              paste your whole department list at once in Settings.
            </p>
          </div>
        ) : null}

        {category.sections.map((section) => (
          <section key={section.id} className="civic-card overflow-hidden">
            <header className="border-b border-border px-4 py-3">
              <h2 className="text-sm font-semibold text-ink">{section.title}</h2>
              {section.footnote ? (
                <p className="mt-0.5 text-xs text-ink-secondary">{section.footnote}</p>
              ) : null}
            </header>
            <div className="space-y-0.5 p-2">
              {section.links.map((link) => (
                <ResourceRow key={link.id} link={link} />
              ))}
            </div>
          </section>
        ))}
      </div>
    </>
  );
}
