/**
 * GET   /api/users          — List all users (super_admin only)
 * PATCH /api/users          — Update a user's role or volunteer link (super_admin only)
 *
 * This is the admin panel for managing user accounts.
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';
import { requireRole } from './_lib/auth-middleware';

const VALID_ROLES = ['pending', 'volunteer', 'admin', 'super_admin'];

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const user = await requireRole(req, res, 'super_admin');
			if (!user) return;

			const result = await pool.query(
				`SELECT u.id, u.firebase_uid, u.email, u.display_name, u.photo_url,
				        u.volunteer_id, u.role, u.created_at, u.last_login_at,
				        v.first_name AS volunteer_first_name, v.last_name AS volunteer_last_name
				 FROM users u
				 LEFT JOIN volunteers v ON u.volunteer_id = v.id
				 ORDER BY u.created_at DESC`,
			);

			return res.status(200).json(result.rows);
		}

		if (req.method === 'PATCH') {
			const user = await requireRole(req, res, 'super_admin');
			if (!user) return;

			const { id, role, volunteer_id } = req.body;
			if (!id) return res.status(400).json({ error: 'id is required' });

			const fields: string[] = [];
			const values: unknown[] = [];
			let idx = 1;

			if (role !== undefined) {
				if (!VALID_ROLES.includes(role)) {
					return res.status(400).json({ error: `Invalid role. Must be one of: ${VALID_ROLES.join(', ')}` });
				}
				// Prevent demoting yourself
				if (id === user.id && role !== 'super_admin') {
					return res.status(400).json({ error: 'Cannot change your own role' });
				}
				fields.push(`role = $${idx++}`);
				values.push(role);
			}

			if (volunteer_id !== undefined) {
				if (volunteer_id !== null) {
					// Check volunteer exists
					const volCheck = await pool.query('SELECT id FROM volunteers WHERE id = $1', [volunteer_id]);
					if (volCheck.rows.length === 0) {
						return res.status(400).json({ error: 'Volunteer not found' });
					}
					// Check not already linked to another user
					const dupeCheck = await pool.query(
						'SELECT id FROM users WHERE volunteer_id = $1 AND id != $2',
						[volunteer_id, id],
					);
					if (dupeCheck.rows.length > 0) {
						return res.status(409).json({ error: 'Volunteer already linked to another account' });
					}
				}
				fields.push(`volunteer_id = $${idx++}`);
				values.push(volunteer_id);
			}

			if (fields.length === 0) {
				return res.status(400).json({ error: 'No fields to update' });
			}

			values.push(id);
			const result = await pool.query(
				`UPDATE users SET ${fields.join(', ')} WHERE id = $${idx}
				 RETURNING id, firebase_uid, email, display_name, photo_url, volunteer_id, role, created_at, last_login_at`,
				values,
			);

			if (result.rows.length === 0) {
				return res.status(404).json({ error: 'User not found' });
			}

			return res.status(200).json(result.rows[0]);
		}

		res.setHeader('Allow', ['GET', 'PATCH']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
