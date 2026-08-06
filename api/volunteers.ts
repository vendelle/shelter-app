import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			// Single-volunteer profile mode: aggregated visit/dog stats for one
			// volunteer, used by the volunteer profile screen. Kept on this
			// endpoint (rather than a new function) to stay within the
			// project's serverless function budget — see DECISIONS.md.
			if (req.query.id) {
				return await getVolunteerProfile(req, res);
			}

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

/**
 * GET /api/volunteers?id=X
 *
 * Aggregated stats for a single volunteer's profile screen:
 * - `visits`: one row per date with a walk in the past 6 months, with the
 *   number of walks logged that day.
 * - `dogs`: every active dog with how many times this volunteer walked it
 *   in the past 90 days (0 included, so dogs never walked still show up).
 */
async function getVolunteerProfile(req: VercelRequest, res: VercelResponse) {
	const id = req.query.id as string;

	const volunteerResult = await pool.query(
		`SELECT id, first_name, last_name, COALESCE(archived, false) as archived, COALESCE(role, 'new') as role
		 FROM volunteers WHERE id = $1`,
		[id],
	);
	if (volunteerResult.rows.length === 0) {
		return res.status(404).json({ error: 'Volunteer not found' });
	}

	const visitsResult = await pool.query(
		`SELECT w.walk_date, COUNT(*)::int AS walk_count
		 FROM walks w
		 WHERE w.volunteer_id = $1
		 	AND w.deleted_at IS NULL
		 	AND w.walk_date >= CURRENT_DATE - INTERVAL '6 months'
		 GROUP BY w.walk_date
		 ORDER BY w.walk_date DESC`,
		[id],
	);

	const dogsResult = await pool.query(
		`SELECT d.id AS dog_id, d.name AS dog_name, COUNT(w.id)::int AS walk_count
		 FROM dogs d
		 LEFT JOIN walks w ON w.dog_id = d.id
		 	AND w.volunteer_id = $1
		 	AND w.deleted_at IS NULL
		 	AND w.walk_date >= CURRENT_DATE - INTERVAL '90 days'
		 WHERE d.archived IS NOT TRUE
		 GROUP BY d.id, d.name
		 ORDER BY walk_count DESC, d.name ASC`,
		[id],
	);

	return res.status(200).json({
		volunteer: volunteerResult.rows[0],
		visits: visitsResult.rows,
		dogs: dogsResult.rows,
	});
}
