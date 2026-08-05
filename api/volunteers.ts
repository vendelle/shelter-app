import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const includeArchived = req.query.include_archived === 'true';
			const onlyArchived = req.query.only_archived === 'true';
			let whereClause = 'WHERE archived IS NOT TRUE';
			if (onlyArchived) whereClause = 'WHERE archived = TRUE';
			else if (includeArchived) whereClause = '';
			const result = await pool.query(
				`SELECT id, first_name, last_name, COALESCE(archived, false) as archived, COALESCE(role, 'new') as role FROM volunteers ${whereClause} ORDER BY archived, first_name, last_name`,
			);
			return res.status(200).json(result.rows);
		}

		if (req.method === 'POST') {
			const { first_name, last_name, role } = req.body;
			if (!first_name || !last_name) {
				return res.status(400).json({ error: 'first_name and last_name are required' });
			}
			const volunteerRole = role || 'new';
			const result = await pool.query(
				'INSERT INTO volunteers (first_name, last_name, role) VALUES ($1, $2, $3) RETURNING id, first_name, last_name, false as archived, role',
				[first_name, last_name, volunteerRole],
			);
			return res.status(201).json(result.rows[0]);
		}

		if (req.method === 'PATCH') {
			const { id, first_name, last_name, role } = req.body;
			if (!id) return res.status(400).json({ error: 'id is required' });

			const fields: string[] = [];
			const values: unknown[] = [];
			let idx = 1;
			if (first_name !== undefined) { fields.push(`first_name = $${idx++}`); values.push(first_name); }
			if (last_name !== undefined) { fields.push(`last_name = $${idx++}`); values.push(last_name); }
			if (role !== undefined) { fields.push(`role = $${idx++}`); values.push(role); }
			if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });

			values.push(id);
			const result = await pool.query(
				`UPDATE volunteers SET ${fields.join(', ')} WHERE id = $${idx} RETURNING id, first_name, last_name, COALESCE(archived, false) as archived, COALESCE(role, 'new') as role`,
				values,
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Volunteer not found' });
			return res.status(200).json(result.rows[0]);
		}

		if (req.method === 'PUT') {
			const id = req.query.id;
			const archive = req.query.archive === 'true';
			if (!id) return res.status(400).json({ error: 'id query param is required' });

			const result = await pool.query(
				`UPDATE volunteers SET archived = $1 WHERE id = $2 RETURNING id, first_name, last_name, archived, COALESCE(role, 'new') as role`,
				[archive, id],
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Volunteer not found' });
			return res.status(200).json(result.rows[0]);
		}

		res.setHeader('Allow', ['GET', 'POST', 'PATCH', 'PUT']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
