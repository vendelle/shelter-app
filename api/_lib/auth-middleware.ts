/**
 * Auth middleware for Vercel serverless functions.
 *
 * Extracts and verifies the Firebase ID token from the Authorization header,
 * then looks up (or creates) the corresponding user row in PostgreSQL.
 *
 * Usage in an endpoint:
 *   const user = await getAuthUser(req);          // null when no token
 *   const user = await requireAuth(req, res);     // returns 401 if missing
 *   const user = await requireRole(req, res, 'admin'); // returns 403 if insufficient
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import pool from './connection';
import { verifyFirebaseToken, type FirebaseTokenPayload } from './firebase-token';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface AuthUser {
	id: number;
	firebaseUid: string;
	email: string;
	displayName: string | null;
	photoUrl: string | null;
	volunteerId: number | null;
	role: 'pending' | 'volunteer' | 'admin' | 'super_admin';
}

/** Role hierarchy — higher index means more permissions. */
const ROLE_RANK: Record<string, number> = {
	pending: 0,
	volunteer: 1,
	admin: 2,
	super_admin: 3,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getFirebaseProjectId(): string {
	const id = process.env.FIREBASE_PROJECT_ID;
	if (!id) throw new Error('FIREBASE_PROJECT_ID environment variable is not set');
	return id;
}

function extractBearerToken(req: VercelRequest): string | null {
	const header = req.headers.authorization;
	if (!header || !header.startsWith('Bearer ')) return null;
	return header.slice(7);
}

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

// ---------------------------------------------------------------------------
// Core: look-up or upsert user from a verified token
// ---------------------------------------------------------------------------

async function findOrCreateUser(payload: FirebaseTokenPayload): Promise<AuthUser> {
	// Try to find existing user
	const existing = await pool.query(
		'SELECT * FROM users WHERE firebase_uid = $1',
		[payload.sub],
	);

	if (existing.rows.length > 0) {
		// Update last_login_at, display_name, photo_url (they may change)
		const row = existing.rows[0];
		await pool.query(
			`UPDATE users SET last_login_at = NOW(),
			   display_name = COALESCE($1, display_name),
			   photo_url = COALESCE($2, photo_url)
			 WHERE id = $3`,
			[payload.name || null, payload.picture || null, row.id],
		);
		return rowToUser({ ...row, display_name: payload.name || row.display_name, photo_url: payload.picture || row.photo_url });
	}

	// Create new user with 'pending' role
	const inserted = await pool.query(
		`INSERT INTO users (firebase_uid, email, display_name, photo_url, role, last_login_at)
		 VALUES ($1, $2, $3, $4, 'pending', NOW())
		 RETURNING *`,
		[payload.sub, payload.email, payload.name || null, payload.picture || null],
	);

	return rowToUser(inserted.rows[0]);
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Returns the authenticated user or `null` if no (valid) token was provided.
 * Does **not** send an error response — the caller decides what to do.
 */
export async function getAuthUser(req: VercelRequest): Promise<AuthUser | null> {
	const token = extractBearerToken(req);
	if (!token) return null;

	try {
		const payload = await verifyFirebaseToken(token, getFirebaseProjectId());
		return await findOrCreateUser(payload);
	} catch {
		// Invalid / expired token → treat as unauthenticated
		return null;
	}
}

/**
 * Like `getAuthUser` but sends a 401 response when there is no valid token.
 * Returns `null` after sending the response so the caller can `return`.
 */
export async function requireAuth(
	req: VercelRequest,
	res: VercelResponse,
): Promise<AuthUser | null> {
	const user = await getAuthUser(req);
	if (!user) {
		res.status(401).json({ error: 'Authentication required' });
		return null;
	}
	return user;
}

/**
 * Requires authentication **and** a minimum role.
 * Sends 401 (no token) or 403 (insufficient role) as appropriate.
 */
export async function requireRole(
	req: VercelRequest,
	res: VercelResponse,
	minimumRole: AuthUser['role'],
): Promise<AuthUser | null> {
	const user = await requireAuth(req, res);
	if (!user) return null; // 401 already sent

	if (ROLE_RANK[user.role] < ROLE_RANK[minimumRole]) {
		res.status(403).json({ error: 'Insufficient permissions' });
		return null;
	}

	return user;
}
