/**
 * Static content model for the Engineering Hub: the six categories, their
 * sections, and seed data for tracking screens.
 *
 * Web links start unconfigured so staff can attach the real destinations from
 * inside the app (Settings → Paste a list of links), exactly as on iOS.
 */

export type ResourceActionKind = "web" | "phone" | "email" | "route";

export interface ResourceAction {
  kind: ResourceActionKind;
  /** Default web address, phone number, email, or in-app route. */
  value?: string;
}

/** A single actionable row inside a hub section. */
export interface ResourceLink {
  id: string;
  title: string;
  /** Lucide icon name rendered by `ResourceIcon`. */
  icon: string;
  detail?: string;
  action: ResourceAction;
}

export interface ResourceSection {
  id: string;
  title: string;
  footnote?: string;
  links: ResourceLink[];
}

export interface HubCategory {
  id: string;
  title: string;
  summary: string;
  icon: string;
  sections: ResourceSection[];
}

const DAKOTA_COUNTY_PHONE = "9528917115";
const DAKOTA_COUNTY_EMAIL = "rosalee.mccready@co.dakota.mn.us";

const web = (defaultURL?: string): ResourceAction => ({ kind: "web", value: defaultURL });
const phone = (number: string): ResourceAction => ({ kind: "phone", value: number });
const email = (address: string): ResourceAction => ({ kind: "email", value: address });
const route = (path: string): ResourceAction => ({ kind: "route", value: path });

export const ROW_PERMITTING: HubCategory = {
  id: "row-permitting",
  title: "ROW & Utility Permitting",
  summary:
    "Utility and ROW permit review and coordination: permits, fiber construction, restoration and closeout.",
  icon: "FileSearch",
  sections: [
    {
      id: "row-tracking",
      title: "Permit Tracking",
      footnote: "Always check tracking first to confirm current status before responding.",
      links: [
        {
          id: "row-tracking-all",
          title: "Permit Tracking (ALL Inboxes)",
          icon: "Table2",
          detail: "ROW · RowM · ENG Survey",
          action: route("/permits"),
        },
        { id: "row-applications", title: "ROW Permit Applications", icon: "Inbox", action: web() },
        {
          id: "row-fiber-inquiry",
          title: "ROW/Fiber Inquiry Management",
          icon: "Network",
          action: web(),
        },
        {
          id: "row-moratorium",
          title: "Moratorium Notes & Admin Updates",
          icon: "TriangleAlert",
          action: web(),
        },
      ],
    },
    {
      id: "row-quick-links",
      title: "Quick Links",
      links: [
        { id: "row-onestop-permits", title: "ROW — One Stop Roadway Permits", icon: "Link", action: web() },
        { id: "row-onestop-shop", title: "OneStop Roadway Shop", icon: "Building2", action: web() },
        { id: "row-gis", title: "GIS Lakeville ROW Permits", icon: "Map", action: web() },
        { id: "row-gsoc", title: "FIND One Call Concepts Ticket List", icon: "ListChecks", action: web() },
        { id: "row-contacts", title: "ROW & General Contacts", icon: "Users", action: web() },
        {
          id: "row-dakota-phone",
          title: "Dakota County Permit Office",
          icon: "Phone",
          detail: "(952) 891-7115 — direct applicants here",
          action: phone(DAKOTA_COUNTY_PHONE),
        },
        {
          id: "row-dakota-email",
          title: "Rosalee McCready (Dakota County)",
          icon: "Mail",
          detail: "Internal staff contact",
          action: email(DAKOTA_COUNTY_EMAIL),
        },
      ],
    },
    {
      id: "row-templates",
      title: "Examples & Templates",
      links: [
        {
          id: "row-checklist",
          title: "ROW Checklist",
          icon: "ClipboardCheck",
          detail: "Review steps before approval",
          action: route("/checklists/row"),
        },
        { id: "row-install-example", title: "Installation Plan Example", icon: "FileText", action: web() },
        { id: "row-traffic-example", title: "Traffic Control Plan Example", icon: "TrafficCone", action: web() },
        { id: "row-notice-template", title: "ROW Permit Notice Template", icon: "Files", action: web() },
        { id: "row-fee-permits", title: "2026 Fee Schedule (Permits)", icon: "CircleDollarSign", action: web() },
        { id: "row-fee-full", title: "2026 Fee Schedule (Full)", icon: "CircleDollarSign", action: web() },
      ],
    },
  ],
};

