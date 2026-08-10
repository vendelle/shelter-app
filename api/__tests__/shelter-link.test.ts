import { buildShelterUrl } from '../_lib/shelter-link';

describe('buildShelterUrl', () => {
	it('pads a short number to 4 digits', () => {
		expect(buildShelterUrl('573/26')).toBe('https://napaluchu.waw.pl/animal/0573-26p/');
	});

	it('leaves an already 4-digit number as-is', () => {
		expect(buildShelterUrl('2222/26')).toBe('https://napaluchu.waw.pl/animal/2222-26p/');
	});

	it('trims surrounding whitespace', () => {
		expect(buildShelterUrl(' 573/26 ')).toBe('https://napaluchu.waw.pl/animal/0573-26p/');
	});

	it('returns null for null, undefined, or empty', () => {
		expect(buildShelterUrl(null)).toBeNull();
		expect(buildShelterUrl(undefined)).toBeNull();
		expect(buildShelterUrl('')).toBeNull();
	});

	it('returns null when shelterid does not match the number/year shape', () => {
		expect(buildShelterUrl('S010')).toBeNull();
		expect(buildShelterUrl('573-26')).toBeNull();
		expect(buildShelterUrl('573/26/1')).toBeNull();
	});
});
