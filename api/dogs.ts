import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders, hasColumn, formatDateOnly } from './_lib/util';
import pool from './_lib/connection';
import { getRegionForKennel } from './_lib/kennel-regions';
import { buildShelterUrl } from './_lib/shelter-link';

/** Adds the computed fields every dog response carries, regardless of method. */
function withComputedFields(row: Record<string, unknown>) {
	return {
		...row,
		region: (row.region as string) || getRegionForKennel(row.kennel as string),
		region_override: (row.region as string) || null,
		arrival_date: formatDateOnly(row.arrival_date),
		departure_date: formatDateOnly(row.departure_date),
		shelter_url: buildShelterUrl(row.shelterid as string),
	};
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		// Check optional columns exist (cached per request is fine for serverless)
		const hasRegionCol = await hasColumn('dogs', 'region');
		const hasArrivalCol = await hasColumn('dogs', 'arrival_date');
		const hasDepartureCol = await hasColumn('dogs', 'departure_date');
		const regionCol = hasRegionCol ? ', region' : '';
		const arrivalCol = hasArrivalCol ? ', arrival_date' : '';
		const departureCol = hasDepartureCol ? ', departure_date' : '';
		const optionalCols = `${regionCol}${arrivalCol}${departureCol}`;

		if (req.method === 'GET') {
			const includeArchived = req.query.include_archived === 'true';
			const onlyArchived = req.query.only_archived === 'true';
			let whereClause = 'WHERE archived IS NOT TRUE';
			if (onlyArchived) whereClause = 'WHERE archived = TRUE';
			else if (includeArchived) whereClause = '';
			const result = await pool.query(
				`SELECT id, name, shelterid, kennel${optionalCols}, COALESCE(archived, false) as archived FROM dogs ${whereClause} ORDER BY archived, name`,
			);
			const rows = result.rows.map((row: Record<string, unknown>) => withComputedFields(row));
			return res.status(200).json(rows);
		}

		if (req.method === 'POST') {
			const { name, shelterid, kennel, region, arrival_date, departure_date } = req.body;
			if (!name || !shelterid || !kennel) {
				return res.status(400).json({ error: 'name, shelterid, and kennel are required' });
			}
			const insertCols = ['name', 'shelterid', 'kennel'];
			const insertValues: unknown[] = [name, shelterid, kennel];
			if (hasRegionCol) { insertCols.push('region'); insertValues.push(region || null); }
			if (hasArrivalCol) { insertCols.push('arrival_date'); insertValues.push(arrival_date || null); }
			if (hasDepartureCol) { insertCols.push('departure_date'); insertValues.push(departure_date || null); }
			const placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
			const result = await pool.query(
				`INSERT INTO dogs (${insertCols.join(', ')}) VALUES (${placeholders}) RETURNING id, name, shelterid, kennel${optionalCols}, false as archived`,
				insertValues,
			);
			return res.status(201).json(withComputedFields(result.rows[0]));
		}

		if (req.method === 'PATCH') {
			const { id, name, shelterid, kennel, region, arrival_date, departure_date } = req.body;
			if (!id) return res.status(400).json({ error: 'id is required' });

			const fields: string[] = [];
			const values: unknown[] = [];
			let idx = 1;
			if (name !== undefined) { fields.push(`name = $${idx++}`); values.push(name); }
			if (shelterid !== undefined) { fields.push(`shelterid = $${idx++}`); values.push(shelterid); }
			if (kennel !== undefined) { fields.push(`kennel = $${idx++}`); values.push(kennel); }
			if (hasRegionCol && region !== undefined) { fields.push(`region = $${idx++}`); values.push(region || null); }
			if (hasArrivalCol && arrival_date !== undefined) { fields.push(`arrival_date = $${idx++}`); values.push(arrival_date || null); }
			if (hasDepartureCol && departure_date !== undefined) { fields.push(`departure_date = $${idx++}`); values.push(departure_date || null); }
			if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });

			values.push(id);
			const result = await pool.query(
				`UPDATE dogs SET ${fields.join(', ')} WHERE id = $${idx} RETURNING id, name, shelterid, kennel${optionalCols}, COALESCE(archived, false) as archived`,
				values,
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Dog not found' });
			return res.status(200).json(withComputedFields(result.rows[0]));
		}

		if (req.method === 'PUT') {
			const id = req.query.id;
			const archive = req.query.archive === 'true';
			if (!id) return res.status(400).json({ error: 'id query param is required' });

			const result = await pool.query(
				`UPDATE dogs SET archived = $1 WHERE id = $2 RETURNING id, name, shelterid, kennel${optionalCols}, archived`,
				[archive, id],
			);
			if (result.rows.length === 0) return res.status(404).json({ error: 'Dog not found' });
			return res.status(200).json(withComputedFields(result.rows[0]));
		}

		res.setHeader('Allow', ['GET', 'POST', 'PATCH', 'PUT']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