export const SURVEY_REVIEW: HubCategory = {
  id: "survey-review",
  title: "Survey Review",
  summary: "As-built surveys, building permit certificates, checklists and examples.",
  icon: "Ruler",
  sections: [
    {
      id: "survey-inboxes",
      title: "Inboxes",
      links: [
        { id: "survey-rowm", title: "RowM — As-Built Surveys", icon: "Map", action: web() },
        {
          id: "survey-eng",
          title: "ENG Survey — Building Permit Certificates",
          icon: "FileSearch",
          action: web(),
        },
        {
          id: "survey-tracking",
          title: "Permit Tracking (ALL Inboxes)",
          icon: "Table2",
          action: route("/permits"),
        },
      ],
    },
    {
      id: "survey-quick-links",
      title: "Quick Links",
      links: [
        {
          id: "survey-asbuilt-checklist",
          title: "As-Built Survey Checklist",
          icon: "ClipboardCheck",
          action: route("/checklists/as-built"),
        },
        {
          id: "survey-cos-checklist",
          title: "Certificate of Survey Checklist",
          icon: "ClipboardCheck",
          action: route("/checklists/certificate"),
        },
        { id: "survey-county-contacts", title: "Dakota County Surveyor Contacts", icon: "Users", action: web() },
        { id: "survey-gis", title: "GIS Survey Reference Map", icon: "Map", action: web() },
      ],
    },
    {
      id: "survey-templates",
      title: "Examples & Templates",
      links: [
        { id: "survey-asbuilt-example", title: "Approved As-Built Example", icon: "FileText", action: web() },
        { id: "survey-cos-example", title: "Certificate of Survey Example", icon: "FileText", action: web() },
        { id: "survey-comment-template", title: "Review Comment Notice Template", icon: "Files", action: web() },
        { id: "survey-submittal", title: "Survey Submittal Requirements", icon: "ClipboardList", action: web() },
      ],
    },
  ],
};

export const TRAFFIC_RESOURCES: HubCategory = {
  id: "traffic-resources",
  title: "Traffic Resources",
  summary: "Traffic counts, mapping, equipment, data processing and crash-review resources.",
  icon: "CarFront",
  sections: [
    {
      id: "traffic-mapping",
      title: "Mapping & Data",
      links: [
        {
          id: "traffic-count-apps",
          title: "Internal Traffic Count Applications",
          icon: "BarChart3",
          detail: "2026–2029 program",
          action: web(),
        },
        { id: "traffic-count-map", title: "Traffic Count Map (GIS)", icon: "Map", action: web() },
        { id: "traffic-crash-data", title: "Crash Review Data", icon: "TriangleAlert", action: web() },
        { id: "traffic-processing-sop", title: "Data Processing SOP", icon: "Settings2", action: web() },
      ],
    },
    {
      id: "traffic-equipment",
      title: "Equipment & Contacts",
      links: [
        { id: "traffic-equipment-checkout", title: "Count Equipment Checkout", icon: "Package", action: web() },
        { id: "traffic-scheduler", title: "Metro Count Scheduler", icon: "CalendarDays", action: web() },
        { id: "traffic-staff", title: "Traffic Staff Contacts", icon: "Users", action: web() },
      ],
    },
  ],
};

export const CAPITAL_PROJECTS: HubCategory = {
  id: "capital-projects",
  title: "Capital Projects",
  summary: "Quick access to active City project information and coordination resources.",
  icon: "Hammer",
  sections: [
    {
      id: "cip-resources",
      title: "Project Resources",
      links: [
        { id: "cip-map", title: "CIP Project Map (GIS)", icon: "Map", action: web() },
        { id: "cip-notices", title: "Construction Notices & Updates", icon: "Bell", action: web() },
        { id: "cip-detours", title: "Detour & Traffic Impacts", icon: "CarFront", action: web() },
        { id: "cip-contacts", title: "Project Contact List", icon: "Users", action: web() },
      ],
    },
    {
      id: "cip-coordination",
      title: "Coordination",
      links: [
        { id: "cip-utility-meetings", title: "Utility Coordination Meetings", icon: "CalendarDays", action: web() },
        { id: "cip-inspections", title: "Inspection Schedules", icon: "BadgeCheck", action: web() },
        { id: "cip-directory", title: "Consultant & Contractor Directory", icon: "Building2", action: web() },
      ],
    },
  ],
};

