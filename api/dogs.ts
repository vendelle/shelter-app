import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders, hasColumn } from './util';
import pool from './connection';
import { getRegionForKennel } from './kennel-regions';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		// Check if region column exists (cached per request is fine for serverless)
		const hasRegionCol = await hasColumn('dogs', 'region');

		if (req.method === 'GET') {
			const includeArchived = req.query.include_archived === 'true';
			const onlyArchived = req.query.only_archived === 'true';
			let whereClause = 'WHERE archived IS NOT TRUE';
			if (onlyArchived) whereClause = 'WHERE archived = TRUE';
			else if (includeArchived) whereClause = '';
			const regionCol = hasRegionCol ? ', region' : '';
			const result = await pool.query(
				`SELECT id, name, shelterid, kennel${regionCol}, COALESCE(archived, false) as archived FROM dogs ${whereClause} ORDER BY archived, name`,
			);
			const rows = result.rows.map((row: Record<string, unknown>) => ({
				...row,
				region: (row.region as string) || getRegionForKennel(row.kennel as string),
			}));
			return res.status(200).json(rows);
		}

		if (req.method === 'POST') {
			const { name, shelterid, kennel, region } = req.body;
			if (!name || !shelterid || !kennel) {
				return res.status(400).json({ error: 'name, shelterid, and kennel are required' });
			}
			let result;
			if (hasRegionCol) {
				result = await pool.query(
					'INSERT INTO dogs (name, shelterid, kennel, region) VALUES ($1, $2, $3, $4) RETURNING id, name, shelterid, kennel, region, false as archived',
					[name, shelterid, kennel, region || null],
				);
			} else {
				result = await pool.query(
					'INSERT INTO dogs (name, shelterid, kennel) VALUES ($1, $2, $3) RETURNING id, name, shelterid, kennel, false as archived',
					[name, shelterid, kennel],
				);
			}
			const row = result.rows[0];
			return res.status(201).json({ ...row, region: (row.region as string) || getRegionForKennel(row.kennel) });
		}

		if (req.method === 'PATCH') {
			const { id, name, shelterid, kennel, region } = req.body;
			if (!id) return res.status(400).json({ error: 'id is required' });

			const fields: string[] = [];
			const values: unknown[] = [];
			let idx = 1;
			if (name !== undefined) { fields.push(`name = $${idx++}`); values.push(name); }
			if (shelterid !== undefined) { fields.push(`shelterid = $${idx++}`); values.push(shelterid); }
			if (kennel !== undefined) { fields.push(`kennel = $${idx++}`); values.push(kennel); }
			if (hasRegionCol && region !== undefined) { fields.push(`region = $${idx++}`); values.push(region || null); }
			if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });

			const regionCol = hasRegionCol ? ', region' : '';
			values.push(id);
			const result = await pool.query(
				`UPDATE dogs SET ${fields.join(', ')} WHERE id = $${idx} RETURNING id, name, shelterid, kennel${regionCol}, COALESCE(archived, false) as archived`,
				values,
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Dog not found' });
			const row = result.rows[0];
			return res.status(200).json({ ...row, region: (row.region as string) || getRegionForKennel(row.kennel) });
		}

		if (req.method === 'PUT') {
			const id = req.query.id;
			const archive = req.query.archive === 'true';
			if (!id) return res.status(400).json({ error: 'id query param is required' });

			const regionCol = hasRegionCol ? ', region' : '';
			const result = await pool.query(
				`UPDATE dogs SET archived = $1 WHERE id = $2 RETURNING id, name, shelterid, kennel${regionCol}, archived`,
				[archive, id],
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Dog not found' });
			const row = result.rows[0];
			return res.status(200).json({ ...row, region: (row.region as string) || getRegionForKennel(row.kennel) });
		}

		res.setHeader('Allow', ['GET', 'POST', 'PATCH', 'PUT']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
