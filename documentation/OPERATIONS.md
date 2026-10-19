# Backend operations

## Migrations

```bash
supabase db reset          # local
supabase db push           # linked remote (careful)
supabase migration new <name>
```

Never edit applied migrations in place on shared environments; add a new migration.

## Backups

Use Supabase automated backups / point-in-time recovery appropriate to the paid plan. Document restore drills before production launch.

## Incident / rollback

1. Identify failing migration or function version
2. Roll forward with a corrective migration when possible
3. Coordinate frontend deploy compatibility via contract version notes

## Secrets rotation

Rotate service role keys and webhook secrets via the Supabase dashboard / provider console; update hosting env vars; never commit values.

## Admin owner bootstrap

1. Create Auth user in Supabase (invite/password reset) — no public admin registration UI.
2. Insert owner profile (service role / SQL editor):

```sql
insert into public.admin_profiles (user_id, role, display_name, is_active)
values ('<auth-user-uuid>', 'owner', 'Primary owner', true);
```

3. Confirm the user can read `admin_profiles` for themselves and mutate products under RLS.
4. Add `staff` rows only from an owner-controlled process.

## Bulk import CSV

Template headers are defined in `contracts/bulk-import.ts` (`BULK_IMPORT_HEADERS`). Always dry-run validate; never silently skip invalid rows.
