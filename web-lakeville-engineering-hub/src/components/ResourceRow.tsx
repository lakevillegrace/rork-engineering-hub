import { useState } from "react";
import { Link } from "react-router-dom";
import { ExternalLink, Pencil, Pin, PinOff } from "lucide-react";
import { toast } from "sonner";

import { ResourceIcon } from "@/components/ResourceIcon";
import { StatusChip } from "@/components/StatusChip";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useHubStore } from "@/lib/hub-store";
import type { ResourceLink } from "@/data/hub-content";
import { cn } from "@/lib/utils";

function LinkEditorDialog({
  link,
  isOpen,
  onOpenChange,
}: {
  link: ResourceLink;
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { resourceURLs, setURL } = useHubStore();
  const [draft, setDraft] = useState(resourceURLs[link.id] ?? "");

  const save = () => {
    setURL(draft, link);
    onOpenChange(false);
    toast.success(draft.trim().length > 0 ? "Link saved" : "Link cleared");
  };

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{link.title}</DialogTitle>
          <DialogDescription>
            Paste the real destination for this row. Staff who import your configuration get
            the same address.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor={`url-${link.id}`}>Destination</Label>
          <Input
            id={`url-${link.id}`}
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            placeholder="https://…"
            autoFocus
            onKeyDown={(event) => {
              if (event.key === "Enter") save();
            }}
          />
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={save}>Save</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

/**
 * One actionable row. Web rows open their configured destination; phone, email
 * and in-app routes act without any setup.
 */
export function ResourceRow({ link }: { link: ResourceLink }) {
  const { urlFor, isPinned, togglePin } = useHubStore();
  const [isEditing, setIsEditing] = useState(false);

  const url = urlFor(link);
  const pinned = isPinned(link);

  const body = (
    <>
      <span
        className={cn(
          "flex h-9 w-9 shrink-0 items-center justify-center rounded-lg",
          url || link.action.kind !== "web"
            ? "bg-navy/8 text-navy"
            : "bg-secondary text-ink-secondary",
        )}
      >
        <ResourceIcon name={link.icon} className="h-[18px] w-[18px]" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="flex flex-wrap items-center gap-2">
          <span className="truncate text-sm font-medium text-ink">{link.title}</span>
          {link.action.kind === "web" && !url ? (
            <StatusChip label="Needs link" tone="amber" />
          ) : null}
          {link.action.kind === "route" ? <StatusChip label="In app" tone="steel" /> : null}
        </span>
        {link.detail ? (
          <span className="mt-0.5 block truncate text-xs text-ink-secondary">{link.detail}</span>
        ) : null}
      </span>
    </>
  );

  const rowClass =
    "flex flex-1 items-center gap-3 rounded-lg px-2.5 py-2 text-left transition-colors hover:bg-secondary/70";

  function renderAction() {
    if (link.action.kind === "route" && link.action.value) {
      return (
        <Link to={link.action.value} className={rowClass}>
          {body}
        </Link>
      );
    }
    if (link.action.kind === "phone" && link.action.value) {
      return (
        <a href={`tel:${link.action.value}`} className={rowClass}>
          {body}
        </a>
      );
    }
    if (link.action.kind === "email" && link.action.value) {
      return (
        <a href={`mailto:${link.action.value}`} className={rowClass}>
          {body}
        </a>
      );
    }
    if (url) {
      return (
        <a href={url} target="_blank" rel="noreferrer noopener" className={rowClass}>
          {body}
          <ExternalLink className="h-3.5 w-3.5 shrink-0 text-ink-secondary" aria-hidden="true" />
        </a>
      );
    }
    return (
      <button type="button" onClick={() => setIsEditing(true)} className={rowClass}>
        {body}
      </button>
    );
  }

  return (
    <div className="group flex items-center gap-1">
      {renderAction()}

      <div className="flex shrink-0 items-center opacity-0 transition-opacity focus-within:opacity-100 group-hover:opacity-100">
        <button
          type="button"
          onClick={() => togglePin(link)}
          className="rounded-md p-1.5 text-ink-secondary hover:bg-secondary hover:text-navy"
          aria-label={pinned ? `Unpin ${link.title}` : `Pin ${link.title}`}
          title={pinned ? "Unpin" : "Pin to dashboard"}
        >
          {pinned ? <PinOff className="h-3.5 w-3.5" /> : <Pin className="h-3.5 w-3.5" />}
        </button>
        {link.action.kind === "web" ? (
          <button
            type="button"
            onClick={() => setIsEditing(true)}
            className="rounded-md p-1.5 text-ink-secondary hover:bg-secondary hover:text-navy"
            aria-label={`Edit link for ${link.title}`}
            title="Edit link"
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
        ) : null}
      </div>

      {pinned ? (
        <span className="pointer-events-none absolute" aria-hidden="true" />
      ) : null}

      <LinkEditorDialog link={link} isOpen={isEditing} onOpenChange={setIsEditing} />
    </div>
  );
}
