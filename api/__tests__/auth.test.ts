import type { VercelRequest } from '@vercel/node';
import { createMockPool, mockResponse, type MockPool } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});

jest.mock('../_lib/firebase-token', () => ({ verifyFirebaseToken: jest.fn() }));

import { verifyFirebaseToken } from '../_lib/firebase-token';
import { getAuthUser, requireRole, signIn, userToJson } from '../_lib/auth';

const verifyMock = verifyFirebaseToken as jest.Mock;

const withToken = (token = 'good-token') =>
	({ headers: { authorization: `Bearer ${token}` } }) as unknown as VercelRequest;
const anonymous = { headers: {} } as unknown as VercelRequest;

const identity = {
	sub: 'uid-1',
	email: 'Anna@Gmail.com',
	email_verified: true,
	name: 'Anna K',
	picture: 'https://photo',
};

const userRow = {
	id: 5,
	email: 'anna@gmail.com',
	display_name: 'Anna K',
	photo_url: 'https://photo',
	volunteer_id: 7,
	role: 'volunteer',
};

describe('auth', () => {
	const originalEnv = process.env;

	beforeEach(() => {
		mockPool.query.mockReset();
		verifyMock.mockReset();
		verifyMock.mockResolvedValue(identity);
		process.env = { ...originalEnv };
		jest.spyOn(console, 'warn').mockImplementation(() => {});
	});

	afterAll(() => {
		process.env = originalEnv;
	});

	describe('getAuthUser', () => {
		it('returns null without an Authorization header', async () => {
			expect(await getAuthUser(anonymous)).toBeNull();
			expect(verifyMock).not.toHaveBeenCalled();
		});

		it('returns null when the token does not verify', async () => {
			verifyMock.mockRejectedValue(new Error('Token expired'));
			expect(await getAuthUser(withToken())).toBeNull();
		});

		it('returns null for unverified emails', async () => {
			verifyMock.mockResolvedValue({ ...identity, email_verified: false });
			expect(await getAuthUser(withToken())).toBeNull();
			expect(mockPool.query).not.toHaveBeenCalled();
		});

		it('returns null for tokens without an email', async () => {
			verifyMock.mockResolvedValue({ ...identity, email: undefined });
			expect(await getAuthUser(withToken())).toBeNull();
		});

		it('looks the user up by Firebase UID', async () => {
			mockPool.query.mockResolvedValue({ rows: [userRow] });
			const user = await getAuthUser(withToken());
			expect(user).toEqual({
				id: 5,
				email: 'anna@gmail.com',
				displayName: 'Anna K',
				photoUrl: 'https://photo',
				volunteerId: 7,
				role: 'volunteer',
			});
			expect(mockPool.query).toHaveBeenCalledWith(expect.stringContaining('WHERE firebase_uid = $1'), ['uid-1']);
		});

		it('returns null when the account was never signed in', async () => {
			mockPool.query.mockResolvedValue({ rows: [] });
			expect(await getAuthUser(withToken())).toBeNull();
		});

		it('verifies against the default Firebase project unless overridden', async () => {
			mockPool.query.mockResolvedValue({ rows: [] });
			await getAuthUser(withToken('t1'));
			expect(verifyMock).toHaveBeenLastCalledWith('t1', 'shelter-app-cf77a');

			process.env.FIREBASE_PROJECT_ID = 'other-project';
			await getAuthUser(withToken('t2'));
			expect(verifyMock).toHaveBeenLastCalledWith('t2', 'other-project');
		});
	});

	describe('signIn', () => {
		it('returns null for anonymous requests', async () => {
			expect(await signIn(anonymous)).toBeNull();
		});

		it('upserts by lower-cased email, keeping the existing role', async () => {
			mockPool.query.mockResolvedValue({ rows: [userRow] });
			const user = await signIn(withToken());
			expect(user?.role).toBe('volunteer');

			const [sql, params] = mockPool.query.mock.calls[0];
			expect(sql).toContain('ON CONFLICT (email) DO UPDATE');
			expect(params).toEqual(['uid-1', 'anna@gmail.com', 'Anna K', 'https://photo', false]);
		});

		it('passes null profile fields when Google omits them', async () => {
			verifyMock.mockResolvedValue({ sub: 'uid-2', email: 'x@y.pl', email_verified: true });
			mockPool.query.mockResolvedValue({ rows: [{ ...userRow, display_name: null, photo_url: null }] });
			const user = await signIn(withToken());
			expect(mockPool.query.mock.calls[0][1]).toEqual(['uid-2', 'x@y.pl', null, null, false]);
			expect(user?.displayName).toBeNull();
		});

		it('promotes emails listed in SUPER_ADMIN_EMAILS', async () => {
			process.env.SUPER_ADMIN_EMAILS = 'someone@else.pl, ANNA@gmail.com';
			mockPool.query.mockResolvedValue({ rows: [{ ...userRow, role: 'super_admin' }] });
			await signIn(withToken());
			expect(mockPool.query.mock.calls[0][1][4]).toBe(true);
		});
	});

	describe('requireRole', () => {
		it('sends 401 for anonymous requests', async () => {
			const res = mockResponse();
			expect(await requireRole(anonymous, res, 'volunteer')).toBeNull();
			expect(res._status).toBe(401);
		});

		it('sends 403 when the role is too low', async () => {
			mockPool.query.mockResolvedValue({ rows: [userRow] });
			const res = mockResponse();
			expect(await requireRole(withToken(), res, 'admin')).toBeNull();
			expect(res._status).toBe(403);
		});

		it('returns the user when the role is sufficient', async () => {
			mockPool.query.mockResolvedValue({ rows: [userRow] });
			const res = mockResponse();
			expect((await requireRole(withToken(), res, 'volunteer'))?.id).toBe(5);
			expect(res.status).not.toHaveBeenCalled();
		});
	});

	it('userToJson uses the API snake_case shape', () => {
		expect(
			userToJson({ id: 1, email: 'a@b.pl', displayName: null, photoUrl: null, volunteerId: null, role: 'pending' }),
		).toEqual({ id: 1, email: 'a@b.pl', display_name: null, photo_url: null, volunteer_id: null, role: 'pending' });
	});
});