export const DEVELOPMENT_REVIEW: HubCategory = {
  id: "development-review",
  title: "Development Review",
  summary: "Plat, site plan and development engineering review resources.",
  icon: "Building2",
  sections: [
    {
      id: "dev-review-types",
      title: "Review Types",
      links: [
        { id: "dev-plat", title: "Plat Review", icon: "Map", action: web() },
        { id: "dev-site-plan", title: "Site Plan Review", icon: "LayoutGrid", action: web() },
        { id: "dev-engineering", title: "Development Engineering Review", icon: "Ruler", action: web() },
      ],
    },
    {
      id: "dev-applications",
      title: "Applications & Tracking",
      links: [
        { id: "dev-tracking", title: "Development Review Tracking", icon: "ClipboardList", action: web() },
        { id: "dev-forms", title: "Application Forms & Fees", icon: "FileClock", action: web() },
        { id: "dev-preapp", title: "Pre-Application Meetings", icon: "Users", action: web() },
        { id: "dev-deadlines", title: "Comment Deadline Calendar", icon: "CalendarDays", action: web() },
      ],
    },
    {
      id: "dev-standards",
      title: "Standards & Templates",
      links: [
        { id: "dev-standards-manual", title: "Design Standards Manual", icon: "BookOpen", action: web() },
        { id: "dev-comment-template", title: "Review Comment Template", icon: "Files", action: web() },
        { id: "dev-plat-checklist", title: "Preliminary Plat Checklist", icon: "ClipboardCheck", action: web() },
        { id: "dev-swppp", title: "Stormwater Requirements (SWPPP)", icon: "CloudRain", action: web() },
      ],
    },
  ],
};

export const PROCEDURES_RESOURCES: HubCategory = {
  id: "procedures-resources",
  title: "Procedures & Resources",
  summary: "Engineering procedures, SOPs, contacts, templates and staff references.",
  icon: "FolderCog",
  sections: [
    {
      id: "proc-sops",
      title: "Procedures & SOPs",
      links: [
        { id: "proc-sop-library", title: "Engineering SOP Library", icon: "BookOpen", action: web() },
        { id: "proc-permit-review", title: "Permit Review Procedure", icon: "ClipboardCheck", action: web() },
        { id: "proc-records", title: "Records Retention & Filing", icon: "Archive", action: web() },
        { id: "proc-safety", title: "Safety & Field Procedures", icon: "ShieldCheck", action: web() },
      ],
    },
    {
      id: "proc-contacts",
      title: "Contacts",
      links: [
        { id: "proc-staff-directory", title: "Engineering Staff Directory", icon: "CircleUser", action: web() },
        {
          id: "proc-dakota-phone",
          title: "Dakota County Permit Office",
          icon: "Phone",
          detail: "(952) 891-7115",
          action: phone(DAKOTA_COUNTY_PHONE),
        },
        { id: "proc-utility-contacts", title: "Utility & Fiber Contacts", icon: "CircleUser", action: web() },
        { id: "proc-gsoc", title: "GSOC / One Call Concepts", icon: "PhoneCall", action: web() },
      ],
    },
    {
      id: "proc-templates",
      title: "Templates & References",
      links: [
        { id: "proc-notice-templates", title: "Notice & Letter Templates", icon: "FileText", action: web() },
        { id: "proc-fees", title: "Fee Schedules (2026)", icon: "CircleDollarSign", action: web() },
        { id: "proc-gis", title: "GIS Maps & Layers", icon: "Map", action: web() },
        { id: "proc-handbook", title: "Employee Handbook References", icon: "BookMarked", action: web() },
      ],
    },
  ],
};

export const HUB_CATEGORIES: HubCategory[] = [
  ROW_PERMITTING,
  SURVEY_REVIEW,
  TRAFFIC_RESOURCES,
  CAPITAL_PROJECTS,
  DEVELOPMENT_REVIEW,
  PROCEDURES_RESOURCES,
];

export function categoryByID(id: string | undefined): HubCategory | null {
  return HUB_CATEGORIES.find((category) => category.id === id) ?? null;
}

export const ALL_LINKS: ResourceLink[] = HUB_CATEGORIES.flatMap((category) =>
  category.sections.flatMap((section) => section.links),
);

export function linkByID(id: string): ResourceLink | null {
  return ALL_LINKS.find((link) => link.id === id) ?? null;
}

