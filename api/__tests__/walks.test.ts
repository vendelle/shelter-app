import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});

import handler from '../walks';

describe('GET /api/walks', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	describe('JSON response', () => {
		it('returns all non-deleted walks', async () => {
			mockPool._setResults([{
				rows: [
					{ id: 1, dog_id: 10, dog_name: 'Burek', kennel: 'A1', volunteer_id: 1, volunteer_name: 'Anna K', walk_date: new Date('2025-03-15'), notes: null },
					{ id: 2, dog_id: 11, dog_name: 'Luna', kennel: 'B2', volunteer_id: 2, volunteer_name: 'Jan N', walk_date: new Date('2025-03-14'), notes: 'shy' },
				],
			}]);

			await handler(mockRequest({ method: 'GET', query: {} }), res);

			expect(res._status).toBe(200);
			expect(res._body).toHaveLength(2);
			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('deleted_at IS NULL'),
				[],
			);
		});

		it('filters walks by date', async () => {
			mockPool._setResults([{ rows: [{ id: 1 }] }]);

			await handler(mockRequest({ method: 'GET', query: { date: '2025-03-15' } }), res);

			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('w.walk_date = $1'),
				['2025-03-15'],
			);
		});

		it('filters walks by volunteer', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(mockRequest({ method: 'GET', query: { volunteer: '5' } }), res);

			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('w.volunteer_id = $1'),
				['5'],
			);
		});

		it('filters walks by dog', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(mockRequest({ method: 'GET', query: { dog: '10' } }), res);

			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('w.dog_id = $1'),
				['10'],
			);
		});

		it('combines multiple filters', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(mockRequest({
				method: 'GET',
				query: { date: '2025-03-15', volunteer: '1', dog: '10' },
			}), res);

			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('w.walk_date = $1'),
				expect.arrayContaining(['2025-03-15', '1', '10']),
			);
		});

		it('returns empty array when no walks match', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(mockRequest({ method: 'GET', query: {} }), res);

			expect(res._status).toBe(200);
			expect(res._body).toEqual([]);
		});
	});

	describe('CSV export', () => {
		it('returns 400 when from/to params are missing', async () => {
			await handler(mockRequest({ method: 'GET', query: { format: 'csv' } }), res);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'from and to query params are required for CSV export' });
		});

		it('returns 400 when only from is provided', async () => {
			await handler(mockRequest({ method: 'GET', query: { format: 'csv', from: '2025-01-01' } }), res);

			expect(res._status).toBe(400);
		});

		it('returns CSV with correct headers and content-type', async () => {
			mockPool._setResults([{
				rows: [
					{ dog_name: 'Burek', shelterid: 'S001', walk_date: new Date('2025-03-15'), volunteer_name: 'Anna Kowalska' },
					{ dog_name: 'Luna', shelterid: 'S002', walk_date: new Date('2025-03-14'), volunteer_name: 'Jan Nowak' },
				],
			}]);

			await handler(mockRequest({
				method: 'GET',
				query: { format: 'csv', from: '2025-01-01', to: '2025-03-31' },
			}), res);

			expect(res._status).toBe(200);
			expect(res._headers['Content-Type']).toBe('text/csv; charset=utf-8');
			expect(res._headers['Content-Disposition']).toBe('attachment; filename=walks_export.csv');

			const csv = res._body as string;
			const lines = csv.split('\n');
			expect(lines[0]).toBe('dog_name,shelterid,walk_date,volunteer_name');
			expect(lines[1]).toBe('Burek,S001,2025-03-15,Anna Kowalska');
		});

		it('escapes CSV values containing commas', async () => {
			mockPool._setResults([{
				rows: [
					{ dog_name: 'Rex, Jr.', shelterid: 'S003', walk_date: new Date('2025-02-10'), volunteer_name: 'Maria Nowak' },
				],
			}]);

			await handler(mockRequest({
				method: 'GET',
				query: { format: 'csv', from: '2025-01-01', to: '2025-03-31' },
			}), res);

			const csv = res._body as string;
			expect(csv).toContain('"Rex, Jr."');
		});

		it('escapes CSV values containing quotes', async () => {
			mockPool._setResults([{
				rows: [
					{ dog_name: 'Rex "The Beast"', shelterid: 'S004', walk_date: new Date('2025-02-10'), volunteer_name: 'Jan Nowak' },
				],
			}]);

			await handler(mockRequest({
				method: 'GET',
				query: { format: 'csv', from: '2025-01-01', to: '2025-03-31' },
			}), res);

			const csv = res._body as string;
			expect(csv).toContain('"Rex ""The Beast"""');
		});

		it('handles null values gracefully', async () => {
			mockPool._setResults([{
				rows: [
					{ dog_name: null, shelterid: null, walk_date: new Date('2025-02-10'), volunteer_name: null },
				],
			}]);

			await handler(mockRequest({
				method: 'GET',
				query: { format: 'csv', from: '2025-01-01', to: '2025-03-31' },
			}), res);

			const csv = res._body as string;
			const lines = csv.split('\n');
			expect(lines[1]).toBe(',,2025-02-10,');
		});

		it('filters out deleted walks in CSV', async () => {
			mockPool._setResults([{ rows: [] }]);

			await handler(mockRequest({
				method: 'GET',
				query: { format: 'csv', from: '2025-01-01', to: '2025-12-31' },
			}), res);

			expect(mockPool.query).toHaveBeenCalledWith(
				expect.stringContaining('deleted_at IS NULL'),
				expect.anything(),
			);
		});
	});
});

