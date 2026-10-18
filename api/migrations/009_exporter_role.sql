-- Export-only role for shelter staff: signed in, sees only the walks CSV
-- export. Sits outside the pending → super_admin ladder. Safe to re-run.

-- Drop whatever check limits `role` (the name may differ on databases that
-- had the table from the earlier auth attempt), then add the new one.
DO $$
DECLARE c TEXT;
BEGIN
    FOR c IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'users'::regclass AND contype = 'c'
          AND pg_get_constraintdef(oid) LIKE '%role%'
    LOOP
        EXECUTE format('ALTER TABLE users DROP CONSTRAINT %I', c);
    END LOOP;
END $$;

ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('pending', 'volunteer', 'admin', 'super_admin', 'exporter'));
