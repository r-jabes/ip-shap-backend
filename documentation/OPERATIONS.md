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
