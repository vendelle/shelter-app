import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const volunteerId = req.query.volunteer_id;
			if (!volunteerId) {
				return res.status(400).json({ error: 'volunteer_id query param is required' });
			}
			const result = await pool.query(
				'SELECT volunteer_id, dog_id, level FROM volunteer_dog_familiarity WHERE volunteer_id = $1',
				[volunteerId],
			);
			return res.status(200).json(result.rows);
		}

		if (req.method === 'PUT') {
			const { volunteer_id, dog_id, level } = req.body;
			if (!volunteer_id || !dog_id || !level) {
				return res.status(400).json({ error: 'volunteer_id, dog_id, and level are required' });
			}
			if (!['good', 'difficult', 'never'].includes(level)) {
				return res.status(400).json({ error: 'level must be one of: good, difficult, never' });
			}
			const result = await pool.query(
				`INSERT INTO volunteer_dog_familiarity (volunteer_id, dog_id, level)
				 VALUES ($1, $2, $3)
				 ON CONFLICT (volunteer_id, dog_id) DO UPDATE SET level = $3
				 RETURNING volunteer_id, dog_id, level`,
				[volunteer_id, dog_id, level],
			);
			return res.status(200).json(result.rows[0]);
		}

		if (req.method === 'DELETE') {
			const volunteerId = req.query.volunteer_id;
			const dogId = req.query.dog_id;
			if (!volunteerId || !dogId) {
				return res.status(400).json({ error: 'volunteer_id and dog_id query params are required' });
			}
			await pool.query(
				'DELETE FROM volunteer_dog_familiarity WHERE volunteer_id = $1 AND dog_id = $2',
				[volunteerId, dogId],
			);
			return res.status(204).end();
		}

		res.setHeader('Allow', ['GET', 'PUT', 'DELETE']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
