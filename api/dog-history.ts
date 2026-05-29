import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';

/**
 * GET /api/dog-history?dog_id=X
 *
 * Returns walk history for a dog.
 * Each walk includes the volunteer name and all dogs in the same group
 * on that date (i.e. dogs with the same group_index walked on the same day).
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

		// Get walks for this dog in the past 3 months
		const walksResult = await pool.query(
			`SELECT
				w.id,
				w.walk_date,
				w.group_index,
				w.notes,
				v.first_name || ' ' || v.last_name AS volunteer_name
			FROM walks w
			LEFT JOIN volunteers v ON w.volunteer_id = v.id
			WHERE w.dog_id = $1
				AND w.deleted_at IS NULL
			ORDER BY w.walk_date DESC, w.id DESC`,
			[dogId],
		);

		// For walks with a group_index, find other dogs in the same group on the same date
		const walks = await Promise.all(
			walksResult.rows.map(async (walk: Record<string, unknown>) => {
				let groupDogs: Array<{ dog_id: number; dog_name: string }> = [];

				if (walk.group_index != null && (walk.group_index as number) > 0) {
					const groupResult = await pool.query(
						`SELECT w.dog_id, d.name AS dog_name
						FROM walks w
						JOIN dogs d ON w.dog_id = d.id
						WHERE w.walk_date = $1
							AND w.group_index = $2
							AND w.dog_id != $3
							AND w.deleted_at IS NULL
						ORDER BY d.name`,
						[walk.walk_date, walk.group_index, dogId],
					);
					groupDogs = groupResult.rows as Array<{ dog_id: number; dog_name: string }>;
				}

				return {
					walk_date: walk.walk_date instanceof Date
						? walk.walk_date.toISOString().slice(0, 10)
						: walk.walk_date,
					volunteer_name: walk.volunteer_name,
					group_index: walk.group_index,
					notes: walk.notes,
					group_dogs: groupDogs,
				};
			}),
		);

		return res.status(200).json(walks);
	} catch (error) {
		handleError(error, res);
	}
}
