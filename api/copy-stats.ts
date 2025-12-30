// Cloudflare Worker API for tracking install script copies
// Deploy this as a Cloudflare Worker or serverless function

/// <reference types="@cloudflare/workers-types" />

// Type definitions for Cloudflare Workers KV Namespace
interface KVNamespace {
  get(key: string): Promise<string | null>;
  put(key: string, value: string, options?: { expirationTtl?: number }): Promise<void>;
  delete(key: string): Promise<void>;
}

// Environment interface for Cloudflare Workers
interface Env {
  COPY_STATS_KV: KVNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // GET: Fetch current counts
    if (request.method === 'GET' && path === '/api/copy-stats') {
      try {
        const counts = await getCounts(env.COPY_STATS_KV);
        return new Response(JSON.stringify(counts), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      } catch (error) {
        return new Response(JSON.stringify({ error: 'Failed to fetch stats' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // POST: Track a copy event
    if (request.method === 'POST' && path === '/api/copy-stats') {
      try {
        const body = await request.json();
        const { platform, sessionId } = body;

        if (!platform || !sessionId) {
          return new Response(JSON.stringify({ error: 'Missing platform or sessionId' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Check if this session has copied within the last 10 minutes
        const sessionKey = `session:${sessionId}`;
        const lastCopyTime = await env.COPY_STATS_KV.get(sessionKey);

        if (lastCopyTime) {
          const timeSinceLastCopy = Date.now() - parseInt(lastCopyTime, 10);
          const tenMinutes = 10 * 60 * 1000; // 10 minutes in milliseconds

          if (timeSinceLastCopy < tenMinutes) {
            // Too soon, return current counts without incrementing
            const counts = await getCounts(env.COPY_STATS_KV);
            return new Response(JSON.stringify({
              ...counts,
              message: 'Rate limited - only one copy per 10 minutes',
              nextCopyAllowed: new Date(parseInt(lastCopyTime, 10) + tenMinutes).toISOString(),
            }), {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
          }
        }

        // Record this copy event
        await env.COPY_STATS_KV.put(sessionKey, Date.now().toString(), { expirationTtl: 600 }); // 10 minutes TTL
        await env.COPY_STATS_KV.put(`last_copy:${sessionId}`, JSON.stringify({ platform, timestamp: Date.now() }), { expirationTtl: 600 });

        // Increment platform-specific counter
        const platformKey = `count:${platform}`;
        const currentCount = await env.COPY_STATS_KV.get(platformKey);
        const newCount = (parseInt(currentCount || '0', 10) + 1).toString();
        await env.COPY_STATS_KV.put(platformKey, newCount);

        // Update total count
        const totalKey = 'count:total';
        const currentTotal = await env.COPY_STATS_KV.get(totalKey);
        const newTotal = (parseInt(currentTotal || '0', 10) + 1).toString();
        await env.COPY_STATS_KV.put(totalKey, newTotal);

        // Return updated counts
        const counts = await getCounts(env.COPY_STATS_KV);
        return new Response(JSON.stringify(counts), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      } catch (error) {
        return new Response(JSON.stringify({ error: 'Failed to track copy' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    return new Response('Not Found', { status: 404, headers: corsHeaders });
  },
};

async function getCounts(kv: Env['COPY_STATS_KV']) {
  const windows = parseInt(await kv.get('count:windows') || '0', 10);
  const linux = parseInt(await kv.get('count:linux') || '0', 10);
  const mac = parseInt(await kv.get('count:mac') || '0', 10);
  const total = parseInt(await kv.get('count:total') || '0', 10);

  return {
    windows,
    linux,
    mac,
    total,
  };
}
