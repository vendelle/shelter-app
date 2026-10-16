/**
 * Lightweight Firebase ID-token verification.
 *
 * Verifies tokens against Google's public certificates instead of pulling in
 * the ~50MB firebase-admin SDK, which keeps serverless cold starts fast.
 * See https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
 */

import { createPublicKey, verify as cryptoVerify } from 'crypto';

export interface FirebaseTokenPayload {
	/** Firebase UID */
	sub: string;
	email?: string;
	email_verified?: boolean;
	name?: string;
	picture?: string;
	iss: string;
	aud: string;
	exp: number;
	iat: number;
	auth_time: number;
}

const GOOGLE_CERTS_URL =
	'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

/** Allowed clock drift between Google and the serverless host. */
const CLOCK_SKEW_SECONDS = 60;

let cachedCerts: Record<string, string> = {};
let cacheExpiry = 0;

async function getPublicCerts(): Promise<Record<string, string>> {
	if (Date.now() < cacheExpiry && Object.keys(cachedCerts).length > 0) {
		return cachedCerts;
	}

	const res = await fetch(GOOGLE_CERTS_URL);
	if (!res.ok) throw new Error(`Failed to fetch Google certs: ${res.status}`);

	const maxAge = res.headers.get('cache-control')?.match(/max-age=(\d+)/)?.[1];
	cacheExpiry = Date.now() + (maxAge ? parseInt(maxAge, 10) * 1000 : 3600_000);
	cachedCerts = (await res.json()) as Record<string, string>;
	return cachedCerts;
}

function decodeJwt(token: string) {
	const parts = token.split('.');
	if (parts.length !== 3) throw new Error('Invalid JWT: expected 3 parts');

	const [headerPart, payloadPart, signaturePart] = parts;
	try {
		return {
			header: JSON.parse(Buffer.from(headerPart, 'base64url').toString()) as {
				alg?: string;
				kid?: string;
			},
			payload: JSON.parse(Buffer.from(payloadPart, 'base64url').toString()) as FirebaseTokenPayload,
			signedContent: `${headerPart}.${payloadPart}`,
			signature: Buffer.from(signaturePart, 'base64url'),
		};
	} catch {
		throw new Error('Invalid JWT: malformed header or payload');
	}
}

/**
 * Verify a Firebase ID token and return its decoded payload.
 * Throws if the token is malformed, badly signed, expired, or issued for a
 * different Firebase project.
 */
export async function verifyFirebaseToken(
	idToken: string,
	firebaseProjectId: string,
): Promise<FirebaseTokenPayload> {
	const { header, payload, signedContent, signature } = decodeJwt(idToken);

	if (header.alg !== 'RS256') throw new Error(`Unsupported algorithm: ${header.alg}`);

	const certs = await getPublicCerts();
	const certPem = header.kid ? certs[header.kid] : undefined;
	if (!certPem) throw new Error('Token signed with unknown key ID');

	const isValid = cryptoVerify('RSA-SHA256', Buffer.from(signedContent), createPublicKey(certPem), signature);
	if (!isValid) throw new Error('Invalid token signature');

	const now = Math.floor(Date.now() / 1000);
	if (payload.exp <= now) throw new Error('Token expired');
	if (payload.iat > now + CLOCK_SKEW_SECONDS) throw new Error('Token issued in the future');
	if (payload.auth_time > now + CLOCK_SKEW_SECONDS) throw new Error('Token auth_time in the future');
	if (payload.iss !== `https://securetoken.google.com/${firebaseProjectId}`) throw new Error('Invalid issuer');
	if (payload.aud !== firebaseProjectId) throw new Error('Invalid audience');
	if (!payload.sub || typeof payload.sub !== 'string') throw new Error('Missing subject');

	return payload;
}

/** Reset the certificate cache. Test-only. */
export function _resetCertCache(): void {
	cachedCerts = {};
	cacheExpiry = 0;
}
