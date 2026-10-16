import {
	canEditFamiliarity,
	canEditWalkDate,
	earliestEditableDate,
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

		it('allows edits from 3 days ago onward', () => {
			expect(earliestEditableDate(new Date('2026-10-16T10:00:00Z'))).toBe('2026-10-13');
		});

		it('handles month boundaries', () => {
			expect(earliestEditableDate(new Date('2026-03-02T10:00:00Z'))).toBe('2026-02-27');
		});
	});

	describe('canEditWalkDate', () => {
		const now = new Date('2026-10-16T10:00:00Z');

		it('lets volunteers edit today, the future, and up to 3 days back', () => {
			for (const date of ['2026-10-13', '2026-10-16', '2026-12-01']) {
				expect(canEditWalkDate(TEST_USERS.volunteer, date, now)).toBe(true);
			}
		});

		it('locks older walks for volunteers', () => {
			expect(canEditWalkDate(TEST_USERS.volunteer, '2026-10-12', now)).toBe(false);
		});

		it('lets admins edit any date', () => {
			expect(canEditWalkDate(TEST_USERS.admin, '2020-01-01', now)).toBe(true);
		});

		it('never lets anonymous or pending users edit', () => {
			expect(canEditWalkDate(null, '2026-10-16', now)).toBe(false);
			expect(canEditWalkDate(TEST_USERS.pending, '2026-10-16', now)).toBe(false);
		});

		it('rejects malformed dates for volunteers', () => {
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