describe('POST /api/walks', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('creates a walk with required fields', async () => {
		mockPool._setResults([{
			rows: [{ id: 100, dog_id: 10, volunteer_id: 1, walk_date: '2025-03-15', notes: null }],
		}]);

		await handler(mockRequest({
			method: 'POST',
			body: { dog_id: 10, volunteer_id: 1, walk_date: '2025-03-15' },
		}), res);

		expect(res._status).toBe(201);
		expect(res._body).toEqual({ id: 100, dog_id: 10, volunteer_id: 1, walk_date: '2025-03-15', notes: null });
	});

	it('creates a walk without volunteer', async () => {
		mockPool._setResults([{
			rows: [{ id: 101, dog_id: 11, volunteer_id: null, walk_date: '2025-03-15', notes: null }],
		}]);

		await handler(mockRequest({
			method: 'POST',
			body: { dog_id: 11, walk_date: '2025-03-15' },
		}), res);

		expect(res._status).toBe(201);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('INSERT INTO walks'),
			[11, null, '2025-03-15', null],
		);
	});

	it('creates a walk with notes', async () => {
		mockPool._setResults([{
			rows: [{ id: 102, dog_id: 12, volunteer_id: 1, walk_date: '2025-03-15', notes: 'shy dog' }],
		}]);

		await handler(mockRequest({
			method: 'POST',
			body: { dog_id: 12, volunteer_id: 1, walk_date: '2025-03-15', notes: 'shy dog' },
		}), res);

		expect(res._status).toBe(201);
		expect((res._body as any).notes).toBe('shy dog');
	});

	it('returns 400 when dog_id is missing', async () => {
		await handler(mockRequest({
			method: 'POST',
			body: { walk_date: '2025-03-15' },
		}), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id and walk_date are required' });
	});

	it('returns 400 when walk_date is missing', async () => {
		await handler(mockRequest({
			method: 'POST',
			body: { dog_id: 10 },
		}), res);

		expect(res._status).toBe(400);
	});

	it('returns 400 when dog_id is not an integer', async () => {
		await handler(mockRequest({
			method: 'POST',
			body: { dog_id: 'not-a-number', walk_date: '2025-03-15' },
		}), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id must be an integer' });
	});
});

describe('DELETE /api/walks', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('soft-deletes a walk', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({
			method: 'DELETE',
			query: { walk_id: '100' },
		}), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({ message: 'Walk marked as deleted' });
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('UPDATE walks SET deleted_at = NOW()'),
			['100'],
		);
	});

	it('returns 400 when walk_id is missing', async () => {
		await handler(mockRequest({
			method: 'DELETE',
			query: {},
		}), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'walk_id is required' });
	});
});

describe('Unsupported methods', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns 405 for PUT requests', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'PUT' }), res);

		expect(res._status).toBe(405);
		expect(res._headers['Allow']).toContain('GET');
	});
});
