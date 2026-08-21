// Engineering Hub backend.
//
// The only server-side job this project has is fetching agency feeds that
// browsers cannot request directly. Dakota County's GIS (gis2.co.dakota.mn.us)
// and MnDOT 511 (services.arcgis.com) both send CORS headers, so the web app
// calls those straight from the browser. Lakeville's CivicPlus RSS sends no
// CORS header at all, so it has to come through here.

/** Hosts this proxy is willing to fetch. Anything else is refused. */
const ALLOWED_HOSTS: readonly string[] = [
  "www.lakevillemn.gov",
  "lakevillemn.gov",
];

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function withCors(response: Response): Response {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(CORS_HEADERS)) {
    headers.set(key, value);
  }
  return new Response(response.body, { status: response.status, headers });
}

function errorResponse(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

/**
 * GET /feed?url=<encoded feed url>
 *
 * Streams an allow-listed public RSS feed back to the browser with CORS
 * headers and a short edge cache, so a room full of staff refreshing the
 * Updates page doesn't hammer the city's web server.
 */
async function handleFeed(request: Request): Promise<Response> {
  const target = new URL(request.url).searchParams.get("url");
  if (!target) return errorResponse(400, "Missing url parameter.");

  let parsed: URL;
  try {
    parsed = new URL(target);
  } catch {
    return errorResponse(400, "That url isn't valid.");
  }

  if (parsed.protocol !== "https:") {
    return errorResponse(400, "Only https feeds are allowed.");
  }
  if (!ALLOWED_HOSTS.includes(parsed.hostname)) {
    return errorResponse(403, `${parsed.hostname} is not an allowed feed host.`);
  }

  try {
    const upstream = await fetch(parsed.toString(), {
      headers: {
        Accept: "application/rss+xml, application/xml, text/xml;q=0.9, */*;q=0.8",
        "User-Agent": "LakevilleEngineeringHub/1.0 (city staff tool)",
      },
      cf: { cacheTtl: 300, cacheEverything: true },
    });

    if (!upstream.ok) {
      return errorResponse(502, `Feed responded ${upstream.status}.`);
    }

    const body = await upstream.text();
    return new Response(body, {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, max-age=300",
        ...CORS_HEADERS,
      },
    });
  } catch (error) {
    console.error("feed fetch failed", parsed.hostname, String(error));
    return errorResponse(502, "Couldn't reach that feed.");
  }
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }));
    }

    const url = new URL(request.url);

    if (url.pathname === "/feed") return handleFeed(request);
    if (url.pathname === "/ping") {
      return withCors(Response.json({ ok: true, now: new Date().toISOString() }));
    }

    return withCors(Response.json({ ok: true, service: "engineering-hub" }));
  },
};
