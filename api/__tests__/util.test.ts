import { handleError, setCorsHeaders } from '../_lib/util';
import { mockResponse, type MockResponse } from './helpers';

describe('util', () => {
	describe('setCorsHeaders', () => {
		it('sets all required CORS headers', () => {
			const res = mockResponse();
			setCorsHeaders(res);

			expect(res.setHeader).toHaveBeenCalledWith('Access-Control-Allow-Origin', '*');
			expect(res.setHeader).toHaveBeenCalledWith(
				'Access-Control-Allow-Methods',
				'GET,POST,PUT,PATCH,DELETE,OPTIONS',
			);
			expect(res.setHeader).toHaveBeenCalledWith(
				'Access-Control-Allow-Headers',
				'Content-Type, Authorization',
			);
		});
	});

	describe('handleError', () => {
		let res: MockResponse;

		beforeEach(() => {
			res = mockResponse();
			// Suppress console.error in test output
			jest.spyOn(console, 'error').mockImplementation(() => {});
		});

		afterEach(() => {
			jest.restoreAllMocks();
		});

		it('returns 500 with error message for Error instances', () => {
			handleError(new Error('something broke'), res);

			expect(res._status).toBe(500);
			expect(res._body).toEqual({ error: 'something broke' });
		});

		it('returns 500 with generic message for non-Error values', () => {
			handleError('string error', res);

			expect(res._status).toBe(500);
			expect(res._body).toEqual({ error: 'An unknown error occurred' });
		});

		it('logs the error to console', () => {
			const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
			const err = new Error('test');
			handleError(err, res);

			expect(spy).toHaveBeenCalledWith('API error:', err);
		});
	});

	describe('hasColumn', () => {
		let pool: any;

		beforeEach(() => {
			jest.resetModules();
			// Mock the pool module before importing util
			jest.doMock('../_lib/connection', () => ({
				__esModule: true,
				default: {
					query: jest.fn(),
				},
			}));
		});

		afterEach(() => {
			jest.unmock('../_lib/connection');
		});

		it('returns true when column exists', async () => {
			pool = require('../_lib/connection').default;
			pool.query.mockResolvedValueOnce({ rows: [{ '1': 1 }] });

			const util = await import('../_lib/util');
			const result = await util.hasColumn('dogs', 'region');

			expect(result).toBe(true);
			expect(pool.query).toHaveBeenCalledWith(
				`SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2 LIMIT 1`,
				['dogs', 'region'],
			);
		});

		it('returns false when column does not exist', async () => {
			pool = require('../_lib/connection').default;
			pool.query.mockResolvedValueOnce({ rows: [] });

			const util = await import('../_lib/util');
			const result = await util.hasColumn('dogs', 'nonexistent');

			expect(result).toBe(false);
			expect(pool.query).toHaveBeenCalledWith(
				`SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2 LIMIT 1`,
				['dogs', 'nonexistent'],
			);
		});

		it('caches column existence check', async () => {
			pool = require('../_lib/connection').default;
			pool.query.mockResolvedValueOnce({ rows: [{ '1': 1 }] });

			const util = await import('../_lib/util');

			// First call should query the database
			const result1 = await util.hasColumn('dogs', 'region');
			expect(result1).toBe(true);
			expect(pool.query).toHaveBeenCalledTimes(1);

			// Second call should use cache
			const result2 = await util.hasColumn('dogs', 'region');
			expect(result2).toBe(true);
			expect(pool.query).toHaveBeenCalledTimes(1); // Still 1, not 2
		});

		it('differentiates cache by table.column', async () => {
			pool = require('../_lib/connection').default;
			pool.query.mockResolvedValueOnce({ rows: [{ '1': 1 }] });
			pool.query.mockResolvedValueOnce({ rows: [] });

			const util = await import('../_lib/util');

			const result1 = await util.hasColumn('dogs', 'region');
			expect(result1).toBe(true);

			const result2 = await util.hasColumn('walks', 'region');
			expect(result2).toBe(false);

			expect(pool.query).toHaveBeenCalledTimes(2);
		});

		it('cache can be cleared', async () => {
			pool = require('../_lib/connection').default;
			pool.query.mockResolvedValueOnce({ rows: [{ '1': 1 }] });
			pool.query.mockResolvedValueOnce({ rows: [{ '1': 1 }] });

			const util = await import('../_lib/util');

			// First call
			let result = await util.hasColumn('dogs', 'region');
			expect(result).toBe(true);
			expect(pool.query).toHaveBeenCalledTimes(1);

			// Clear cache
			util.clearColumnCache();

			// Second call should hit database again
			result = await util.hasColumn('dogs', 'region');
			expect(result).toBe(true);
			expect(pool.query).toHaveBeenCalledTimes(2);
		});
	});

	describe('clearColumnCache', () => {
		it('clears all cached column checks', async () => {
			jest.resetModules();
			jest.doMock('../_lib/connection', () => ({
				__esModule: true,
				default: {
					query: jest.fn(),
				},
			}));

			const pool = require('../_lib/connection').default;
			pool.query.mockResolvedValue({ rows: [{ '1': 1 }] });

			const util = await import('../_lib/util');

			// Cache a result
			await util.hasColumn('dogs', 'region');
			expect(pool.query).toHaveBeenCalledTimes(1);

			// Clear the cache
			util.clearColumnCache();

			// Next call should query again
			await util.hasColumn('dogs', 'region');
			expect(pool.query).toHaveBeenCalledTimes(2);

			jest.unmock('../_lib/connection');
		});
	});
});
