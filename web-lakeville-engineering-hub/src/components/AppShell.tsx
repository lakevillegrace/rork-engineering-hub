import { useMemo, useState } from "react";
import { NavLink, useLocation } from "react-router-dom";
import {
  Building2,
  CarFront,
  FileSearch,
  FolderCog,
  Hammer,
  LayoutDashboard,
  Menu,
  RadioTower,
  Ruler,
  Settings,
  Table2,
  X,
} from "lucide-react";

import { cn } from "@/lib/utils";
import { useHubStore } from "@/lib/hub-store";
import { useLiveFeed } from "@/lib/queries";
import { isInside } from "@/lib/live-ops";

interface NavItem {
  to: string;
  label: string;
  icon: typeof LayoutDashboard;
  /** Small count badge, e.g. open closures in your city. */
  badge?: number;
}

function SidebarLink({ item, onNavigate }: { item: NavItem; onNavigate: () => void }) {
  return (
    <NavLink
      to={item.to}
      end={item.to === "/"}
      onClick={onNavigate}
      className={({ isActive }) =>
        cn(
          "group flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors",
          "text-sidebar-foreground/75 hover:bg-sidebar-accent hover:text-white",
          isActive && "bg-sidebar-accent text-white shadow-[inset_2px_0_0_0_hsl(var(--amber))]",
        )
      }
    >
      <item.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
      <span className="flex-1 truncate">{item.label}</span>
      {item.badge !== undefined && item.badge > 0 ? (
        <span className="tabular rounded-full bg-amber px-1.5 py-0.5 text-[11px] font-semibold text-navy-deep">
          {item.badge}
        </span>
      ) : null}
    </NavLink>
  );
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const { cityName } = useHubStore();
  const { data } = useLiveFeed();
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const closuresInCity = useMemo(() => {
    const items = data?.items ?? [];
    return items.filter(
      (item) => item.category === "closure" && isInside(item, "lakeville"),
    ).length;
  }, [data]);

  const primary: NavItem[] = [
    { to: "/", label: "Dashboard", icon: LayoutDashboard },
    { to: "/live", label: "Live Conditions", icon: RadioTower, badge: closuresInCity },
    { to: "/updates", label: "Agency Updates", icon: Building2 },
    { to: "/permits", label: "Permit Tracking", icon: Table2 },
  ];

  const categories: NavItem[] = [
    { to: "/category/row-permitting", label: "ROW & Utility", icon: FileSearch },
    { to: "/category/survey-review", label: "Survey Review", icon: Ruler },
    { to: "/category/traffic-resources", label: "Traffic", icon: CarFront },
    { to: "/category/capital-projects", label: "Capital Projects", icon: Hammer },
    { to: "/category/development-review", label: "Development", icon: Building2 },
    { to: "/category/procedures-resources", label: "Procedures", icon: FolderCog },
  ];

  const closeMenu = () => setIsMenuOpen(false);

  return (
    <div className="flex h-full min-h-screen bg-background">
      {/* Mobile scrim */}
      {isMenuOpen ? (
        <button
          type="button"
          aria-label="Close navigation"
          onClick={closeMenu}
          className="fixed inset-0 z-30 bg-ink/40 lg:hidden"
        />
      ) : null}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 flex w-64 flex-col bg-sidebar transition-transform lg:static lg:translate-x-0",
          isMenuOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex items-center gap-3 border-b border-sidebar-border px-4 py-4">
          <div className="flex h-9 w-9 items-center justify-center rounded-md bg-amber text-navy-deep">
            <span className="text-sm font-bold">LE</span>
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-white">Engineering Hub</p>
            <p className="truncate text-xs text-sidebar-foreground/65">{cityName} · Dakota County</p>
          </div>
          <button
            type="button"
            onClick={closeMenu}
            className="text-sidebar-foreground/70 hover:text-white lg:hidden"
            aria-label="Close navigation"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
          <div className="space-y-1">
            {primary.map((item) => (
              <SidebarLink key={item.to} item={item} onNavigate={closeMenu} />
            ))}
          </div>

          <div className="space-y-1">
            <p className="px-3 pb-1 text-[11px] font-semibold uppercase tracking-wider text-sidebar-foreground/45">
              Resources
            </p>
            {categories.map((item) => (
              <SidebarLink key={item.to} item={item} onNavigate={closeMenu} />
            ))}
          </div>
        </nav>

        <div className="border-t border-sidebar-border p-3">
          <SidebarLink
            item={{ to: "/settings", label: "Settings", icon: Settings }}
            onNavigate={closeMenu}
          />
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-3 border-b border-border bg-card px-4 py-3 lg:hidden">
          <button
            type="button"
            onClick={() => setIsMenuOpen(true)}
            className="rounded-md p-1.5 text-ink hover:bg-secondary"
            aria-label="Open navigation"
          >
            <Menu className="h-5 w-5" />
          </button>
          <p className="text-sm font-semibold text-ink">Engineering Hub</p>
        </header>

        <main key={location.pathname} className="min-w-0 flex-1 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
