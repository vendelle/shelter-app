import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';
import { mockAuth, TEST_USERS } from './helpers';

jest.mock('../_lib/auth', () => require('./helpers').authModuleMock);

// Callers can do anything unless a test says otherwise.
beforeEach(() => {
	mockAuth.user = TEST_USERS.super_admin;
});

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return {
		__esModule: true,
		default: mockPool,
		getPool: () => mockPool,
	};
});

import handler from '../familiarity';

describe('/api/familiarity', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);

		expect(res._status).toBe(200);
		expect(res.end).toHaveBeenCalled();
	});

	it('rejects unsupported methods with 405', async () => {
		await handler(mockRequest({ method: 'POST' }), res);

		expect(res._status).toBe(405);
		expect(res._body).toEqual({ error: 'Method POST Not Allowed' });
	});

	describe('GET', () => {
		it('returns familiarity entries for a volunteer', async () => {
			const entries = [
				{ volunteer_id: 1, dog_id: 10, level: 'good' },
				{ volunteer_id: 1, dog_id: 11, level: 'never' },
			];
			mockPool._setResults([{ rows: entries }]);

			await handler(
				mockRequest({ method: 'GET', query: { volunteer_id: '1' } }),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual(entries);
		});

		it('returns 400 when volunteer_id is missing', async () => {
			await handler(mockRequest({ method: 'GET', query: {} }), res);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'volunteer_id query param is required' });
		});

		it('returns empty array when no entries exist', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(
				mockRequest({ method: 'GET', query: { volunteer_id: '999' } }),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual([]);
		});
	});

	describe('PUT', () => {
		it('upserts a familiarity entry', async () => {
			const entry = { volunteer_id: 1, dog_id: 10, level: 'good' };
			mockPool._setResults([{ rows: [entry] }]);

			await handler(
				mockRequest({ method: 'PUT', body: { volunteer_id: 1, dog_id: 10, level: 'good' } }),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual(entry);
		});

		it('returns 400 when fields are missing', async () => {
			await handler(
				mockRequest({ method: 'PUT', body: { volunteer_id: 1 } }),
				res,
			);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'volunteer_id, dog_id, and level are required' });
		});

		it('returns 400 for invalid level', async () => {
			await handler(
				mockRequest({ method: 'PUT', body: { volunteer_id: 1, dog_id: 10, level: 'unknown' } }),
				res,
			);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'level must be one of: good, difficult, never' });
		});
	});

	describe('DELETE', () => {
		it('deletes a familiarity entry', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(
				mockRequest({ method: 'DELETE', query: { volunteer_id: '1', dog_id: '10' } }),
				res,
			);

			expect(res._status).toBe(204);
			expect(res.end).toHaveBeenCalled();
		});

		it('returns 400 when params are missing', async () => {
			await handler(
				mockRequest({ method: 'DELETE', query: { volunteer_id: '1' } }),
				res,
			);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'volunteer_id and dog_id query params are required' });
		});
	});

	it('returns 500 on database error', async () => {
		jest.spyOn(console, 'error').mockImplementation(() => {});
		mockPool.query.mockRejectedValueOnce(new Error('DB down'));

		await handler(
			mockRequest({ method: 'GET', query: { volunteer_id: '1' } }),
			res,
		);

		expect(res._status).toBe(500);
		expect(res._body).toEqual({ error: 'DB down' });
	});
});

describe('/api/familiarity permissions', () => {
	let res: MockResponse;
	const ownVolunteerId = TEST_USERS.volunteer.volunteerId!;

	beforeEach(() => {
		res = mockResponse();
		mockPool.query.mockReset();
		mockPool.query.mockResolvedValue({ rows: [{}] });
	});

	it('rejects anonymous changes with 401', async () => {
		mockAuth.user = null;
		await handler(mockRequest({ method: 'PUT', body: { volunteer_id: ownVolunteerId, dog_id: 10, level: 'good' } }), res);
		expect(res._status).toBe(401);
	});

	it("lets a volunteer edit their own preferences", async () => {
		mockAuth.user = TEST_USERS.volunteer;
		await handler(mockRequest({ method: 'PUT', body: { volunteer_id: ownVolunteerId, dog_id: 10, level: 'good' } }), res);
		expect(res._status).toBe(200);
	});

	it("stops a volunteer editing someone else's preferences", async () => {
		mockAuth.user = TEST_USERS.volunteer;
		await handler(mockRequest({ method: 'PUT', body: { volunteer_id: 99, dog_id: 10, level: 'good' } }), res);
		expect(res._status).toBe(403);
		expect(mockPool.query).not.toHaveBeenCalled();
	});

	it("stops a volunteer deleting someone else's preference", async () => {
		mockAuth.user = TEST_USERS.volunteer;
		await handler(mockRequest({ method: 'DELETE', query: { volunteer_id: '99', dog_id: '10' } }), res);
		expect(res._status).toBe(403);
	});

	it('rejects pending accounts deleting preferences with 403', async () => {
		mockAuth.user = TEST_USERS.pending;
		await handler(mockRequest({ method: 'DELETE', query: { volunteer_id: '1', dog_id: '10' } }), res);
		expect(res._status).toBe(403);
	});

	it("lets an admin edit anyone's preferences", async () => {
		await handler(mockRequest({ method: 'DELETE', query: { volunteer_id: '99', dog_id: '10' } }), res);
		expect(res._status).toBe(204);
	});
});
