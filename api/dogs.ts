import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const result = await pool.query(
				'SELECT id, name, shelterid, kennel FROM dogs WHERE NOT archived ORDER BY id',
			);
			return res.status(200).json(result.rows);
		}

		res.setHeader('Allow', ['GET']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
