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

// Set FIREBASE_PROJECT_ID for auth-middleware
process.env.FIREBASE_PROJECT_ID = 'test-project';

import handler from '../auth';

const validPayload = {
	sub: 'firebase-uid-123',
	email: 'volunteer@example.com',
	name: 'Test Volunteer',
	picture: 'https://example.com/pic.jpg',
	iss: 'https://securetoken.google.com/test-project',
	aud: 'test-project',
	exp: Math.floor(Date.now() / 1000) + 3600,
	iat: Math.floor(Date.now() / 1000) - 60,
	auth_time: Math.floor(Date.now() / 1000) - 120,
};

beforeEach(() => {
	mockVerifyFirebaseToken.mockReset();
});

describe('POST /api/auth', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('creates a new user on first login', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [] }, // SELECT users WHERE firebase_uid
			{ rows: [{ id: 1, firebase_uid: 'firebase-uid-123', email: 'volunteer@example.com', display_name: 'Test Volunteer', photo_url: 'https://example.com/pic.jpg', volunteer_id: null, role: 'pending', created_at: new Date(), last_login_at: new Date() }] }, // INSERT
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token' },
			}),
			res,
		);

		expect(res._status).toBe(201);
		expect(res._body).toMatchObject({
			firebase_uid: 'firebase-uid-123',
			email: 'volunteer@example.com',
			role: 'pending',
		});
	});

	it('returns existing user on subsequent login', async () => {
		const existingRow = {
			id: 5, firebase_uid: 'firebase-uid-123', email: 'volunteer@example.com',
			display_name: 'Test Volunteer', photo_url: 'https://example.com/pic.jpg',
			volunteer_id: null, role: 'volunteer', created_at: new Date(), last_login_at: new Date(),
		};
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [existingRow] }, // SELECT users WHERE firebase_uid
			{ rows: [] }, // UPDATE last_login_at
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token' },
			}),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toMatchObject({
			id: 5,
			role: 'volunteer',
		});
	});

	it('creates a new user with volunteer link', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [] }, // SELECT users WHERE firebase_uid
			{ rows: [{ id: 3 }] }, // SELECT volunteers WHERE id
			{ rows: [] }, // SELECT users WHERE volunteer_id (no dupe)
			{ rows: [{ id: 1, firebase_uid: 'firebase-uid-123', email: 'volunteer@example.com', display_name: 'Test Volunteer', photo_url: 'https://example.com/pic.jpg', volunteer_id: 3, role: 'pending', created_at: new Date(), last_login_at: new Date() }] }, // INSERT
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token', volunteer_id: 3 },
			}),
			res,
		);

		expect(res._status).toBe(201);
		expect(res._body).toMatchObject({
			volunteer_id: 3,
			role: 'pending',
		});
	});

	it('returns 409 when volunteer already linked to another account', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [] }, // SELECT users WHERE firebase_uid
			{ rows: [{ id: 3 }] }, // SELECT volunteers WHERE id
			{ rows: [{ id: 99 }] }, // SELECT users WHERE volunteer_id → already linked
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token', volunteer_id: 3 },
			}),
			res,
		);

		expect(res._status).toBe(409);
		expect(res._body).toEqual({ error: 'Volunteer already linked to another account' });
	});

	it('returns 400 when volunteer_id does not exist', async () => {
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [] }, // SELECT users WHERE firebase_uid
			{ rows: [] }, // SELECT volunteers WHERE id → not found
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token', volunteer_id: 999 },
			}),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'Volunteer not found' });
	});

	it('returns 400 when id_token is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: {} }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'id_token is required' });
	});

	it('returns 401 when token is invalid', async () => {
		mockVerifyFirebaseToken.mockRejectedValue(new Error('Token expired'));

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'expired-token' },
			}),
			res,
		);

		expect(res._status).toBe(401);
		expect(res._body).toEqual({ error: 'Token expired' });
	});

	it('links volunteer on subsequent login if not already linked', async () => {
		const existingRow = {
			id: 5, firebase_uid: 'firebase-uid-123', email: 'volunteer@example.com',
			display_name: 'Test Volunteer', photo_url: null,
			volunteer_id: null, role: 'volunteer', created_at: new Date(), last_login_at: new Date(),
		};
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [existingRow] }, // SELECT users WHERE firebase_uid
			{ rows: [{ id: 7 }] }, // SELECT volunteers WHERE id
			{ rows: [] }, // SELECT users WHERE volunteer_id (no dupe)
			{ rows: [] }, // UPDATE with volunteer_id
		]);

		await handler(
			mockRequest({
				method: 'POST',
				body: { id_token: 'valid-firebase-token', volunteer_id: 7 },
			}),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toMatchObject({ volunteer_id: 7 });
	});

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);
		expect(res._status).toBe(200);
	});

	it('rejects unsupported methods', async () => {
		await handler(mockRequest({ method: 'DELETE' }), res);
		expect(res._status).toBe(405);
	});

	it('returns 500 when FIREBASE_PROJECT_ID is missing', async () => {
		const original = process.env.FIREBASE_PROJECT_ID;
		delete process.env.FIREBASE_PROJECT_ID;

		await handler(
			mockRequest({ method: 'POST', body: { id_token: 'some-token' } }),
			res,
		);

		expect(res._status).toBe(500);
		expect(res._body).toEqual({ error: 'Server misconfigured: missing FIREBASE_PROJECT_ID' });
		process.env.FIREBASE_PROJECT_ID = original;
	});
});

describe('GET /api/auth', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns current user when authenticated', async () => {
		const userRow = {
			id: 1, firebase_uid: 'uid-1', email: 'test@example.com',
			display_name: 'Test', photo_url: null,
			volunteer_id: null, role: 'volunteer',
		};
		mockVerifyFirebaseToken.mockResolvedValue(validPayload);
		mockPool._setResults([
			{ rows: [userRow] }, // SELECT users WHERE firebase_uid (from middleware)
			{ rows: [] }, // UPDATE last_login_at
		]);

		await handler(
			mockRequest({
				method: 'GET',
				headers: { authorization: 'Bearer valid-token' },
			}),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toMatchObject({ email: 'test@example.com' });
	});

	it('returns 401 when not authenticated', async () => {
		await handler(mockRequest({ method: 'GET' }), res);
		expect(res._status).toBe(401);
	});
});
