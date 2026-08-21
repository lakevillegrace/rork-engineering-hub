import { useMemo, useRef, useState } from "react";
import {
  CheckCircle2,
  Download,
  ExternalLink,
  Plus,
  RotateCcw,
  Trash2,
  Upload,
} from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/PageHeader";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { DAKOTA_MUNICIPALITIES, engineeringURL } from "@/data/cities";
import { ALL_LINKS, type ResourceLink } from "@/data/hub-content";
import type { LiveSource } from "@/data/live-sources";
import {
  importSummaryMessage,
  useHubStore,
  type HubConfiguration,
} from "@/lib/hub-store";
import { BOUNDARY_RETRIEVED, BOUNDARY_SOURCE_NOTE } from "@/lib/boundaries";

/** Loose title match so "ROW OneStop" finds the "ROW OneStop" row. */
function normalize(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

/** Splits "Title | URL", "Title - URL", "Title<tab>URL" or a bare URL. */
function splitLine(line: string): { label: string; url: string } | null {
  for (const separator of ["|", "\t", " — ", " – ", " - "]) {
    const index = line.indexOf(separator);
    if (index === -1) continue;
    const label = line.slice(0, index).trim();
    const url = line.slice(index + separator.length).trim();
    if (label.length > 0 && url.length > 0) return { label, url };
  }
  if (line.toLowerCase().startsWith("http")) return { label: line, url: line };
  return null;
}

interface ParsedEntry {
  label: string;
  url: string;
  match: ResourceLink | null;
}

function BulkLinkImportDialog({
  isOpen,
  onOpenChange,
}: {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { setURL } = useHubStore();
  const [pasted, setPasted] = useState("");

  const entries = useMemo<ParsedEntry[]>(() => {
    return pasted
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .flatMap((line) => {
        const parts = splitLine(line);
        if (!parts) return [];
        const needle = normalize(parts.label);
        const exact = ALL_LINKS.find((link) => normalize(link.title) === needle);
        const loose =
          exact ??
          ALL_LINKS.find((link) => {
            const title = normalize(link.title);
            return title.includes(needle) || needle.includes(title);
          });
        return [{ label: parts.label, url: parts.url, match: loose ?? null }];
      });
  }, [pasted]);

  const matched = entries.filter((entry) => entry.match !== null);
  const unmatched = entries.filter((entry) => entry.match === null);

  function apply() {
    for (const entry of matched) {
      if (entry.match) setURL(entry.url, entry.match);
    }
    toast.success(
      `${matched.length} row${matched.length === 1 ? "" : "s"} now open the destination you pasted.`,
    );
    setPasted("");
    onOpenChange(false);
  }

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Paste a list of links</DialogTitle>
          <DialogDescription>
            One per line as <span className="font-mono text-xs">Name | URL</span>. Names are
            matched to rows already in the hub, so each row opens the real destination instead
            of a SharePoint page.
          </DialogDescription>
        </DialogHeader>

        <Textarea
          value={pasted}
          onChange={(event) => setPasted(event.target.value)}
          rows={7}
          className="font-mono text-xs"
          placeholder={"ROW OneStop | https://example.gov/onestop\nAs-Built Plans | https://example.gov/asbuilts.pdf"}
        />

        {matched.length > 0 ? (
          <div className="max-h-40 overflow-y-auto rounded-lg border border-border">
            <p className="border-b border-border bg-secondary/60 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-ink-secondary">
              Will update {matched.length}
            </p>
            <ul className="divide-y divide-border">
              {matched.map((entry) => (
                <li key={`${entry.label}-${entry.url}`} className="flex items-start gap-2 px-3 py-2">
                  <CheckCircle2 className="mt-0.5 h-3.5 w-3.5 shrink-0 text-ok" />
                  <div className="min-w-0">
                    <p className="truncate text-xs font-medium text-ink">{entry.match?.title}</p>
                    <p className="truncate font-mono text-[11px] text-ink-secondary">{entry.url}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        ) : null}

        {unmatched.length > 0 ? (
          <div className="max-h-32 overflow-y-auto rounded-lg border border-amber/40 bg-amber/5">
            <p className="border-b border-amber/30 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-[#8A5A0B]">
              No matching row ({unmatched.length})
            </p>
            <ul className="divide-y divide-amber/20">
              {unmatched.map((entry) => (
                <li key={`${entry.label}-${entry.url}`} className="px-3 py-2">
                  <p className="truncate text-xs text-ink">{entry.label}</p>
                </li>
              ))}
            </ul>
          </div>
        ) : null}

        <DialogFooter>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={apply} disabled={matched.length === 0}>
            Apply {matched.length > 0 ? matched.length : ""}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function AddSourceDialog({
  isOpen,
  onOpenChange,
}: {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { addCustomSource } = useHubStore();
  const [title, setTitle] = useState("");
  const [layerURL, setLayerURL] = useState("");
  const [titleField, setTitleField] = useState("");

  function save() {
    if (title.trim().length === 0 || layerURL.trim().length === 0) {
      toast.error("A title and layer address are required.");
      return;
    }
    const source: LiveSource = {
      id: `custom-${Date.now()}`,
      title: title.trim(),
      category: "closure",
      layerURL: layerURL.trim(),
      whereClause: "1=1",
      titleField: titleField.trim().length > 0 ? titleField.trim() : "NAME",
      isBuiltIn: false,
      isEnabled: true,
    };
    addCustomSource(source);
    setTitle("");
    setLayerURL("");
    setTitleField("");
    onOpenChange(false);
    toast.success("Layer added");
  }

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add a GIS layer</DialogTitle>
          <DialogDescription>
            Point the hub at any public ArcGIS feature or map service layer. The layer must
            allow browser requests (most Esri-hosted services do).
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-1.5">
            <Label htmlFor="source-title">Title</Label>
            <Input
              id="source-title"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="Lakeville Street Closures"
            />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="source-url">Layer address</Label>
            <Input
              id="source-url"
              value={layerURL}
              onChange={(event) => setLayerURL(event.target.value)}
              placeholder="https://services.arcgis.com/…/FeatureServer/0"
              className="font-mono text-xs"
            />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="source-field">Title field</Label>
            <Input
              id="source-field"
              value={titleField}
              onChange={(event) => setTitleField(event.target.value)}
              placeholder="ROADNAME"
              className="font-mono text-xs"
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={save}>Add layer</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function SettingsPage() {
  const {
    city,
    cityName,
    setCityID,
    allSources,
    isSourceEnabled,
    setSourceEnabled,
    removeCustomSource,
    configuredLinkCount,
    exportConfiguration,
    importConfiguration,
    resetEverything,
  } = useHubStore();

  const [isPasting, setIsPasting] = useState(false);
  const [isAddingSource, setIsAddingSource] = useState(false);
  const fileInput = useRef<HTMLInputElement>(null);

  function download() {
    const config = exportConfiguration();
    const blob = new Blob([JSON.stringify(config, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    const slug = cityName.toLowerCase().replace(/\s+/g, "-");
    anchor.href = url;
    anchor.download = `${slug}-engineering-hub-${new Date().toISOString().slice(0, 10)}.json`;
    anchor.click();
    URL.revokeObjectURL(url);
    toast.success("Configuration exported");
  }

  async function handleFile(file: File) {
    try {
      const parsed = JSON.parse(await file.text()) as HubConfiguration;
      if (typeof parsed.formatVersion !== "number") {
        toast.error("That file isn't a valid Engineering Hub configuration.");
        return;
      }
      if (parsed.formatVersion > 1) {
        toast.error(`That file was made by a newer version (format ${parsed.formatVersion}).`);
        return;
      }
      toast.success(importSummaryMessage(importConfiguration(parsed)));
    } catch (error) {
      console.error("Configuration import failed", error);
      toast.error("Couldn't read that file.");
    }
  }

  const engineering = engineeringURL(city);

  return (
    <>
      <PageHeader
        eyebrow="Setup"
        title="Settings"
        summary="Choose the municipality, wire up destinations, and share the whole setup with the rest of the department."
      />

      <div className="mx-auto max-w-3xl space-y-5 px-5 py-6 sm:px-8">
        <section className="civic-card overflow-hidden">
          <header className="border-b border-border px-4 py-3">
            <h2 className="text-sm font-semibold text-ink">Your city</h2>
          </header>
          <div className="space-y-3 p-4">
            <div className="grid gap-1.5">
              <Label>Municipality</Label>
              <Select value={city?.id ?? ""} onValueChange={setCityID}>
                <SelectTrigger>
                  <SelectValue placeholder="Choose a municipality" />
                </SelectTrigger>
                <SelectContent className="max-h-72">
                  {DAKOTA_MUNICIPALITIES.map((option) => (
                    <SelectItem key={option.id} value={option.id}>
                      {option.displayName}
                      {option.hasCuratedContent ? " · curated" : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <p className="text-xs leading-relaxed text-ink-secondary">
              Live conditions, jurisdiction filters and distance sorting all follow this choice.
            </p>
            {engineering ? (
              <a
                href={engineering}
                target="_blank"
                rel="noreferrer noopener"
                className="inline-flex items-center gap-1.5 text-xs font-medium text-navy hover:underline"
              >
                Open {cityName} Engineering
                <ExternalLink className="h-3 w-3" />
              </a>
            ) : null}
          </div>
        </section>

        <section className="civic-card overflow-hidden">
          <header className="border-b border-border px-4 py-3">
            <h2 className="text-sm font-semibold text-ink">Links & sharing</h2>
          </header>
          <div className="space-y-3 p-4">
            <div className="flex flex-wrap gap-2">
              <Button onClick={() => setIsPasting(true)} className="bg-navy hover:bg-navy-deep">
                <Upload className="mr-2 h-4 w-4" />
                Paste a list of links
              </Button>
              <Button variant="outline" onClick={download} disabled={configuredLinkCount === 0}>
                <Download className="mr-2 h-4 w-4" />
                Export configuration
              </Button>
              <Button variant="outline" onClick={() => fileInput.current?.click()}>
                <Upload className="mr-2 h-4 w-4" />
                Import file
              </Button>
              <input
                ref={fileInput}
                type="file"
                accept="application/json,.json"
                className="hidden"
                onChange={(event) => {
                  const file = event.target.files?.[0];
                  if (file) void handleFile(file);
                  event.target.value = "";
                }}
              />
            </div>
            <p className="text-xs leading-relaxed text-ink-secondary">
              <span className="tabular font-semibold text-ink">{configuredLinkCount}</span> link
              {configuredLinkCount === 1 ? "" : "s"} saved. Exports use the same format as the
              iPhone app, so a file made on either one imports into the other.
            </p>
          </div>
        </section>

        <section className="civic-card overflow-hidden">
          <header className="flex items-center justify-between border-b border-border px-4 py-3">
            <h2 className="text-sm font-semibold text-ink">Live data sources</h2>
            <Button variant="ghost" size="sm" onClick={() => setIsAddingSource(true)}>
              <Plus className="mr-1.5 h-3.5 w-3.5" />
              Add layer
            </Button>
          </header>
          <ul className="divide-y divide-border">
            {allSources.map((source) => (
              <li key={source.id} className="flex items-center gap-3 px-4 py-3">
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="truncate text-sm font-medium text-ink">{source.title}</p>
                    <StatusChip
                      label={source.isBuiltIn ? "Built in" : "Custom"}
                      tone={source.isBuiltIn ? "navy" : "steel"}
                    />
                  </div>
                  <p className="mt-0.5 truncate font-mono text-[11px] text-ink-secondary">
                    {source.layerURL.replace(/^https:\/\//, "")}
                  </p>
                </div>
                {!source.isBuiltIn ? (
                  <button
                    type="button"
                    onClick={() => removeCustomSource(source.id)}
                    className="rounded-md p-1.5 text-ink-secondary hover:bg-destructive/10 hover:text-destructive"
                    aria-label={`Remove ${source.title}`}
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                ) : null}
                <Switch
                  checked={isSourceEnabled(source)}
                  onCheckedChange={(checked) => setSourceEnabled(source, checked)}
                  aria-label={`Toggle ${source.title}`}
                />
              </li>
            ))}
          </ul>
          <p className="border-t border-border px-4 py-3 text-[11px] leading-relaxed text-ink-secondary">
            Dakota County GIS and MnDOT's 511 service both allow direct browser requests, so
            live data loads without going through any middleman. City RSS feeds are fetched by
            this project's own server because the city's web host doesn't permit browser access.
          </p>
        </section>

        <section className="civic-card overflow-hidden">
          <header className="border-b border-border px-4 py-3">
            <h2 className="text-sm font-semibold text-ink">About</h2>
          </header>
          <div className="space-y-2 p-4 text-xs leading-relaxed text-ink-secondary">
            <p>{BOUNDARY_SOURCE_NOTE}</p>
            <p>Boundary geometry retrieved {BOUNDARY_RETRIEVED}.</p>
            <p>
              Internal tool for City of Lakeville Engineering staff. Live data is read-only and
              comes straight from the publishing agency.
            </p>
            <Button
              variant="outline"
              size="sm"
              className="mt-2 text-destructive hover:bg-destructive/10"
              onClick={() => {
                resetEverything();
                toast.success("Everything reset to defaults");
              }}
            >
              <RotateCcw className="mr-2 h-3.5 w-3.5" />
              Reset this browser
            </Button>
          </div>
        </section>
      </div>

      <BulkLinkImportDialog isOpen={isPasting} onOpenChange={setIsPasting} />
      <AddSourceDialog isOpen={isAddingSource} onOpenChange={setIsAddingSource} />
    </>
  );
}
