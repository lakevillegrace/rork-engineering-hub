import { useMemo, useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/PageHeader";
import { StatusChip, type ChipTone } from "@/components/StatusChip";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import {
  OPEN_PERMIT_STATUSES,
  PERMIT_INBOXES,
  PERMIT_INBOX_TITLE,
  PERMIT_STATUSES,
  PERMIT_STATUS_TITLE,
  type PermitInbox,
  type PermitStatus,
} from "@/data/hub-content";
import { useHubStore } from "@/lib/hub-store";
import { cn } from "@/lib/utils";

const STATUS_TONE: Record<PermitStatus, ChipTone> = {
  underReview: "steel",
  awaitingApplicant: "amber",
  awaitingRestoration: "amber",
  pendingPickup: "navy",
  approved: "ok",
  closed: "neutral",
};

function AddPermitDialog({
  isOpen,
  onOpenChange,
  defaultInbox,
}: {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  defaultInbox: PermitInbox;
}) {
  const { addPermit } = useHubStore();
  const [number, setNumber] = useState("");
  const [applicant, setApplicant] = useState("");
  const [inbox, setInbox] = useState<PermitInbox>(defaultInbox);
  const [status, setStatus] = useState<PermitStatus>("underReview");
  const [note, setNote] = useState("");

  function save() {
    if (number.trim().length === 0 || applicant.trim().length === 0) {
      toast.error("Permit number and applicant are required.");
      return;
    }
    addPermit({
      number: number.trim(),
      applicant: applicant.trim(),
      inbox,
      status,
      receivedDate: new Date().toISOString(),
      note: note.trim().length > 0 ? note.trim() : undefined,
    });
    setNumber("");
    setApplicant("");
    setNote("");
    onOpenChange(false);
    toast.success("Permit added");
  }

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Log a permit</DialogTitle>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-1.5">
            <Label htmlFor="permit-number">Permit number</Label>
            <Input
              id="permit-number"
              value={number}
              onChange={(event) => setNumber(event.target.value)}
              placeholder="ROW-2026-0142"
            />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="permit-applicant">Applicant</Label>
            <Input
              id="permit-applicant"
              value={applicant}
              onChange={(event) => setApplicant(event.target.value)}
              placeholder="Xcel Energy"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5">
              <Label>Inbox</Label>
              <Select value={inbox} onValueChange={(value) => setInbox(value as PermitInbox)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PERMIT_INBOXES.map((option) => (
                    <SelectItem key={option} value={option}>
                      {PERMIT_INBOX_TITLE[option]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-1.5">
              <Label>Status</Label>
              <Select value={status} onValueChange={(value) => setStatus(value as PermitStatus)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PERMIT_STATUSES.map((option) => (
                    <SelectItem key={option} value={option}>
                      {PERMIT_STATUS_TITLE[option]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="permit-note">Note</Label>
            <Textarea
              id="permit-note"
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Traffic control plan needs revision."
              rows={2}
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={save}>Add permit</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function Permits() {
  const { permitsIn, openCount, updatePermit, deletePermit } = useHubStore();
  const [inbox, setInbox] = useState<PermitInbox | "all">("all");
  const [isAdding, setIsAdding] = useState(false);

  const rows = useMemo(
    () => permitsIn(inbox === "all" ? null : inbox),
    [permitsIn, inbox],
  );

  const totalOpen = PERMIT_INBOXES.reduce((total, box) => total + openCount(box), 0);

  return (
    <>
      <PageHeader
        eyebrow="ROW · RowM · ENG Survey"
        title="Permit Tracking"
        summary={`${totalOpen} open item${totalOpen === 1 ? "" : "s"} across all three inboxes. Check status here before responding to an applicant.`}
        actions={
          <Button
            size="sm"
            onClick={() => setIsAdding(true)}
            className="bg-amber text-navy-deep hover:bg-amber/90"
          >
            <Plus className="mr-1.5 h-4 w-4" />
            Log permit
          </Button>
        }
      />

      <div className="mx-auto max-w-5xl space-y-4 px-5 py-6 sm:px-8">
        <div className="flex flex-wrap gap-1.5">
          {(["all", ...PERMIT_INBOXES] as (PermitInbox | "all")[]).map((option) => (
            <button
              key={option}
              type="button"
              onClick={() => setInbox(option)}
              className={cn(
                "rounded-full border px-3 py-1.5 text-xs font-semibold transition-colors",
                inbox === option
                  ? "border-navy bg-navy text-white"
                  : "border-border bg-card text-ink-secondary hover:border-navy/40",
              )}
            >
              {option === "all" ? "All inboxes" : PERMIT_INBOX_TITLE[option]}
              {option !== "all" ? (
                <span className="tabular ml-1.5 opacity-70">{openCount(option)}</span>
              ) : null}
            </button>
          ))}
        </div>

        <div className="civic-card overflow-hidden">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-secondary/50">
              <tr className="text-[11px] uppercase tracking-wider text-ink-secondary">
                <th scope="col" className="px-4 py-2.5 font-semibold">Permit</th>
                <th scope="col" className="hidden px-4 py-2.5 font-semibold sm:table-cell">Applicant</th>
                <th scope="col" className="px-4 py-2.5 font-semibold">Status</th>
                <th scope="col" className="hidden px-4 py-2.5 font-semibold md:table-cell">Received</th>
                <th scope="col" className="w-10 px-2 py-2.5" />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-12 text-center text-sm text-ink-secondary">
                    No permits in this inbox.
                  </td>
                </tr>
              ) : (
                rows.map((permit) => {
                  const isOpen = OPEN_PERMIT_STATUSES.includes(permit.status);
                  return (
                    <tr key={permit.id} className="group hover:bg-secondary/40">
                      <td className="px-4 py-3 align-top">
                        <p className="tabular font-mono text-xs font-medium text-ink">
                          {permit.number}
                        </p>
                        <p className="mt-0.5 text-xs text-ink-secondary sm:hidden">
                          {permit.applicant}
                        </p>
                        {permit.note ? (
                          <p className="mt-1 max-w-md text-xs leading-relaxed text-ink-secondary">
                            {permit.note}
                          </p>
                        ) : null}
                      </td>
                      <td className="hidden px-4 py-3 align-top text-ink sm:table-cell">
                        {permit.applicant}
                      </td>
                      <td className="px-4 py-3 align-top">
                        <Select
                          value={permit.status}
                          onValueChange={(value) =>
                            updatePermit({ ...permit, status: value as PermitStatus })
                          }
                        >
                          <SelectTrigger className="h-auto w-auto border-0 bg-transparent p-0 shadow-none focus:ring-0">
                            <StatusChip
                              label={PERMIT_STATUS_TITLE[permit.status]}
                              tone={STATUS_TONE[permit.status]}
                            />
                          </SelectTrigger>
                          <SelectContent>
                            {PERMIT_STATUSES.map((option) => (
                              <SelectItem key={option} value={option}>
                                {PERMIT_STATUS_TITLE[option]}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        {!isOpen ? null : (
                          <span className="mt-1 block text-[11px] text-ink-secondary">open</span>
                        )}
                      </td>
                      <td className="tabular hidden px-4 py-3 align-top text-xs text-ink-secondary md:table-cell">
                        {new Date(permit.receivedDate).toLocaleDateString(undefined, {
                          month: "short",
                          day: "numeric",
                        })}
                      </td>
                      <td className="px-2 py-3 align-top">
                        <button
                          type="button"
                          onClick={() => {
                            deletePermit(permit.id);
                            toast.success(`${permit.number} removed`);
                          }}
                          className="rounded-md p-1.5 text-ink-secondary opacity-0 transition-opacity hover:bg-destructive/10 hover:text-destructive group-hover:opacity-100"
                          aria-label={`Delete ${permit.number}`}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        <p className="text-[11px] leading-relaxed text-ink-secondary">
          Tracking is stored in this browser only. Use Settings → Export configuration to hand
          your setup to a colleague; permit rows stay local to whoever logged them.
        </p>
      </div>

      <AddPermitDialog
        isOpen={isAdding}
        onOpenChange={setIsAdding}
        defaultInbox={inbox === "all" ? "row" : inbox}
      />
    </>
  );
}
