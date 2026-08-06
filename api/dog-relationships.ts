import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

const VALID_LEVELS = ['yard', 'contact_good', 'contact_caution', 'parallel_good', 'parallel_caution', 'incompatible'];

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const dogId = req.query.dog_id;

			let result;
			if (dogId) {
				// Relationships for a specific dog
				result = await pool.query(
					`SELECT
						r.id,
						r.dog_id_1,
						r.dog_id_2,
						r.level,
						r.notes,
						d1.name AS dog_name_1,
						d2.name AS dog_name_2
					FROM dog_relationships r
					JOIN dogs d1 ON r.dog_id_1 = d1.id
					JOIN dogs d2 ON r.dog_id_2 = d2.id
					WHERE r.dog_id_1 = $1 OR r.dog_id_2 = $1
					ORDER BY r.level, d1.name, d2.name`,
					[dogId],
				);
			} else {
				// All relationships (for matrix view)
				result = await pool.query(
					`SELECT
						r.id,
						r.dog_id_1,
						r.dog_id_2,
						r.level,
						r.notes,
						d1.name AS dog_name_1,
						d2.name AS dog_name_2
					FROM dog_relationships r
					JOIN dogs d1 ON r.dog_id_1 = d1.id
					JOIN dogs d2 ON r.dog_id_2 = d2.id
					ORDER BY d1.name, d2.name`,
				);
			}
			return res.status(200).json(result.rows);
		}

		if (req.method === 'PUT') {
			const { dog_id_1, dog_id_2, level, notes } = req.body;
			if (!dog_id_1 || !dog_id_2 || !level) {
				return res.status(400).json({ error: 'dog_id_1, dog_id_2, and level are required' });
			}
			if (dog_id_1 === dog_id_2) {
				return res.status(400).json({ error: 'dog_id_1 and dog_id_2 must be different' });
			}
			if (!VALID_LEVELS.includes(level)) {
				return res.status(400).json({ error: `level must be one of: ${VALID_LEVELS.join(', ')}` });
			}

			// Canonical ordering
			const id1 = Math.min(dog_id_1, dog_id_2);
			const id2 = Math.max(dog_id_1, dog_id_2);

			const result = await pool.query(
				`INSERT INTO dog_relationships (dog_id_1, dog_id_2, level, notes)
				 VALUES ($1, $2, $3, $4)
				 ON CONFLICT (dog_id_1, dog_id_2) DO UPDATE SET level = $3, notes = $4
				 RETURNING id, dog_id_1, dog_id_2, level, notes`,
				[id1, id2, level, notes ?? null],
			);
			return res.status(200).json(result.rows[0]);
		}

		if (req.method === 'DELETE') {
			const dogId1 = req.query.dog_id_1;
			const dogId2 = req.query.dog_id_2;
			if (!dogId1 || !dogId2) {
				return res.status(400).json({ error: 'dog_id_1 and dog_id_2 query params are required' });
			}

			const id1 = Math.min(Number(dogId1), Number(dogId2));
			const id2 = Math.max(Number(dogId1), Number(dogId2));

			await pool.query(
				'DELETE FROM dog_relationships WHERE dog_id_1 = $1 AND dog_id_2 = $2',
				[id1, id2],
			);
			return res.status(204).end();
		}

		res.setHeader('Allow', ['GET', 'PUT', 'DELETE', 'OPTIONS']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
