import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

/**
 * GET /api/walk-partners?dog_id=X
 *
 * Returns all dogs that have shared a walk group with the given dog,
 * along with their relationship level (if set) and last shared walk date.
 * Results include both dogs with explicit relationships AND dogs with only
 * shared walk history.
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method !== 'GET') {
			res.setHeader('Allow', ['GET', 'OPTIONS']);
			return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
		}

		const dogId = req.query.dog_id;
		if (!dogId) {
			return res.status(400).json({ error: 'dog_id query param is required' });
		}

		// Find all dogs that shared a group with this dog (same date + same group_index)
		// LEFT JOIN relationships to get the level if one exists.
		const result = await pool.query(
			`WITH shared_walks AS (
				SELECT DISTINCT ON (other.dog_id)
					other.dog_id,
					d.name AS dog_name,
					my.walk_date AS last_shared_walk
				FROM walks my
				JOIN walks other ON my.walk_date = other.walk_date
					AND my.group_index = other.group_index
					AND other.dog_id != my.dog_id
					AND other.deleted_at IS NULL
				JOIN dogs d ON other.dog_id = d.id
				WHERE my.dog_id = $1
					AND my.deleted_at IS NULL
					AND my.group_index IS NOT NULL
					AND my.group_index > 0
				ORDER BY other.dog_id, my.walk_date DESC
			)
			SELECT
				sw.dog_id,
				sw.dog_name,
				sw.last_shared_walk,
				r.level,
				r.notes
			FROM shared_walks sw
			LEFT JOIN dog_relationships r
				ON (LEAST(sw.dog_id, $1::int) = r.dog_id_1
				AND GREATEST(sw.dog_id, $1::int) = r.dog_id_2)
			ORDER BY sw.last_shared_walk DESC`,
			[dogId],
		);

		// Format dates
		const partners = result.rows.map((row: Record<string, unknown>) => ({
			dog_id: row.dog_id,
			dog_name: row.dog_name,
			last_shared_walk: row.last_shared_walk instanceof Date
				? row.last_shared_walk.toISOString().slice(0, 10)
				: row.last_shared_walk,
			level: row.level ?? null,
			notes: row.notes ?? null,
		}));

		return res.status(200).json(partners);
	} catch (error) {
		handleError(error, res);
	}
}
