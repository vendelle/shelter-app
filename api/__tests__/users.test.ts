import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool, getPool: () => mockPool };
});

// Mock firebase-token verification
const mockVerifyFirebaseToken = jest.fn();
jest.mock('../_lib/firebase-token', () => ({
	verifyFirebaseToken: (...args: unknown[]) => mockVerifyFirebaseToken(...args),
}));

process.env.FIREBASE_PROJECT_ID = 'test-project';

import handler from '../users';

const superAdminPayload = {
	sub: 'admin-uid-1',
	email: 'admin@example.com',
	name: 'Admin',
	picture: null,
	iss: 'https://securetoken.google.com/test-project',
	aud: 'test-project',
	exp: Math.floor(Date.now() / 1000) + 3600,
	iat: Math.floor(Date.now() / 1000) - 60,
	auth_time: Math.floor(Date.now() / 1000) - 120,
};

const superAdminRow = {
	id: 1, firebase_uid: 'admin-uid-1', email: 'admin@example.com',
	display_name: 'Admin', photo_url: null,
	volunteer_id: null, role: 'super_admin',
};

const volunteerPayload = {
	...superAdminPayload,
	sub: 'vol-uid-1',
	email: 'vol@example.com',
};

const volunteerRow = {
	id: 2, firebase_uid: 'vol-uid-1', email: 'vol@example.com',
	display_name: 'Volunteer', photo_url: null,
	volunteer_id: 5, role: 'volunteer',
};

function authRequest(overrides: Parameters<typeof mockRequest>[0] = {}) {
	return mockRequest({
		...overrides,
		headers: { authorization: 'Bearer valid-token', ...overrides.headers },
	});
}

describe('GET /api/users', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		mockVerifyFirebaseToken.mockReset();
	});

	it('returns list of users for super_admin', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		const users = [
			{ ...superAdminRow, volunteer_first_name: null, volunteer_last_name: null },
			{ ...volunteerRow, volunteer_first_name: 'Jan', volunteer_last_name: 'Nowak' },
		];
		mockPool._setResults([
			{ rows: [superAdminRow] }, // auth middleware lookup
			{ rows: [] }, // auth middleware update
			{ rows: users }, // SELECT all users
		]);

		await handler(authRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toHaveLength(2);
	});

	it('returns 401 when not authenticated', async () => {
		await handler(mockRequest({ method: 'GET' }), res);
		expect(res._status).toBe(401);
	});

	it('returns 403 when non-super_admin tries to list users', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(volunteerPayload);
		mockPool._setResults([
			{ rows: [volunteerRow] }, // auth middleware lookup
			{ rows: [] }, // auth middleware update
		]);

		await handler(authRequest({ method: 'GET' }), res);

		expect(res._status).toBe(403);
	});
});

describe('PATCH /api/users', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		mockVerifyFirebaseToken.mockReset();
	});

	it('updates user role', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		const updatedUser = { ...volunteerRow, role: 'admin' };
		mockPool._setResults([
			{ rows: [superAdminRow] }, // auth middleware
			{ rows: [] }, // auth middleware update
			{ rows: [updatedUser] }, // UPDATE
		]);

		await handler(
			authRequest({
				method: 'PATCH',
				body: { id: 2, role: 'admin' },
			}),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toMatchObject({ role: 'admin' });
	});

	it('links volunteer to user', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] }, // auth middleware
			{ rows: [] }, // auth middleware update
			{ rows: [{ id: 10 }] }, // SELECT volunteers
			{ rows: [] }, // SELECT users WHERE volunteer_id (no dupe)
			{ rows: [{ ...volunteerRow, volunteer_id: 10 }] }, // UPDATE
		]);

		await handler(
			authRequest({
				method: 'PATCH',
				body: { id: 2, volunteer_id: 10 },
			}),
			res,
		);

		expect(res._status).toBe(200);
	});

	it('rejects invalid role', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
		]);

		await handler(
			authRequest({
				method: 'PATCH',
				body: { id: 2, role: 'superuser' },
			}),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'Invalid role. Must be one of: pending, volunteer, admin, super_admin' });
	});

	it('prevents super_admin from demoting themselves', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
		]);

		await handler(
			authRequest({
				method: 'PATCH',
				body: { id: 1, role: 'admin' }, // same id as super_admin
			}),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'Cannot change your own role' });
	});

	it('returns 400 when id is missing', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { role: 'admin' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'id is required' });
	});

	it('returns 400 when no fields to update', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { id: 2 } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'No fields to update' });
	});

	it('returns 404 when user not found', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
			{ rows: [] }, // UPDATE returns nothing
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { id: 999, role: 'volunteer' } }),
			res,
		);

		expect(res._status).toBe(404);
	});

	it('returns 409 when volunteer already linked', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
			{ rows: [{ id: 10 }] }, // volunteer exists
			{ rows: [{ id: 99 }] }, // already linked to another user
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { id: 2, volunteer_id: 10 } }),
			res,
		);

		expect(res._status).toBe(409);
	});

	it('returns 400 when volunteer not found', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
			{ rows: [] }, // volunteer not found
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { id: 2, volunteer_id: 999 } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'Volunteer not found' });
	});

	it('allows unlinking volunteer (null)', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
			{ rows: [{ ...volunteerRow, volunteer_id: null }] }, // UPDATE
		]);

		await handler(
			authRequest({ method: 'PATCH', body: { id: 2, volunteer_id: null } }),
			res,
		);

		expect(res._status).toBe(200);
	});
});

describe('Method handling', () => {
	it('handles OPTIONS preflight', async () => {
		const res = mockResponse();
		await handler(mockRequest({ method: 'OPTIONS' }), res);
		expect(res._status).toBe(200);
	});

	it('rejects unsupported methods', async () => {
		const res = mockResponse();
		mockVerifyFirebaseToken.mockResolvedValue(superAdminPayload);
		mockPool._setResults([
			{ rows: [superAdminRow] },
			{ rows: [] },
		]);
		await handler(authRequest({ method: 'DELETE' }), res);
		expect(res._status).toBe(405);
	});
});
