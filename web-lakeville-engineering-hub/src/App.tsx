import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AppShell } from "@/components/AppShell";
import { HubStoreProvider } from "@/lib/hub-store";

import CategoryPage from "./pages/CategoryPage";
import ChecklistPage from "./pages/ChecklistPage";
import Dashboard from "./pages/Dashboard";
import LiveConditions from "./pages/LiveConditions";
import NotFound from "./pages/NotFound";
import Permits from "./pages/Permits";
import SettingsPage from "./pages/SettingsPage";
import Updates from "./pages/Updates";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { refetchOnWindowFocus: false },
  },
});

const App = () => (
  <QueryClientProvider client={queryClient}>
    <HubStoreProvider>
      <TooltipProvider>
        <Toaster position="top-right" />
        <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <AppShell>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/live" element={<LiveConditions />} />
              <Route path="/updates" element={<Updates />} />
              <Route path="/permits" element={<Permits />} />
              <Route path="/category/:categoryID" element={<CategoryPage />} />
              <Route path="/checklists/:checklistID" element={<ChecklistPage />} />
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="/index.html" element={<Navigate to="/" replace />} />
              {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </AppShell>
        </BrowserRouter>
      </TooltipProvider>
    </HubStoreProvider>
  </QueryClientProvider>
);

export default App;
