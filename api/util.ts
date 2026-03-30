import type { VercelResponse } from '@vercel/node';

export function handleError(error: unknown, res: VercelResponse): VercelResponse {
	console.error('API error:', error);
	if (error instanceof Error) {
		return res.status(500).json({ error: error.message });
	}
	return res.status(500).json({ error: 'An unknown error occurred' });
}

/** CORS headers for Flutter web on the same domain (and local dev). */
export function setCorsHeaders(res: VercelResponse): void {
	res.setHeader('Access-Control-Allow-Origin', '*');
	res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
	res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
