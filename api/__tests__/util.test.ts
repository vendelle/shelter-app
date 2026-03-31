import { handleError, setCorsHeaders } from '../util';
import { mockResponse, type MockResponse } from './helpers';

describe('util', () => {
	describe('setCorsHeaders', () => {
		it('sets all required CORS headers', () => {
			const res = mockResponse();
			setCorsHeaders(res);

			expect(res.setHeader).toHaveBeenCalledWith('Access-Control-Allow-Origin', '*');
			expect(res.setHeader).toHaveBeenCalledWith(
				'Access-Control-Allow-Methods',
				'GET,POST,PUT,DELETE,OPTIONS',
			);
			expect(res.setHeader).toHaveBeenCalledWith(
				'Access-Control-Allow-Headers',
				'Content-Type',
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
});
