/**
 * GET /api/auth/demo — Return demo user for recruiter showcase environment.
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from '../_lib/util';
import pool from '../_lib/connection';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method !== 'GET') {
			res.setHeader('Allow', ['GET']);
			return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
		}

		const demoUser = await pool.query(
			'SELECT * FROM users WHERE firebase_uid = $1',
			['demo-uid-recruiter'],
		);

		if (demoUser.rows.length === 0) {
			return res.status(404).json({ error: 'Demo user not found — run setup SQL' });
		}

		const row = demoUser.rows[0];
		return res.status(200).json({
			id: row.id,
			firebase_uid: row.firebase_uid,
			email: row.email,
			display_name: row.display_name,
			photo_url: row.photo_url,
			volunteer_id: row.volunteer_id,
			role: row.role,
		});
	} catch (error) {
		handleError(error, res);
	}
}
