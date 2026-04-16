import { getRegionForKennel, getRegionNumberForKennel } from '../kennel-regions';

describe('kennel-regions', () => {
	describe('getRegionForKennel', () => {
		it('returns null for null/undefined kennel', () => {
			expect(getRegionForKennel(null)).toBeNull();
			expect(getRegionForKennel(undefined)).toBeNull();
		});

		it('returns ? for unmapped kennels', () => {
			expect(getRegionForKennel('999')).toBe('?');
			expect(getRegionForKennel('250')).toBe('?');
		});

		it('returns correct region for region 5 (quarantine) kennels 1-48', () => {
			expect(getRegionForKennel('1')).toBe('R5');
			expect(getRegionForKennel('10')).toBe('R5');
			expect(getRegionForKennel('48')).toBe('R5');
			expect(getRegionForKennel('A1')).toBe('R5');
			expect(getRegionForKennel('B10')).toBe('R5');
		});

		it('returns correct region for region 4 kennels 49-72 (green top)', () => {
			expect(getRegionForKennel('49')).toBe('R4');
			expect(getRegionForKennel('63')).toBe('R4');
			expect(getRegionForKennel('72')).toBe('R4');
		});

		it('returns correct region for region 4 kennels 91-114 (green bottom)', () => {
			expect(getRegionForKennel('91')).toBe('R4');
			expect(getRegionForKennel('100')).toBe('R4');
			expect(getRegionForKennel('114')).toBe('R4');
		});

		it('returns correct region for region 3 kennels 73-90 (orange)', () => {
			expect(getRegionForKennel('73')).toBe('R3');
			expect(getRegionForKennel('80')).toBe('R3');
			expect(getRegionForKennel('90')).toBe('R3');
		});

		it('returns correct region for region 3 kennels 130-159 (orange pavilion IV)', () => {
			expect(getRegionForKennel('130')).toBe('R3');
			expect(getRegionForKennel('145')).toBe('R3');
			expect(getRegionForKennel('159')).toBe('R3');
		});

		it('returns correct region for region 2 kennels 115-129 (cyan top)', () => {
			expect(getRegionForKennel('115')).toBe('R2');
			expect(getRegionForKennel('120')).toBe('R2');
			expect(getRegionForKennel('129')).toBe('R2');
		});

		it('returns correct region for region 2 kennels 160-183 (cyan bottom)', () => {
			expect(getRegionForKennel('160')).toBe('R2');
			expect(getRegionForKennel('170')).toBe('R2');
			expect(getRegionForKennel('183')).toBe('R2');
		});

		it('returns correct region for region 2 kennels 238-240 (cyan pavilion III)', () => {
			expect(getRegionForKennel('238')).toBe('R2');
			expect(getRegionForKennel('240')).toBe('R2');
		});

		it('returns correct region for region 1 kennels 184-231 (lime)', () => {
			expect(getRegionForKennel('184')).toBe('R1');
			expect(getRegionForKennel('200')).toBe('R1');
			expect(getRegionForKennel('231')).toBe('R1');
		});

		it('returns correct region for region 1 kennels 241-248 (lime middle)', () => {
			expect(getRegionForKennel('241')).toBe('R1');
			expect(getRegionForKennel('245')).toBe('R1');
			expect(getRegionForKennel('248')).toBe('R1');
		});

		it('returns correct region for region 12 kennels 405-422 (brown vertical)', () => {
			expect(getRegionForKennel('405')).toBe('R12');
			expect(getRegionForKennel('415')).toBe('R12');
			expect(getRegionForKennel('422')).toBe('R12');
		});

		it('returns correct region for region 12 kennels 425-441 (brown vertical)', () => {
			expect(getRegionForKennel('425')).toBe('R12');
			expect(getRegionForKennel('433')).toBe('R12');
			expect(getRegionForKennel('441')).toBe('R12');
		});

		it('returns correct region for region 12 kennels 590-596 (brown lower)', () => {
			expect(getRegionForKennel('590')).toBe('R12');
			expect(getRegionForKennel('593')).toBe('R12');
			expect(getRegionForKennel('596')).toBe('R12');
		});

		it('returns correct region for region 12 kennels 607-620 (brown top)', () => {
			expect(getRegionForKennel('607')).toBe('R12');
			expect(getRegionForKennel('613')).toBe('R12');
			expect(getRegionForKennel('620')).toBe('R12');
		});

		it('returns correct region for region 12 kennels 700-708 (brown strip)', () => {
			expect(getRegionForKennel('700')).toBe('R12');
			expect(getRegionForKennel('704')).toBe('R12');
			expect(getRegionForKennel('708')).toBe('R12');
		});

		it('returns correct region for region 13 kennels 320-344 (magenta upper)', () => {
			expect(getRegionForKennel('320')).toBe('R13');
			expect(getRegionForKennel('332')).toBe('R13');
			expect(getRegionForKennel('344')).toBe('R13');
		});

		it('returns correct region for region 13 kennels 451-456 (magenta horizontal)', () => {
			expect(getRegionForKennel('451')).toBe('R13');
			expect(getRegionForKennel('453')).toBe('R13');
			expect(getRegionForKennel('456')).toBe('R13');
		});

		it('returns correct region for region 13 kennels 623-631 (magenta group)', () => {
			expect(getRegionForKennel('623')).toBe('R13');
			expect(getRegionForKennel('627')).toBe('R13');
			expect(getRegionForKennel('631')).toBe('R13');
		});

		it('returns correct region for region 13 kennels 709-714 (magenta strip)', () => {
			expect(getRegionForKennel('709')).toBe('R13');
			expect(getRegionForKennel('711')).toBe('R13');
			expect(getRegionForKennel('714')).toBe('R13');
		});

		it('returns correct region for region 13 kennel 732 (magenta single)', () => {
			expect(getRegionForKennel('732')).toBe('R13');
		});

		it('returns correct region for region 11 kennels 457-522 (dark blue)', () => {
			expect(getRegionForKennel('457')).toBe('R11');
			expect(getRegionForKennel('490')).toBe('R11');
			expect(getRegionForKennel('522')).toBe('R11');
		});

		it('returns correct region for region 11 kennels 811-819 (dark blue)', () => {
			expect(getRegionForKennel('811')).toBe('R11');
			expect(getRegionForKennel('815')).toBe('R11');
			expect(getRegionForKennel('819')).toBe('R11');
		});

		it('returns correct region for region 9 kennels 523-585 (teal)', () => {
			expect(getRegionForKennel('523')).toBe('R9');
			expect(getRegionForKennel('554')).toBe('R9');
			expect(getRegionForKennel('585')).toBe('R9');
		});

		it('returns correct region for region 8 kennels 801-810 (purple)', () => {
			expect(getRegionForKennel('801')).toBe('R8');
			expect(getRegionForKennel('805')).toBe('R8');
			expect(getRegionForKennel('810')).toBe('R8');
		});

		it('returns correct region for region 8 kennels 822-862 (purple)', () => {
			expect(getRegionForKennel('822')).toBe('R8');
			expect(getRegionForKennel('842')).toBe('R8');
			expect(getRegionForKennel('862')).toBe('R8');
		});

		it('returns correct region for region 8 kennels 901-927 (purple)', () => {
			expect(getRegionForKennel('901')).toBe('R8');
			expect(getRegionForKennel('914')).toBe('R8');
			expect(getRegionForKennel('927')).toBe('R8');
		});

		it('parses kennel strings with non-digit characters', () => {
			expect(getRegionForKennel('A1')).toBe('R5');
			expect(getRegionForKennel('P-49')).toBe('R4');
			expect(getRegionForKennel('Pavilion VIII 63')).toBe('R4');
		});

		it('returns ? for non-numeric kennel after stripping', () => {
			expect(getRegionForKennel('ABC')).toBeNull();
			expect(getRegionForKennel('---')).toBeNull();
		});
	});

	describe('getRegionNumberForKennel', () => {
		it('returns null for invalid inputs', () => {
			expect(getRegionNumberForKennel(0)).toBeNull();
			expect(getRegionNumberForKennel(-1)).toBeNull();
			expect(getRegionNumberForKennel(1.5)).toBeNull();
		});

		it('returns correct region number for region 5 kennels 1-48', () => {
			expect(getRegionNumberForKennel(1)).toBe(5);
			expect(getRegionNumberForKennel(24)).toBe(5);
			expect(getRegionNumberForKennel(48)).toBe(5);
		});

		it('returns correct region number for region 4 kennels', () => {
			expect(getRegionNumberForKennel(49)).toBe(4);
			expect(getRegionNumberForKennel(72)).toBe(4);
			expect(getRegionNumberForKennel(91)).toBe(4);
			expect(getRegionNumberForKennel(114)).toBe(4);
		});

		it('returns correct region number for region 3 kennels', () => {
			expect(getRegionNumberForKennel(73)).toBe(3);
			expect(getRegionNumberForKennel(90)).toBe(3);
			expect(getRegionNumberForKennel(130)).toBe(3);
			expect(getRegionNumberForKennel(159)).toBe(3);
		});

		it('returns correct region number for region 2 kennels', () => {
			expect(getRegionNumberForKennel(115)).toBe(2);
			expect(getRegionNumberForKennel(129)).toBe(2);
			expect(getRegionNumberForKennel(160)).toBe(2);
			expect(getRegionNumberForKennel(240)).toBe(2);
		});

		it('returns correct region number for region 1 kennels', () => {
			expect(getRegionNumberForKennel(184)).toBe(1);
			expect(getRegionNumberForKennel(231)).toBe(1);
			expect(getRegionNumberForKennel(241)).toBe(1);
			expect(getRegionNumberForKennel(248)).toBe(1);
		});

		it('returns correct region number for region 12 kennels', () => {
			expect(getRegionNumberForKennel(405)).toBe(12);
			expect(getRegionNumberForKennel(441)).toBe(12);
			expect(getRegionNumberForKennel(596)).toBe(12);
			expect(getRegionNumberForKennel(708)).toBe(12);
		});

		it('returns correct region number for region 13 kennels', () => {
			expect(getRegionNumberForKennel(320)).toBe(13);
			expect(getRegionNumberForKennel(456)).toBe(13);
			expect(getRegionNumberForKennel(732)).toBe(13);
		});

		it('returns correct region number for region 11 kennels', () => {
			expect(getRegionNumberForKennel(457)).toBe(11);
			expect(getRegionNumberForKennel(522)).toBe(11);
			expect(getRegionNumberForKennel(811)).toBe(11);
			expect(getRegionNumberForKennel(819)).toBe(11);
		});

		it('returns correct region number for region 9 kennels', () => {
			expect(getRegionNumberForKennel(523)).toBe(9);
			expect(getRegionNumberForKennel(585)).toBe(9);
		});

		it('returns correct region number for region 8 kennels', () => {
			expect(getRegionNumberForKennel(801)).toBe(8);
			expect(getRegionNumberForKennel(862)).toBe(8);
			expect(getRegionNumberForKennel(927)).toBe(8);
		});

		it('returns null for unmapped kennels', () => {
			expect(getRegionNumberForKennel(249)).toBeNull();
			expect(getRegionNumberForKennel(319)).toBeNull();
			expect(getRegionNumberForKennel(928)).toBeNull();
		});

		it('handles boundary values correctly', () => {
			// Just before region 5 ends
			expect(getRegionNumberForKennel(48)).toBe(5);
			// Just after region 5 ends
			expect(getRegionNumberForKennel(49)).toBe(4);

			// Just before region 4 first range ends
			expect(getRegionNumberForKennel(72)).toBe(4);
			// Just after region 4 first range ends, before second starts
			expect(getRegionNumberForKennel(73)).toBe(3);
		});
	});
});
