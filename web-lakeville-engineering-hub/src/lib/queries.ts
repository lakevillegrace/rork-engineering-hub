import { useQuery, type UseQueryResult } from "@tanstack/react-query";

import { useHubStore } from "@/lib/hub-store";
import { fetchLiveFeed, type LiveFeedResult } from "@/lib/live-ops";
import { fetchUpdates, type UpdatesResult } from "@/lib/updates";

const FIVE_MINUTES = 5 * 60 * 1000;

/** Live GIS conditions for the selected city's enabled layers. */
export function useLiveFeed(): UseQueryResult<LiveFeedResult, Error> {
  const { city, enabledSources } = useHubStore();
  const sourceKey = enabledSources.map((source) => source.id).join(",");

  return useQuery({
    queryKey: ["live-feed", city?.id ?? "none", sourceKey],
    queryFn: ({ signal }) => fetchLiveFeed(city, enabledSources, signal),
    staleTime: FIVE_MINUTES,
    refetchOnWindowFocus: false,
    retry: 1,
  });
}

/** Agency updates, folded together with the live feed already on hand. */
export function useUpdates(): UseQueryResult<UpdatesResult, Error> {
  const { city } = useHubStore();
  const live = useLiveFeed();
  const liveItems = live.data?.items ?? [];

  return useQuery({
    queryKey: ["updates", city?.id ?? "none", liveItems.length],
    queryFn: ({ signal }) => fetchUpdates(city, liveItems, signal),
    enabled: !live.isLoading,
    staleTime: FIVE_MINUTES,
    refetchOnWindowFocus: false,
    retry: 1,
  });
}
