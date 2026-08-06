import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';

/** Escape a value for CSV — wraps in quotes if it contains comma, quote, or newline. */
function csvEscape(value: string): string {
	if (value.includes(',') || value.includes('"') || value.includes('\n')) {
		return `"${value.replace(/"/g, '""')}"`;
	}
	return value;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const { date, volunteer, dog, format, from, to } = req.query;

			// CSV export mode
			if (format === 'csv') {
				if (!from || !to) {
					return res.status(400).json({ error: 'from and to query params are required for CSV export' });
				}

				const csvResult = await pool.query(
					`SELECT
						d.name AS dog_name,
						d.shelterid,
						w.walk_date,
						v.first_name || ' ' || v.last_name AS volunteer_name
					FROM walks w
					LEFT JOIN dogs d ON w.dog_id = d.id
					LEFT JOIN volunteers v ON w.volunteer_id = v.id
					WHERE w.deleted_at IS NULL
						AND w.walk_date >= $1
						AND w.walk_date <= $2
					ORDER BY w.walk_date DESC, d.name ASC`,
					[from as string, to as string],
				);

				const header = 'dog_name,shelterid,walk_date,volunteer_name';
				const rows = csvResult.rows.map((row) => {
					const walkDate = row.walk_date instanceof Date
						? row.walk_date.toISOString().split('T')[0]
						: String(row.walk_date);
					return [
						csvEscape(row.dog_name ?? ''),
						csvEscape(row.shelterid ?? ''),
						walkDate,
						csvEscape(row.volunteer_name ?? ''),
					].join(',');
				});
				const csv = [header, ...rows].join('\n');

				res.setHeader('Content-Type', 'text/csv; charset=utf-8');
				res.setHeader('Content-Disposition', 'attachment; filename=walks_export.csv');
				return res.status(200).send(csv);
			}

			// Standard JSON response
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
