import type { VercelResponse } from '@vercel/node';
import pool from './connection';

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

/** Check whether a column exists in a table. Result is cached in-memory. */
const _columnCache = new Map<string, boolean>();
export async function hasColumn(table: string, column: string): Promise<boolean> {
	const key = `${table}.${column}`;
	if (_columnCache.has(key)) return _columnCache.get(key)!;
	const result = await pool.query(
		`SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2 LIMIT 1`,
		[table, column],
	);
	const exists = result.rows.length > 0;
	_columnCache.set(key, exists);
	return exists;
}
