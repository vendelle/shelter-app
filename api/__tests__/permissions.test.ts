import {
	canEditFamiliarity,
	canEditWalkDate,
	editableDateRange,
	hasRole,
	isRole,
	shelterToday,
} from '../_lib/permissions';
import { TEST_USERS } from './helpers';

describe('permissions', () => {
	describe('hasRole', () => {
		it('ranks roles pending < volunteer < admin < super_admin', () => {
			expect(hasRole(TEST_USERS.volunteer, 'volunteer')).toBe(true);
			expect(hasRole(TEST_USERS.volunteer, 'admin')).toBe(false);
			expect(hasRole(TEST_USERS.super_admin, 'admin')).toBe(true);
			expect(hasRole(TEST_USERS.pending, 'volunteer')).toBe(false);
		});

		it('treats anonymous as having no role', () => {
			expect(hasRole(null, 'pending')).toBe(false);
		});

		it('never lets the export-only role through the ladder', () => {
			expect(hasRole(TEST_USERS.exporter, 'pending')).toBe(false);
			expect(hasRole(TEST_USERS.exporter, 'volunteer')).toBe(false);
		});
	});

	it('isRole accepts only known roles', () => {
		expect(isRole('admin')).toBe(true);
		expect(isRole('owner')).toBe(false);
		expect(isRole(undefined)).toBe(false);
	});

	describe('shelter dates', () => {
		it('uses the Warsaw date, not UTC', () => {
			// 23:30 UTC on Oct 16 is already Oct 17 in Warsaw (UTC+2 in summer time).
			expect(shelterToday(new Date('2026-10-16T23:30:00Z'))).toBe('2026-10-17');
		});

		it('opens today ±2 days for editing', () => {
			expect(editableDateRange(new Date('2026-10-16T10:00:00Z'))).toEqual({ from: '2026-10-14', to: '2026-10-18' });
		});

		it('handles month and year boundaries', () => {
			expect(editableDateRange(new Date('2026-03-01T10:00:00Z')).from).toBe('2026-02-27');
			expect(editableDateRange(new Date('2026-12-30T10:00:00Z')).to).toBe('2027-01-01');
		});
	});

	describe('canEditWalkDate', () => {
		const now = new Date('2026-10-16T10:00:00Z');

		it('lets volunteers and admins edit from 2 days ago to 2 days ahead', () => {
			for (const user of [TEST_USERS.volunteer, TEST_USERS.admin]) {
				for (const date of ['2026-10-14', '2026-10-16', '2026-10-18']) {
					expect(canEditWalkDate(user, date, now)).toBe(true);
				}
			}
		});

		it('locks days outside the window for volunteers and admins', () => {
			for (const user of [TEST_USERS.volunteer, TEST_USERS.admin]) {
				expect(canEditWalkDate(user, '2026-10-13', now)).toBe(false);
				expect(canEditWalkDate(user, '2026-10-19', now)).toBe(false);
			}
		});

		it('lets the super admin edit any date', () => {
			expect(canEditWalkDate(TEST_USERS.super_admin, '2020-01-01', now)).toBe(true);
			expect(canEditWalkDate(TEST_USERS.super_admin, '2030-01-01', now)).toBe(true);
		});

		it('never lets anonymous or pending users edit', () => {
			expect(canEditWalkDate(null, '2026-10-16', now)).toBe(false);
			expect(canEditWalkDate(TEST_USERS.pending, '2026-10-16', now)).toBe(false);
		});

		it('rejects malformed dates', () => {
			expect(canEditWalkDate(TEST_USERS.volunteer, '16.10.2026', now)).toBe(false);
		});
	});

	describe('canEditFamiliarity', () => {
		it("lets volunteers edit only their own volunteer's preferences", () => {
			expect(canEditFamiliarity(TEST_USERS.volunteer, TEST_USERS.volunteer.volunteerId!)).toBe(true);
			expect(canEditFamiliarity(TEST_USERS.volunteer, 99)).toBe(false);
		});

		it("lets admins edit anyone's preferences", () => {
			expect(canEditFamiliarity(TEST_USERS.admin, 99)).toBe(true);
		});

		it('denies pending and anonymous users', () => {
			expect(canEditFamiliarity({ ...TEST_USERS.pending, volunteerId: 5 }, 5)).toBe(false);
			expect(canEditFamiliarity(null, 5)).toBe(false);
		});
	});
});
