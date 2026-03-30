import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const { date, volunteer, dog } = req.query;
			let query = `
				SELECT
					w.id,
					w.dog_id,
					d.name AS dog_name,
					d.kennel,
					w.volunteer_id,
					v.first_name || ' ' || v.last_name AS volunteer_name,
					w.walk_date,
					w.notes
				FROM walks w
				LEFT JOIN dogs d ON w.dog_id = d.id
				LEFT JOIN volunteers v ON w.volunteer_id = v.id
				WHERE w.deleted_at IS NULL
			`;
			const conditions: string[] = [];
			const values: (string | string[])[] = [];

			if (date) {
				conditions.push(`w.walk_date = $${values.length + 1}`);
				values.push(date as string);
			}
			if (volunteer) {
				conditions.push(`w.volunteer_id = $${values.length + 1}`);
				values.push(volunteer as string);
			}
			if (dog) {
				conditions.push(`w.dog_id = $${values.length + 1}`);
				values.push(dog as string);
			}

			if (conditions.length > 0) {
				query += ' AND ' + conditions.join(' AND ');
			}

			query += ' ORDER BY w.walk_date DESC, w.id DESC';

			const result = await pool.query(query, values);
			return res.status(200).json(result.rows);
		}

		if (req.method === 'POST') {
			const { dog_id, volunteer_id, walk_date, notes } = req.body;

			if (!dog_id || !walk_date) {
				return res.status(400).json({ error: 'dog_id and walk_date are required' });
			}

			if (!Number.isInteger(dog_id)) {
				return res.status(400).json({ error: 'dog_id must be an integer' });
			}

			const result = await pool.query(
				`INSERT INTO walks (dog_id, volunteer_id, walk_date, notes)
				 VALUES ($1, $2, $3, $4) RETURNING *`,
				[dog_id, volunteer_id || null, walk_date, notes || null],
			);

			return res.status(201).json(result.rows[0]);
		}

		if (req.method === 'DELETE') {
			const { walk_id } = req.query;

			if (!walk_id) {
				return res.status(400).json({ error: 'walk_id is required' });
			}

			await pool.query(
				'UPDATE walks SET deleted_at = NOW() WHERE id = $1',
				[walk_id],
			);

			return res.status(200).json({ message: 'Walk marked as deleted' });
		}

		res.setHeader('Allow', ['GET', 'POST', 'DELETE']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
