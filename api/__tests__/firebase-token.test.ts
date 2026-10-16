import { generateKeyPairSync, sign } from 'crypto';
import { _resetCertCache, verifyFirebaseToken } from '../_lib/firebase-token';

const PROJECT = 'test-project';
const KID = 'key-1';
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const publicPem = publicKey.export({ type: 'spki', format: 'pem' }).toString();

const b64 = (value: object) => Buffer.from(JSON.stringify(value)).toString('base64url');

function makeToken(
	payloadOverrides: Record<string, unknown> = {},
	headerOverrides: Record<string, unknown> = {},
): string {
	const now = Math.floor(Date.now() / 1000);
	const header = b64({ alg: 'RS256', kid: KID, typ: 'JWT', ...headerOverrides });
	const payload = b64({
		sub: 'uid-123',
		email: 'anna@gmail.com',
		email_verified: true,
		iss: `https://securetoken.google.com/${PROJECT}`,
		aud: PROJECT,
		iat: now - 10,
		exp: now + 3600,
		auth_time: now - 10,
		...payloadOverrides,
	});
	const signature = sign('RSA-SHA256', Buffer.from(`${header}.${payload}`), privateKey).toString('base64url');
	return `${header}.${payload}.${signature}`;
}

describe('verifyFirebaseToken', () => {
	let fetchMock: jest.Mock;

	beforeEach(() => {
		_resetCertCache();
		fetchMock = jest.fn().mockResolvedValue({
			ok: true,
			headers: new Headers({ 'cache-control': 'public, max-age=600' }),
			json: async () => ({ [KID]: publicPem }),
		});
		global.fetch = fetchMock;
	});

	it('returns the payload of a valid token', async () => {
		const payload = await verifyFirebaseToken(makeToken(), PROJECT);
		expect(payload.sub).toBe('uid-123');
		expect(payload.email).toBe('anna@gmail.com');
	});

	it('caches Google certificates between calls', async () => {
		await verifyFirebaseToken(makeToken(), PROJECT);
		await verifyFirebaseToken(makeToken(), PROJECT);
		expect(fetchMock).toHaveBeenCalledTimes(1);
	});

	it('falls back to a one-hour cache without a max-age header', async () => {
		fetchMock.mockResolvedValue({ ok: true, headers: new Headers(), json: async () => ({ [KID]: publicPem }) });
		await verifyFirebaseToken(makeToken(), PROJECT);
		await verifyFirebaseToken(makeToken(), PROJECT);
		expect(fetchMock).toHaveBeenCalledTimes(1);
	});

	it('fails when certificates cannot be fetched', async () => {
		fetchMock.mockResolvedValue({ ok: false, status: 503 });
		await expect(verifyFirebaseToken(makeToken(), PROJECT)).rejects.toThrow('Failed to fetch Google certs: 503');
	});

	it.each([
		['not a JWT', 'abc.def', 'expected 3 parts'],
		['garbage segments', 'a.b.c', 'malformed'],
	])('rejects %s', async (_label, token, message) => {
		await expect(verifyFirebaseToken(token, PROJECT)).rejects.toThrow(message);
	});

	it('rejects non-RS256 tokens', async () => {
		await expect(verifyFirebaseToken(makeToken({}, { alg: 'HS256' }), PROJECT)).rejects.toThrow('Unsupported algorithm');
	});

	it('rejects unknown key IDs', async () => {
		await expect(verifyFirebaseToken(makeToken({}, { kid: 'other' }), PROJECT)).rejects.toThrow('unknown key ID');
	});

	it('rejects tampered payloads', async () => {
		const [header, , signature] = makeToken().split('.');
		const forged = `${header}.${b64({ sub: 'attacker' })}.${signature}`;
		await expect(verifyFirebaseToken(forged, PROJECT)).rejects.toThrow('Invalid token signature');
	});

	it.each([
		['expired', { exp: Math.floor(Date.now() / 1000) - 1 }, 'Token expired'],
		['issued in the future', { iat: Math.floor(Date.now() / 1000) + 3600 }, 'issued in the future'],
		['auth_time in the future', { auth_time: Math.floor(Date.now() / 1000) + 3600 }, 'auth_time in the future'],
		['another issuer', { iss: 'https://securetoken.google.com/other' }, 'Invalid issuer'],
		['another audience', { aud: 'other' }, 'Invalid audience'],
		['no subject', { sub: '' }, 'Missing subject'],
	])('rejects tokens with %s', async (_label, overrides, message) => {
		await expect(verifyFirebaseToken(makeToken(overrides), PROJECT)).rejects.toThrow(message);
	});
});
