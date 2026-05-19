/**
 * Lightweight Firebase ID-token verification.
 *
 * Verifies tokens using Google's public certificates instead of the heavy
 * firebase-admin SDK, keeping serverless function bundles small and
 * staying within Vercel's free-tier limits.
 */

import { createPublicKey, verify as cryptoVerify, KeyObject } from 'crypto';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface FirebaseTokenPayload {
	/** Firebase UID */
	sub: string;
	email?: string;
	name?: string;
	picture?: string;
	iss: string;
	aud: string;
	exp: number;
	iat: number;
	auth_time: number;
}

// ---------------------------------------------------------------------------
// Certificate cache
// ---------------------------------------------------------------------------

const GOOGLE_CERTS_URL =
	'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let cachedCerts: Record<string, string> = {};
let cacheExpiry = 0;

async function getPublicCerts(): Promise<Record<string, string>> {
	if (Date.now() < cacheExpiry && Object.keys(cachedCerts).length > 0) {
		return cachedCerts;
	}

	const res = await fetch(GOOGLE_CERTS_URL);
	if (!res.ok) throw new Error(`Failed to fetch Google certs: ${res.status}`);

	const cacheControl = res.headers.get('cache-control');
	const maxAge = cacheControl?.match(/max-age=(\d+)/)?.[1];
	cacheExpiry = Date.now() + (maxAge ? parseInt(maxAge) * 1000 : 3600_000);

	cachedCerts = (await res.json()) as Record<string, string>;
	return cachedCerts;
}

// ---------------------------------------------------------------------------
// JWT helpers (minimal, no external dependencies)
// ---------------------------------------------------------------------------

function base64UrlDecode(str: string): Buffer {
	// Restore standard base64 padding
	const padded = str.replace(/-/g, '+').replace(/_/g, '/');
	return Buffer.from(padded, 'base64');
}

function decodeJwtParts(token: string): {
	header: { alg: string; kid: string; typ: string };
	payload: FirebaseTokenPayload;
	signatureInput: string;
	signature: Buffer;
} {
	const parts = token.split('.');
	if (parts.length !== 3) throw new Error('Invalid JWT: expected 3 parts');

	const header = JSON.parse(base64UrlDecode(parts[0]).toString());
	const payload = JSON.parse(base64UrlDecode(parts[1]).toString());
	const signatureInput = `${parts[0]}.${parts[1]}`;
	const signature = base64UrlDecode(parts[2]);

	return { header, payload, signatureInput, signature };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Verify a Firebase ID token and return its decoded payload.
 *
 * Checks:
 * - Algorithm is RS256
 * - Key ID matches a current Google certificate
 * - Cryptographic signature is valid
 * - Token is not expired and was issued in the past
 * - `iss` and `aud` match the Firebase project
 */
export async function verifyFirebaseToken(
	idToken: string,
	firebaseProjectId: string,
): Promise<FirebaseTokenPayload> {
	const { header, payload, signatureInput, signature } = decodeJwtParts(idToken);

	// 1. Algorithm check
	if (header.alg !== 'RS256') {
		throw new Error(`Unsupported algorithm: ${header.alg}`);
	}

	// 2. Fetch signing key
	const certs = await getPublicCerts();
	const certPem = certs[header.kid];
	if (!certPem) {
		throw new Error('Token signed with unknown key ID');
	}

	// 3. Signature verification
	const publicKey: KeyObject = createPublicKey(certPem);
	const isValid = cryptoVerify(
		'RSA-SHA256',
		Buffer.from(signatureInput),
		publicKey,
		signature,
	);
	if (!isValid) throw new Error('Invalid token signature');

	// 4. Claims validation
	const now = Math.floor(Date.now() / 1000);
	if (payload.exp <= now) throw new Error('Token expired');
	if (payload.iat > now + 60) throw new Error('Token issued in the future');
	if (payload.iss !== `https://securetoken.google.com/${firebaseProjectId}`) {
		throw new Error('Invalid issuer');
	}
	if (payload.aud !== firebaseProjectId) {
		throw new Error('Invalid audience');
	}
	if (!payload.sub || typeof payload.sub !== 'string') {
		throw new Error('Missing subject');
	}

	return payload;
}

// ---------------------------------------------------------------------------
// Cache management (for testing)
// ---------------------------------------------------------------------------

/** Reset the certificate cache. Useful in tests. */
export function _resetCertCache(): void {
	cachedCerts = {};
	cacheExpiry = 0;
}
