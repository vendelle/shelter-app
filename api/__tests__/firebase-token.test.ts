import { verifyFirebaseToken, _resetCertCache } from '../firebase-token';
import { createPublicKey, generateKeyPairSync, sign as cryptoSign } from 'crypto';

// ---------------------------------------------------------------------------
// Test key pair
// ---------------------------------------------------------------------------

const { publicKey, privateKey } = generateKeyPairSync('rsa', {
	modulusLength: 2048,
});

const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' }) as string;

function base64UrlEncode(data: string | Buffer): string {
	const buf = typeof data === 'string' ? Buffer.from(data) : data;
	return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function createJwt(
	header: Record<string, unknown>,
	payload: Record<string, unknown>,
): string {
	const headerB64 = base64UrlEncode(JSON.stringify(header));
	const payloadB64 = base64UrlEncode(JSON.stringify(payload));
	const signatureInput = `${headerB64}.${payloadB64}`;

	const signature = cryptoSign('RSA-SHA256', Buffer.from(signatureInput), privateKey);
	const signatureB64 = base64UrlEncode(signature);

	return `${headerB64}.${payloadB64}.${signatureB64}`;
}

// ---------------------------------------------------------------------------
// Mock Google certs endpoint
// ---------------------------------------------------------------------------

const TEST_KID = 'test-key-id-1';
const TEST_PROJECT_ID = 'test-project-123';

beforeEach(() => {
	_resetCertCache();
	global.fetch = jest.fn().mockResolvedValue({
		ok: true,
		headers: { get: () => 'max-age=3600' },
		json: () => Promise.resolve({ [TEST_KID]: publicKeyPem }),
	});
});

afterEach(() => {
	jest.restoreAllMocks();
});

function validPayload(overrides: Record<string, unknown> = {}) {
	const now = Math.floor(Date.now() / 1000);
	return {
		sub: 'firebase-uid-abc',
		email: 'test@example.com',
		name: 'Test User',
		picture: 'https://example.com/photo.jpg',
		iss: `https://securetoken.google.com/${TEST_PROJECT_ID}`,
		aud: TEST_PROJECT_ID,
		exp: now + 3600,
		iat: now - 60,
		auth_time: now - 120,
		...overrides,
	};
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('verifyFirebaseToken', () => {
	it('verifies a valid token', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload(),
		);

		const result = await verifyFirebaseToken(token, TEST_PROJECT_ID);

		expect(result.sub).toBe('firebase-uid-abc');
		expect(result.email).toBe('test@example.com');
		expect(result.name).toBe('Test User');
	});

	it('rejects a token with wrong algorithm', async () => {
		const token = createJwt(
			{ alg: 'HS256', kid: TEST_KID, typ: 'JWT' },
			validPayload(),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Unsupported algorithm: HS256',
		);
	});

	it('rejects a token with unknown key ID', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: 'unknown-key', typ: 'JWT' },
			validPayload(),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Token signed with unknown key ID',
		);
	});

	it('rejects an expired token', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload({ exp: Math.floor(Date.now() / 1000) - 10 }),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Token expired',
		);
	});

	it('rejects a token issued in the future', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload({ iat: Math.floor(Date.now() / 1000) + 300 }),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Token issued in the future',
		);
	});

	it('rejects a token with wrong issuer', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload({ iss: 'https://securetoken.google.com/wrong-project' }),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Invalid issuer',
		);
	});

	it('rejects a token with wrong audience', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload({ aud: 'wrong-project' }),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Invalid audience',
		);
	});

	it('rejects a malformed token', async () => {
		await expect(verifyFirebaseToken('not.a.jwt.token', TEST_PROJECT_ID)).rejects.toThrow();
	});

	it('rejects token with missing subject', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload({ sub: '' }),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Missing subject',
		);
	});

	it('caches certificates on subsequent calls', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload(),
		);

		await verifyFirebaseToken(token, TEST_PROJECT_ID);
		await verifyFirebaseToken(token, TEST_PROJECT_ID);

		// fetch should only be called once due to caching
		expect(global.fetch).toHaveBeenCalledTimes(1);
	});

	it('rejects when Google certs endpoint fails', async () => {
		(global.fetch as jest.Mock).mockResolvedValue({
			ok: false,
			status: 500,
			headers: { get: () => null },
		});

		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload(),
		);

		await expect(verifyFirebaseToken(token, TEST_PROJECT_ID)).rejects.toThrow(
			'Failed to fetch Google certs: 500',
		);
	});

	it('rejects a token with tampered signature', async () => {
		const token = createJwt(
			{ alg: 'RS256', kid: TEST_KID, typ: 'JWT' },
			validPayload(),
		);

		// Tamper with the signature by replacing last few characters
		const tampered = token.slice(0, -5) + 'XXXXX';

		await expect(verifyFirebaseToken(tampered, TEST_PROJECT_ID)).rejects.toThrow(
			'Invalid token signature',
		);
	});
});
