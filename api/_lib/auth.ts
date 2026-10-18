/**
 * Authentication for Vercel serverless functions.
 *
 * The Flutter app signs in with Google through Firebase Auth and sends the
 * Firebase ID token as `Authorization: Bearer <token>`. Here the token is
 * verified and mapped to a row in the `users` table, which holds the role.
 *
 *   signIn(req)                    — called once per app session (GET /api/users?me);
 *                                    creates / claims the user row
 *   getAuthUser(req)               — read-only lookup, null when anonymous
 *   requireRole(req, res, 'admin') — sends 401/403 itself and returns null
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import pool from './connection';
import { verifyFirebaseToken, type FirebaseTokenPayload } from './firebase-token';
import { hasRole, type LadderRole, type Role } from './permissions';

export interface AuthUser {
	id: number;
	email: string;
	displayName: string | null;
	photoUrl: string | null;
	volunteerId: number | null;
	role: Role;
}

/** The Firebase project the Flutter app signs in to (lib/firebase_options.dart). */
const DEFAULT_FIREBASE_PROJECT_ID = 'shelter-app-cf77a';

function firebaseProjectId(): string {
	return process.env.FIREBASE_PROJECT_ID || DEFAULT_FIREBASE_PROJECT_ID;
}

/**
 * Emails that always get super_admin on sign-in (comma-separated env var),
 * so the app owner can get in on a fresh database without touching SQL.
 */
function isBootstrapSuperAdmin(email: string): boolean {
	return (process.env.SUPER_ADMIN_EMAILS ?? '')
		.split(',')
		.map((e) => e.trim().toLowerCase())
		.includes(email);
}

export function rowToUser(row: Record<string, unknown>): AuthUser {
	return {
		id: row.id as number,
		email: row.email as string,
		displayName: (row.display_name as string | null) ?? null,
		photoUrl: (row.photo_url as string | null) ?? null,
		volunteerId: (row.volunteer_id as number | null) ?? null,
		role: row.role as Role,
	};
}

export function userToJson(user: AuthUser) {
	return {
		id: user.id,
		email: user.email,
		display_name: user.displayName,
		photo_url: user.photoUrl,
		volunteer_id: user.volunteerId,
		role: user.role,
	};
}

/**
 * Verified Google identity behind the request, or null when there's no
 * token, it doesn't verify, or the email isn't verified (invites are
 * matched by email, so an unverified one must never be trusted).
 */
async function verifiedIdentity(
	req: VercelRequest,
): Promise<(FirebaseTokenPayload & { email: string }) | null> {
	const header = req.headers?.authorization;
	if (!header?.startsWith('Bearer ')) return null;

	let payload: FirebaseTokenPayload;
	try {
		payload = await verifyFirebaseToken(header.slice('Bearer '.length), firebaseProjectId());
	} catch (err) {
		console.warn('[auth] rejected token:', err instanceof Error ? err.message : err);
		return null;
	}

	if (!payload.email || payload.email_verified !== true) return null;
	return { ...payload, email: payload.email.toLowerCase() };
}

/**
 * Signs the request's Google account in: returns its user row, creating it
 * on first sign-in. An invite for the same email is claimed; otherwise the
 * new account starts as 'pending'.
 */
export async function signIn(req: VercelRequest): Promise<AuthUser | null> {
	const identity = await verifiedIdentity(req);
	if (!identity) return null;

	const bootstrap = isBootstrapSuperAdmin(identity.email);
	const params = [
		identity.sub,
		identity.email,
		identity.name ?? null,
		identity.picture ?? null,
		bootstrap,
	];

	// Rows are matched by the (Google-verified) email, which is what makes an
	// invite claimable; on a match the uid is (re)attached and profile
	// fields are refreshed, but the role is kept.
	const result = await pool.query(
		`INSERT INTO users (firebase_uid, email, display_name, photo_url, role, last_login_at)
		 VALUES ($1, $2, $3, $4, CASE WHEN $5 THEN 'super_admin' ELSE 'pending' END, NOW())
		 ON CONFLICT (email) DO UPDATE SET
		   firebase_uid  = EXCLUDED.firebase_uid,
		   display_name  = COALESCE(EXCLUDED.display_name, users.display_name),
		   photo_url     = COALESCE(EXCLUDED.photo_url, users.photo_url),
		   role          = CASE WHEN $5 THEN 'super_admin' ELSE users.role END,
		   last_login_at = NOW()
		 RETURNING *`,
		params,
	);
	return rowToUser(result.rows[0]);
}

/** The signed-in user behind the request, or null for anonymous requests. */
export async function getAuthUser(req: VercelRequest): Promise<AuthUser | null> {
	const identity = await verifiedIdentity(req);
	if (!identity) return null;

	const result = await pool.query('SELECT * FROM users WHERE firebase_uid = $1', [identity.sub]);
	return result.rows.length > 0 ? rowToUser(result.rows[0]) : null;
}

/**
 * Returns the user when they have at least [minimum] role, or one of
 * [alsoAllow] (roles outside the ladder, e.g. 'exporter'). Otherwise sends
 * 401 (not signed in) or 403 (role too low) and returns null, so callers
 * can simply `if (!user) return;`.
 */
export async function requireRole(
	req: VercelRequest,
	res: VercelResponse,
	minimum: LadderRole,
	alsoAllow: readonly Role[] = [],
): Promise<AuthUser | null> {
	const user = await getAuthUser(req);
	if (!user) {
		res.status(401).json({ error: 'Sign in required' });
		return null;
	}
	if (!hasRole(user, minimum) && !alsoAllow.includes(user.role)) {
		res.status(403).json({ error: 'Insufficient permissions' });
		return null;
	}
	return user;
}
