import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});

import handler from '../walk-partners';

describe('GET /api/walk-partners', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns 400 when dog_id is missing', async () => {
		await handler(mockRequest({ method: 'GET', query: {} }), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id query param is required' });
	});

	it('returns 405 for unsupported methods', async () => {
		await handler(mockRequest({ method: 'POST' }), res);

		expect(res._status).toBe(405);
	});

	it('returns walk partners with relationship levels', async () => {
		mockPool._setResults([{
			rows: [
				{ dog_id: 5, dog_name: 'Boczek', last_shared_walk: new Date('2026-05-27'), level: 'parallel_caution', notes: null },
				{ dog_id: 8, dog_name: 'Burbon', last_shared_walk: new Date('2026-05-16'), level: 'contact_caution', notes: 'seeded' },
				{ dog_id: 12, dog_name: 'Piku', last_shared_walk: new Date('2026-05-27'), level: null, notes: null },
			],
		}]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '1' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([
			{ dog_id: 5, dog_name: 'Boczek', last_shared_walk: '2026-05-27', level: 'parallel_caution', notes: null },
			{ dog_id: 8, dog_name: 'Burbon', last_shared_walk: '2026-05-16', level: 'contact_caution', notes: 'seeded' },
			{ dog_id: 12, dog_name: 'Piku', last_shared_walk: '2026-05-27', level: null, notes: null },
		]);
	});

	it('returns empty array when no partners found', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '99' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([]);
	});

	it('queries with correct dog_id parameter', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '42' } }), res);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('my.dog_id = $1'),
			['42'],
		);
	});
});
