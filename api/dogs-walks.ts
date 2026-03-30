import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';

/**
 * GET /api/dogs-walks
 *
 * Returns all non-archived dogs with this-week and last-week walk counts.
 * Dogs with no walks are included (LEFT JOIN).
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
	console.log('[dogs-walks] Request:', req.method);
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			console.log('[dogs-walks] Querying database...');
			const result = await pool.query(`
				SELECT
					d.id,
					d.name,
					d.kennel,
					d.shelterid,
					COALESCE(
						COUNT(CASE
							WHEN w.walk_date BETWEEN date_trunc('week', current_date)
							                      AND date_trunc('week', current_date) + interval '6 days'
							THEN 1
						END),
						0
					)::int AS this_week_walks,
					COALESCE(
						COUNT(CASE
							WHEN w.walk_date BETWEEN date_trunc('week', current_date - interval '1 week')
							                      AND date_trunc('week', current_date) - interval '1 day'
							THEN 1
						END),
						0
					)::int AS last_week_walks
				FROM dogs d
				LEFT JOIN walks w ON d.id = w.dog_id
					AND w.deleted_at IS NULL
					AND w.walk_date >= date_trunc('week', current_date - interval '1 week')
				WHERE NOT d.archived
				GROUP BY d.id, d.name, d.kennel, d.shelterid
				ORDER BY this_week_walks ASC, d.id
			`);

			console.log('[dogs-walks] Got', result.rows.length, 'rows');
			return res.status(200).json(result.rows);
		}

		res.setHeader('Allow', ['GET']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		console.error('[dogs-walks] Error:', error);
		handleError(error, res);
	}
}