/** Which category a link belongs to, used when exporting configuration. */
export function categoryTitleForLink(linkID: string): string {
  for (const category of HUB_CATEGORIES) {
    for (const section of category.sections) {
      if (section.links.some((link) => link.id === linkID)) return category.title;
    }
  }
  return "Other";
}

// MARK: - Checklists

export interface ChecklistDefinition {
  id: string;
  title: string;
  steps: string[];
}

export const CHECKLISTS: ChecklistDefinition[] = [
  {
    id: "row",
    title: "ROW Checklist",
    steps: [
      "Verify moratorium restrictions",
      "Confirm applicable 2026 fees",
      "Review installation plan",
      "Review traffic control plan",
      "Notify fiber contacts",
      "Issue approval notice from template",
    ],
  },
  {
    id: "as-built",
    title: "As-Built Survey Checklist",
    steps: [
      "Confirm submittal is a signed as-built",
      "Check elevations against approved grading plan",
      "Verify utility service locations",
      "Note erosion control status",
      "Log result in tracking spreadsheet",
    ],
  },
  {
    id: "certificate",
    title: "Certificate of Survey Checklist",
    steps: [
      "Confirm building permit number matches",
      "Verify setbacks and lot lines",
      "Check drainage & utility easements",
      "Confirm proposed elevations",
      "Return comments using notice template",
    ],
  },
];

export function checklistByID(id: string | undefined): ChecklistDefinition | null {
  return CHECKLISTS.find((checklist) => checklist.id === id) ?? null;
}

// MARK: - Permit tracking

export const PERMIT_INBOXES = ["row", "rowM", "engSurvey"] as const;
export type PermitInbox = (typeof PERMIT_INBOXES)[number];

export const PERMIT_INBOX_TITLE: Record<PermitInbox, string> = {
  row: "ROW",
  rowM: "RowM — As-Built",
  engSurvey: "ENG Survey",
};

export const PERMIT_STATUSES = [
  "underReview",
  "awaitingApplicant",
  "awaitingRestoration",
  "pendingPickup",
  "approved",
  "closed",
] as const;
export type PermitStatus = (typeof PERMIT_STATUSES)[number];

export const PERMIT_STATUS_TITLE: Record<PermitStatus, string> = {
  underReview: "Under review",
  awaitingApplicant: "Awaiting applicant",
  awaitingRestoration: "Awaiting restoration",
  pendingPickup: "Pending pickup",
  approved: "Approved",
  closed: "Closed",
};

export const OPEN_PERMIT_STATUSES: PermitStatus[] = [
  "underReview",
  "awaitingApplicant",
  "awaitingRestoration",
  "pendingPickup",
];

export interface PermitRecord {
  id: string;
  number: string;
  applicant: string;
  inbox: PermitInbox;
  status: PermitStatus;
  receivedDate: string;
  note?: string;
}

function daysAgo(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date.toISOString();
}

/** Sample rows so the tracking board isn't empty on first run. */
export function seedPermits(): PermitRecord[] {
  return [
    { id: "seed-1", number: "ROW-2026-0141", applicant: "Xcel Energy", inbox: "row", status: "awaitingRestoration", receivedDate: daysAgo(6), note: "Restoration due before winter moratorium." },
    { id: "seed-2", number: "ROW-2026-0139", applicant: "Frontier Fiber", inbox: "row", status: "underReview", receivedDate: daysAgo(8), note: "Traffic control plan needs revision." },
    { id: "seed-3", number: "ROW-2026-0136", applicant: "Dakota Electric", inbox: "row", status: "approved", receivedDate: daysAgo(14) },
    { id: "seed-4", number: "AB-2026-0087", applicant: "Keavy & Klein Surveying", inbox: "rowM", status: "approved", receivedDate: daysAgo(2) },
    { id: "seed-5", number: "AB-2026-0086", applicant: "Sathre-Bergquist", inbox: "rowM", status: "underReview", receivedDate: daysAgo(3) },
    { id: "seed-6", number: "CS-2026-0032", applicant: "Lennar Homes", inbox: "engSurvey", status: "pendingPickup", receivedDate: daysAgo(1) },
    { id: "seed-7", number: "CS-2026-0031", applicant: "M/I Homes", inbox: "engSurvey", status: "awaitingApplicant", receivedDate: daysAgo(5) },
  ];
}
