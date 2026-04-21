/**
 * POST /api/auth   — Exchange a Firebase ID token for a user record.
 * GET  /api/auth   — Return the currently authenticated user (or 401).
 *
 * This is the main entry-point the Flutter app calls after Firebase
 * sign-in to register / retrieve the backend user record.
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';
import { verifyFirebaseToken } from './firebase-token';
import { requireAuth, type AuthUser } from './auth-middleware';

export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		// GET — return current user
		if (req.method === 'GET') {
			const user = await requireAuth(req, res);
			if (!user) return; // 401 already sent
			return res.status(200).json(userToJson(user));
		}

		// POST — exchange Firebase token → user record (+ optional volunteer link)
		if (req.method === 'POST') {
			const { id_token, volunteer_id } = req.body;

			if (!id_token || typeof id_token !== 'string') {
				return res.status(400).json({ error: 'id_token is required' });
			}

			const projectId = process.env.FIREBASE_PROJECT_ID;
			if (!projectId) {
				return res.status(500).json({ error: 'Server misconfigured: missing FIREBASE_PROJECT_ID' });
			}

			let payload;
			try {
				payload = await verifyFirebaseToken(id_token, projectId);
			} catch (err) {
				const message = err instanceof Error ? err.message : 'Invalid token';
				return res.status(401).json({ error: message });
			}

			// Upsert user
			const existing = await pool.query(
				'SELECT * FROM users WHERE firebase_uid = $1',
				[payload.sub],
			);

			if (existing.rows.length > 0) {
				const row = existing.rows[0];

				// Optionally link volunteer (only if not already linked)
				if (volunteer_id && !row.volunteer_id) {
					// Check the volunteer exists and is not linked to another user
					const volCheck = await pool.query(
						'SELECT id FROM volunteers WHERE id = $1',
						[volunteer_id],
					);
					if (volCheck.rows.length === 0) {
						return res.status(400).json({ error: 'Volunteer not found' });
					}
					const dupeCheck = await pool.query(
						'SELECT id FROM users WHERE volunteer_id = $1',
						[volunteer_id],
					);
					if (dupeCheck.rows.length > 0) {
						return res.status(409).json({ error: 'Volunteer already linked to another account' });
					}

					await pool.query(
						`UPDATE users SET volunteer_id = $1, last_login_at = NOW(),
						   display_name = COALESCE($2, display_name),
						   photo_url = COALESCE($3, photo_url)
						 WHERE id = $4`,
						[volunteer_id, payload.name || null, payload.picture || null, row.id],
					);

					return res.status(200).json(userToJson({
						...rowToUser(row),
						volunteerId: volunteer_id,
						displayName: payload.name || row.display_name,
						photoUrl: payload.picture || row.photo_url,
					}));
				}

				// Just update login timestamp
				await pool.query(
					`UPDATE users SET last_login_at = NOW(),
					   display_name = COALESCE($1, display_name),
					   photo_url = COALESCE($2, photo_url)
					 WHERE id = $3`,
					[payload.name || null, payload.picture || null, row.id],
				);

				return res.status(200).json(userToJson({
					...rowToUser(row),
					displayName: payload.name || row.display_name,
					photoUrl: payload.picture || row.photo_url,
				}));
			}

			// New user — validate volunteer link if provided
			let linkedVolunteerId: number | null = null;
			if (volunteer_id) {
				const volCheck = await pool.query(
					'SELECT id FROM volunteers WHERE id = $1',
					[volunteer_id],
				);
				if (volCheck.rows.length === 0) {
					return res.status(400).json({ error: 'Volunteer not found' });
				}
				const dupeCheck = await pool.query(
					'SELECT id FROM users WHERE volunteer_id = $1',
					[volunteer_id],
				);
				if (dupeCheck.rows.length > 0) {
					return res.status(409).json({ error: 'Volunteer already linked to another account' });
				}
				linkedVolunteerId = volunteer_id;
			}

			const inserted = await pool.query(
				`INSERT INTO users (firebase_uid, email, display_name, photo_url, volunteer_id, role, last_login_at)
				 VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
				 RETURNING *`,
				[
					payload.sub,
					payload.email,
					payload.name || null,
					payload.picture || null,
					linkedVolunteerId,
				],
			);

			return res.status(201).json(userToJson(rowToUser(inserted.rows[0])));
		}

		res.setHeader('Allow', ['GET', 'POST']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function rowToUser(row: Record<string, unknown>): AuthUser {
	return {
		id: row.id as number,
		firebaseUid: row.firebase_uid as string,
		email: row.email as string,
		displayName: (row.display_name as string) || null,
		photoUrl: (row.photo_url as string) || null,
		volunteerId: (row.volunteer_id as number) || null,
		role: row.role as AuthUser['role'],
	};
}

function userToJson(user: AuthUser) {
	return {
		id: user.id,
		firebase_uid: user.firebaseUid,
		email: user.email,
		display_name: user.displayName,
		photo_url: user.photoUrl,
		volunteer_id: user.volunteerId,
		role: user.role,
	};
}
