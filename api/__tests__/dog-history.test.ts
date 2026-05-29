import { createMockPool, mockRequest, mockResponse, MockResponse } from './helpers';

const mockPool = createMockPool();
jest.mock('../connection', () => mockPool);

import handler from '../dog-history';

describe('GET /api/dog-history', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		jest.spyOn(console, 'log').mockImplementation(() => {});
	});

	it('returns walk history for a dog', async () => {
		const walks = [
			{ id: 1, walk_date: '2026-03-28', group_index: null, notes: null, volunteer_name: 'Anna Kowalska' },
		];
		mockPool._setResults([{ rows: walks }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '1' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([
			{
				walk_date: '2026-03-28',
				volunteer_name: 'Anna Kowalska',
				group_index: null,
				notes: null,
				group_dogs: [],
			},
		]);
	});

	it('includes group dogs when group_index is set', async () => {
		const walks = [
			{ id: 1, walk_date: '2026-03-28', group_index: 2, notes: null, volunteer_name: 'Anna Kowalska' },
		];
		const groupDogs = [
			{ dog_id: 3, dog_name: 'Reksio' },
		];
		mockPool._setResults([{ rows: walks }, { rows: groupDogs }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '1' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([
			{
				walk_date: '2026-03-28',
				volunteer_name: 'Anna Kowalska',
				group_index: 2,
				notes: null,
				group_dogs: [{ dog_id: 3, dog_name: 'Reksio' }],
			},
		]);
	});

	it('returns 400 when dog_id is missing', async () => {
		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id query param is required' });
	});

	it('formats Date objects as yyyy-MM-dd strings', async () => {
		const walks = [
			{ id: 1, walk_date: new Date('2026-05-29'), group_index: null, notes: null, volunteer_name: 'Jan Nowak' },
		];
		mockPool._setResults([{ rows: walks }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '1' } }), res);

		expect(res._status).toBe(200);
		expect((res._body as any[])[0].walk_date).toBe('2026-05-29');
	});

	it('returns 405 for unsupported methods', async () => {
		await handler(mockRequest({ method: 'POST' }), res);
		expect(res._status).toBe(405);
	});
});
