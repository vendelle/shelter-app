import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});

import handler from '../walks';

describe('GET /api/walks?format=csv', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns 400 when from/to params are missing', async () => {
		await handler(mockRequest({ method: 'GET', query: { format: 'csv' } }), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'from and to query params are required for CSV export' });
	});

	it('returns 400 when only from is provided', async () => {
		await handler(mockRequest({ method: 'GET', query: { format: 'csv', from: '2025-01-01' } }), res);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'from and to query params are required for CSV export' });
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
		expect(lines[2]).toBe('Luna,S002,2025-03-14,Jan Nowak');
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
		const lines = csv.split('\n');
		expect(lines[1]).toBe('"Rex, Jr.",S003,2025-02-10,Maria Nowak');
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
		const lines = csv.split('\n');
		expect(lines[1]).toBe('"Rex ""The Beast""",S004,2025-02-10,Jan Nowak');
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

	it('returns empty CSV (header only) when no walks in range', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({
			method: 'GET',
			query: { format: 'csv', from: '2025-01-01', to: '2025-01-31' },
		}), res);

		const csv = res._body as string;
		const lines = csv.split('\n');
		expect(lines).toHaveLength(1);
		expect(lines[0]).toBe('dog_name,shelterid,walk_date,volunteer_name');
	});

	it('passes date range params to SQL query', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({
			method: 'GET',
			query: { format: 'csv', from: '2025-03-01', to: '2025-03-31' },
		}), res);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('w.walk_date >= $1'),
			['2025-03-01', '2025-03-31'],
		);
	});

	it('filters out deleted walks', async () => {
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
