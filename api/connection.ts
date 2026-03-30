import { Pool } from 'pg';

let pool: Pool | null = null;

function getPool(): Pool {
	if (pool) return pool;

	const url = process.env.DEV_DATABASE_URL || process.env.DATABASE_URL;

	console.log('[db] Initializing pool...');
	console.log('[db] DEV_DATABASE_URL set:', !!process.env.DEV_DATABASE_URL);
	console.log('[db] DATABASE_URL set:', !!process.env.DATABASE_URL);

	if (!url) {
		throw new Error(
			'No database URL found. Set DEV_DATABASE_URL or DATABASE_URL in Vercel environment variables.',
		);
	}

	pool = new Pool({ connectionString: url });
	return pool;
}

// Lazy proxy so the pool is only created when first used (not at import time)
const lazyPool = new Proxy({} as Pool, {
	get(_target, prop: keyof Pool) {
		return (getPool() as any)[prop].bind(getPool());
	},
});

export { getPool };
export default lazyPool;
