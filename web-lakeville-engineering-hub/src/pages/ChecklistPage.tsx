import { Navigate, useParams } from "react-router-dom";
import { RotateCcw } from "lucide-react";

import { PageHeader } from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { checklistByID } from "@/data/hub-content";
import { useHubStore } from "@/lib/hub-store";
import { cn } from "@/lib/utils";

export default function ChecklistPage() {
  const { checklistID } = useParams<{ checklistID: string }>();
  const checklist = checklistByID(checklistID);
  const { isStepComplete, toggleStep, resetChecklist, completedCount } = useHubStore();

  if (!checklist) return <Navigate to="/" replace />;

  const done = completedCount(checklist.id);
  const total = checklist.steps.length;
  const progress = total === 0 ? 0 : Math.round((done / total) * 100);

  return (
    <>
      <PageHeader
        eyebrow="Review steps"
        title={checklist.title}
        summary={`${done} of ${total} complete. Progress is kept in this browser so you can pick a review back up later.`}
        actions={
          <Button
            variant="secondary"
            size="sm"
            onClick={() => resetChecklist(checklist.id)}
            className="bg-white/10 text-white hover:bg-white/20"
          >
            <RotateCcw className="mr-2 h-3.5 w-3.5" />
            Reset
          </Button>
        }
      />

      <div className="mx-auto max-w-2xl space-y-4 px-5 py-6 sm:px-8">
        <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
          <div
            className="h-full rounded-full bg-amber transition-[width] duration-500 ease-out"
            style={{ width: `${progress}%` }}
          />
        </div>

        <ol className="civic-card divide-y divide-border overflow-hidden">
          {checklist.steps.map((step, index) => {
            const complete = isStepComplete(checklist.id, step);
            return (
              <li key={step}>
                <label className="flex cursor-pointer items-center gap-3 px-4 py-3.5 transition-colors hover:bg-secondary/50">
                  <Checkbox
                    checked={complete}
                    onCheckedChange={() => toggleStep(checklist.id, step)}
                  />
                  <span className="tabular w-5 text-xs font-medium text-ink-secondary">
                    {index + 1}
                  </span>
                  <span
                    className={cn(
                      "flex-1 text-sm transition-colors",
                      complete ? "text-ink-secondary line-through" : "text-ink",
                    )}
                  >
                    {step}
                  </span>
                </label>
              </li>
            );
          })}
        </ol>
      </div>
    </>
  );
}
