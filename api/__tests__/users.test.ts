import { createMockPool, mockAuth, mockRequest, mockResponse, TEST_USERS, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});

jest.mock('../_lib/auth', () => ({
	...jest.requireActual('../_lib/auth'),
	...require('./helpers').authModuleMock,
	signIn: jest.fn(),
}));

import { signIn } from '../_lib/auth';
import handler from '../users';

const signInMock = signIn as jest.Mock;
const owner = TEST_USERS.super_admin;

const listedUser = {
	id: 9,
	email: 'jan@gmail.com',
	display_name: null,
	photo_url: null,
	volunteer_id: null,
	role: 'volunteer',
	invite_pending: true,
};

describe('/api/users', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		mockPool._setResults([]);
		mockAuth.user = owner;
	});

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);
		expect(res._status).toBe(200);
	});

	describe('GET ?me (sign in)', () => {
		it('returns the signed-in account', async () => {
			signInMock.mockResolvedValue(TEST_USERS.volunteer);
			await handler(mockRequest({ method: 'GET', query: { me: '' } }), res);
			expect(res._status).toBe(200);
			expect(res._body).toEqual({
				id: 2,
				email: 'volunteer@test.pl',
				display_name: 'Vol',
				photo_url: null,
				volunteer_id: 7,
				role: 'volunteer',
			});
		});

		it('sends 401 without a valid Google sign-in', async () => {
			signInMock.mockResolvedValue(null);
			await handler(mockRequest({ method: 'GET', query: { me: '' } }), res);
			expect(res._status).toBe(401);
		});
	});

	describe('account management', () => {
		it.each([
			['anonymous', null, 401],
			['volunteer', TEST_USERS.volunteer, 403],
			['admin', TEST_USERS.admin, 403],
		])('is closed to %s callers', async (_label, user, status) => {
			mockAuth.user = user;
			await handler(mockRequest({ method: 'GET' }), res);
			expect(res._status).toBe(status);
			expect(mockPool.query).not.toHaveBeenCalled();
		});

		it('lists accounts with pending ones first', async () => {
			mockPool._setResults([{ rows: [listedUser] }]);
			await handler(mockRequest({ method: 'GET' }), res);
			expect(res._status).toBe(200);
			expect(res._body).toEqual([listedUser]);
			expect(mockPool.query.mock.calls[0][0]).toContain("ORDER BY (u.role = 'pending') DESC");
		});

		it('returns 405 for unsupported methods', async () => {
			await handler(mockRequest({ method: 'PUT' }), res);
			expect(res._status).toBe(405);
		});
	});

	describe('POST (invite)', () => {
		it('creates an invite with a normalised email', async () => {
			mockPool._setResults([{ rows: [{ id: 9 }] }, { rows: [listedUser] }]);
			await handler(mockRequest({ method: 'POST', body: { email: '  Jan@Gmail.com ', role: 'volunteer' } }), res);
			expect(res._status).toBe(201);
			expect(res._body).toEqual(listedUser);
			expect(mockPool.query.mock.calls[0][1]).toEqual(['jan@gmail.com', 'volunteer', null]);
		});

		it('links a volunteer profile when given', async () => {
			mockPool._setResults([{ rows: [{ id: 7 }] }, { rows: [] }, { rows: [{ id: 9 }] }, { rows: [listedUser] }]);
			await handler(mockRequest({ method: 'POST', body: { email: 'jan@gmail.com', role: 'admin', volunteer_id: 7 } }), res);
			expect(res._status).toBe(201);
			expect(mockPool.query.mock.calls[2][1]).toEqual(['jan@gmail.com', 'admin', 7]);
		});

		it.each([
			[{ email: 'not-an-email', role: 'volunteer' }, 'A valid email is required'],
			[{ role: 'volunteer' }, 'A valid email is required'],
			[{ email: 'jan@gmail.com', role: 'boss' }, 'role must be one of: pending, volunteer, admin, super_admin, exporter'],
			[{ email: 'jan@gmail.com', role: 'volunteer', volunteer_id: 'x' }, 'volunteer_id must be an integer'],
		])('rejects invalid input %j', async (body, error) => {
			await handler(mockRequest({ method: 'POST', body }), res);
			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error });
		});

		it('rejects unknown volunteers', async () => {
			await handler(mockRequest({ method: 'POST', body: { email: 'jan@gmail.com', role: 'volunteer', volunteer_id: 404 } }), res);
			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'Volunteer not found' });
		});

		it('rejects volunteers already linked to another account', async () => {
			mockPool._setResults([{ rows: [{ id: 7 }] }, { rows: [{ id: 3 }] }]);
			await handler(mockRequest({ method: 'POST', body: { email: 'jan@gmail.com', role: 'volunteer', volunteer_id: 7 } }), res);
			expect(res._status).toBe(409);
		});

		it('rejects emails that already have an account', async () => {
			await handler(mockRequest({ method: 'POST', body: { email: 'jan@gmail.com', role: 'volunteer' } }), res);
			expect(res._status).toBe(409);
			expect(res._body).toEqual({ error: 'An account with this email already exists' });
		});
	});

	describe('PATCH', () => {
		it('changes a role', async () => {
			mockPool._setResults([{ rows: [{ id: 9 }] }, { rows: [{ ...listedUser, role: 'admin' }] }]);
			await handler(mockRequest({ method: 'PATCH', body: { id: 9, role: 'admin' } }), res);
			expect(res._status).toBe(200);
			expect(mockPool.query.mock.calls[0]).toEqual(['UPDATE users SET role = $1 WHERE id = $2 RETURNING id', ['admin', 9]]);
		});

		it('changes the role and volunteer link together', async () => {
			mockPool._setResults([{ rows: [{ id: 7 }] }, { rows: [] }, { rows: [{ id: 9 }] }, { rows: [listedUser] }]);
			await handler(mockRequest({ method: 'PATCH', body: { id: 9, role: 'volunteer', volunteer_id: 7 } }), res);
			expect(res._status).toBe(200);
			expect(mockPool.query.mock.calls[2]).toEqual([
				'UPDATE users SET role = $1, volunteer_id = $2 WHERE id = $3 RETURNING id',
				['volunteer', 7, 9],
			]);
		});

		it('unlinks a volunteer with null', async () => {
			mockPool._setResults([{ rows: [{ id: 9 }] }, { rows: [listedUser] }]);
			await handler(mockRequest({ method: 'PATCH', body: { id: 9, volunteer_id: null } }), res);
			expect(res._status).toBe(200);
			expect(mockPool.query.mock.calls[0][1]).toEqual([null, 9]);
		});

		it('refuses to change your own role', async () => {
			await handler(mockRequest({ method: 'PATCH', body: { id: owner.id, role: 'volunteer' } }), res);
			expect(res._status).toBe(400);
			expect(mockPool.query).not.toHaveBeenCalled();
		});

		it.each([
			[{ role: 'admin' }, 'id is required'],
			[{ id: 9 }, 'No fields to update'],
			[{ id: 9, role: 'boss' }, 'role must be one of: pending, volunteer, admin, super_admin, exporter'],
		])('rejects invalid input %j', async (body, error) => {
			await handler(mockRequest({ method: 'PATCH', body }), res);
			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error });
		});

		it('rejects linking a volunteer taken by another account', async () => {
			mockPool._setResults([{ rows: [{ id: 7 }] }, { rows: [{ id: 3 }] }]);
			await handler(mockRequest({ method: 'PATCH', body: { id: 9, volunteer_id: 7 } }), res);
			expect(res._status).toBe(409);
		});

		it('returns 404 for unknown accounts', async () => {
			await handler(mockRequest({ method: 'PATCH', body: { id: 404, role: 'admin' } }), res);
			expect(res._status).toBe(404);
		});
	});

	describe('DELETE', () => {
		it('removes an account', async () => {
			mockPool._setResults([{ rows: [{ id: 9 }] }]);
			await handler(mockRequest({ method: 'DELETE', query: { id: '9' } }), res);
			expect(res._status).toBe(204);
		});

		it('requires an id', async () => {
			await handler(mockRequest({ method: 'DELETE', query: {} }), res);
			expect(res._status).toBe(400);
		});

		it('refuses to delete your own account', async () => {
			await handler(mockRequest({ method: 'DELETE', query: { id: String(owner.id) } }), res);
			expect(res._status).toBe(400);
		});

		it('returns 404 for unknown accounts', async () => {
			await handler(mockRequest({ method: 'DELETE', query: { id: '404' } }), res);
			expect(res._status).toBe(404);
		});
	});

	it('returns 500 on database errors', async () => {
		jest.spyOn(console, 'error').mockImplementation(() => {});
		mockPool.query.mockRejectedValueOnce(new Error('db down'));
		await handler(mockRequest({ method: 'GET' }), res);
		expect(res._status).toBe(500);
	});
});
