import { cn } from "@/lib/utils";

export type ChipTone = "neutral" | "navy" | "amber" | "danger" | "ok" | "steel";

const TONES: Record<ChipTone, string> = {
  neutral: "bg-secondary text-ink-secondary",
  navy: "bg-navy/10 text-navy",
  amber: "bg-amber/18 text-[#8A5A0B]",
  danger: "bg-destructive/12 text-destructive",
  ok: "bg-ok/12 text-ok",
  steel: "bg-steel/14 text-[#28618C]",
};

export function StatusChip({
  label,
  tone = "neutral",
  className,
}: {
  label: string;
  tone?: ChipTone;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold leading-tight",
        TONES[tone],
        className,
      )}
    >
      {label}
    </span>
  );
}
