/**
 * GET    /api/users?me   — Sign in: the caller's own account (created / invite
 *                          claimed on first call). Any verified Google account.
 *
 * super_admin only:
 * GET    /api/users      — All accounts and pending invites
 * POST   /api/users      — Invite { email, role, volunteer_id? }; the account
 *                          becomes active when that Google account signs in
 * PATCH  /api/users      — Update { id, role?, volunteer_id? }
 * DELETE /api/users?id=X — Remove an account or invite
 *
 * One file for all of it to stay within the serverless function budget —
 * see DECISIONS.md.
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './_lib/util';
import pool from './_lib/connection';
import { requireRole, signIn, userToJson } from './_lib/auth';
import { isRole, ROLES } from './_lib/permissions';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const USER_COLUMNS = `u.id, u.email, u.display_name, u.photo_url, u.volunteer_id, u.role,
	u.firebase_uid IS NULL AS invite_pending, u.created_at, u.last_login_at,
	v.first_name AS volunteer_first_name, v.last_name AS volunteer_last_name`;

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET' && req.query.me !== undefined) {
			const me = await signIn(req);
			if (!me) return res.status(401).json({ error: 'Sign in required' });
			return res.status(200).json(userToJson(me));
		}

		const admin = await requireRole(req, res, 'super_admin');
		if (!admin) return;

		if (req.method === 'GET') {
			const result = await pool.query(
				`SELECT ${USER_COLUMNS}
				 FROM users u LEFT JOIN volunteers v ON v.id = u.volunteer_id
				 ORDER BY (u.role = 'pending') DESC, u.created_at DESC`,
			);
			return res.status(200).json(result.rows);
		}

		if (req.method === 'POST') {
			const { role, volunteer_id } = req.body;
			const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
			if (!EMAIL.test(email)) return res.status(400).json({ error: 'A valid email is required' });
			if (!isRole(role)) return res.status(400).json({ error: `role must be one of: ${ROLES.join(', ')}` });
			const volunteerError = await validateVolunteerLink(volunteer_id, null);
			if (volunteerError) return res.status(volunteerError.status).json({ error: volunteerError.message });

			const inserted = await pool.query(
				`INSERT INTO users (email, role, volunteer_id) VALUES ($1, $2, $3)
				 ON CONFLICT (email) DO NOTHING
				 RETURNING id`,
				[email, role, volunteer_id ?? null],
			);
			if (inserted.rows.length === 0) {
				return res.status(409).json({ error: 'An account with this email already exists' });
			}
			return res.status(201).json(await findUser(inserted.rows[0].id));
		}

		if (req.method === 'PATCH') {
			const { id, role, volunteer_id } = req.body;
			if (!Number.isInteger(id)) return res.status(400).json({ error: 'id is required' });

			const fields: string[] = [];
			const values: unknown[] = [];

			if (role !== undefined) {
				if (!isRole(role)) return res.status(400).json({ error: `role must be one of: ${ROLES.join(', ')}` });
				// Guards against the last super_admin locking everyone out.
				if (id === admin.id && role !== admin.role) {
					return res.status(400).json({ error: 'You cannot change your own role' });
				}
				values.push(role);
				fields.push(`role = $${values.length}`);
			}

			if (volunteer_id !== undefined) {
				const volunteerError = await validateVolunteerLink(volunteer_id, id);
				if (volunteerError) return res.status(volunteerError.status).json({ error: volunteerError.message });
				values.push(volunteer_id);
				fields.push(`volunteer_id = $${values.length}`);
			}

			if (fields.length === 0) return res.status(400).json({ error: 'No fields to update' });

			values.push(id);
			const updated = await pool.query(
				`UPDATE users SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING id`,
				values,
			);
			if (updated.rows.length === 0) return res.status(404).json({ error: 'User not found' });
			return res.status(200).json(await findUser(id));
		}

		if (req.method === 'DELETE') {
			const id = Number(req.query.id);
			if (!Number.isInteger(id)) return res.status(400).json({ error: 'id query param is required' });
			if (id === admin.id) return res.status(400).json({ error: 'You cannot delete your own account' });

			const deleted = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
			if (deleted.rows.length === 0) return res.status(404).json({ error: 'User not found' });
			return res.status(204).end();
		}

		res.setHeader('Allow', ['GET', 'POST', 'PATCH', 'DELETE']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}

async function findUser(id: number) {
	const result = await pool.query(
		`SELECT ${USER_COLUMNS}
		 FROM users u LEFT JOIN volunteers v ON v.id = u.volunteer_id
		 WHERE u.id = $1`,
		[id],
	);
	return result.rows[0];
}

/**
 * A volunteer profile can be linked to at most one account. Returns an
 * error to send, or null when [volunteerId] (null/undefined = unlink) is fine
 * for user [userId] (null for a new invite).
 */
async function validateVolunteerLink(
	volunteerId: unknown,
	userId: number | null,
): Promise<{ status: number; message: string } | null> {
	if (volunteerId === undefined || volunteerId === null) return null;
	if (!Number.isInteger(volunteerId)) return { status: 400, message: 'volunteer_id must be an integer' };

	const volunteer = await pool.query('SELECT id FROM volunteers WHERE id = $1', [volunteerId]);
	if (volunteer.rows.length === 0) return { status: 400, message: 'Volunteer not found' };

	const linked = await pool.query('SELECT id FROM users WHERE volunteer_id = $1 AND id IS DISTINCT FROM $2', [
		volunteerId,
		userId,
	]);
	if (linked.rows.length > 0) return { status: 409, message: 'This volunteer is already linked to another account' };
	return null;
}
