// Serverless function to write stats to GitHub Gist
// Works with Vercel, Netlify, or Cloudflare Workers
// Set GITHUB_TOKEN and GIST_ID as environment variables

// Vercel/Netlify format
export default async function handler(req, res) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', 'https://persistence-ai.github.io');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // CORS headers - allow your domain
  res.setHeader('Access-Control-Allow-Origin', 'https://persistence-ai.github.io');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  const { GITHUB_TOKEN, GIST_ID } = process.env;

  if (!GITHUB_TOKEN || !GIST_ID) {
    return res.status(500).json({ error: 'Server configuration missing' });
  }

  try {
    const { type, platform, fingerprint, date } = req.body;

    // Fetch current Gist
    const gistResponse = await fetch(`https://api.github.com/gists/${GIST_ID}`, {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': `token ${GITHUB_TOKEN}`,
      },
    });

    if (!gistResponse.ok) {
      throw new Error(`Failed to fetch gist: ${gistResponse.status}`);
    }

    const gist = await gistResponse.json();
    const filename = Object.keys(gist.files)[0];
    const currentStats = JSON.parse(gist.files[filename].content);

    // Update stats based on type
    const updatedStats = { ...currentStats };

    if (type === 'copy' && platform) {
      // Increment copy count for platform
      updatedStats.copyCounts[platform] = (updatedStats.copyCounts[platform] || 0) + 1;
      updatedStats.copyCounts.total = 
        (updatedStats.copyCounts.windows || 0) + 
        (updatedStats.copyCounts.linux || 0) + 
        (updatedStats.copyCounts.mac || 0);
    }

    if (type === 'pageView' && fingerprint && date) {
      // Check if new visitor
      const isNewVisitor = !updatedStats.visitors.fingerprints[fingerprint];
      
      if (isNewVisitor) {
        updatedStats.visitors.total = (updatedStats.visitors.total || 0) + 1;
        updatedStats.visitors.fingerprints[fingerprint] = date;
        updatedStats.visitors.daily[date] = (updatedStats.visitors.daily[date] || 0) + 1;
      }

      // Always increment page views
      updatedStats.pageViews.total = (updatedStats.pageViews.total || 0) + 1;
      updatedStats.pageViews.daily[date] = (updatedStats.pageViews.daily[date] || 0) + 1;
    }

    updatedStats.lastUpdated = new Date().toISOString();

    // Update Gist
    const updateResponse = await fetch(`https://api.github.com/gists/${GIST_ID}`, {
      method: 'PATCH',
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': `token ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        files: {
          [filename]: {
            content: JSON.stringify(updatedStats, null, 2),
          },
        },
      }),
    });

    if (!updateResponse.ok) {
      throw new Error(`Failed to update gist: ${updateResponse.status}`);
    }

    return res.status(200).json({ success: true, stats: updatedStats });
  } catch (error) {
    console.error('Error updating stats:', error);
    return res.status(500).json({ error: error.message });
  }
}
