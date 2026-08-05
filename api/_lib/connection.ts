import { Pool } from 'pg';

let pool: Pool | null = null;

function getPool(): Pool {
	if (pool) return pool;

	// Fallback chain to support multiple Vercel projects and naming conventions:
	// 1. DATABASE_URL_UNPOOLED - Unpooled connection (new ASY project)
	// 2. DATABASE_URL - Regular connection (new ASY project)
	// 3. DEV_DATABASE_URL_UNPOOLED - Dev unpooled (original project)
	// 4. DEV_DATABASE_URL - Dev regular (original project)
	const url =
		process.env.DATABASE_URL_UNPOOLED ||
		process.env.DATABASE_URL ||
		process.env.DEV_DATABASE_URL_UNPOOLED ||
		process.env.DEV_DATABASE_URL;

	console.log('[db] Initializing pool...');
	console.log('[db] DATABASE_URL_UNPOOLED set:', !!process.env.DATABASE_URL_UNPOOLED);
	console.log('[db] DATABASE_URL set:', !!process.env.DATABASE_URL);
	console.log('[db] DEV_DATABASE_URL_UNPOOLED set:', !!process.env.DEV_DATABASE_URL_UNPOOLED);
	console.log('[db] DEV_DATABASE_URL set:', !!process.env.DEV_DATABASE_URL);

	if (!url) {
		throw new Error(
			'No database URL found. Set one of: DATABASE_URL, DATABASE_URL_UNPOOLED, DEV_DATABASE_URL, or DEV_DATABASE_URL_UNPOOLED in environment variables.',
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
