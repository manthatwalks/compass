# Contributing to Compass

## Database Migrations

This project uses Prisma with Supabase (managed Postgres). Because Supabase does not
allow creating shadow databases, `prisma migrate dev` does not work. Use this workflow instead.

### Creating a new migration

1. Edit `packages/db/prisma/schema.prisma` with your changes.

2. Generate the migration SQL (reads current DB state, diffs against new schema):
   ```bash
   cd packages/db
   pnpm db:migrate-new your-migration-name
   ```
   This creates `prisma/migrations/<timestamp>_your-migration-name/migration.sql`.

3. **Review the generated SQL** before applying.

4. Apply to the database:
   ```bash
   pnpm db:migrate-deploy
   ```

### Why not `prisma migrate dev`?

`migrate dev` requires a shadow database (a temporary DB it creates, runs all migrations
on, and compares). Supabase's managed Postgres does not allow `CREATE DATABASE`, so the
shadow DB step fails.

`migrate deploy` skips the shadow DB — it only applies pending migration files. This is
safe as long as you review the generated SQL before committing.

### Connection URLs

- `DATABASE_URL` — pgbouncer pooled URL (port 6543). Used by the app at runtime.
- `DIRECT_URL` — direct Postgres connection (port 5432). Used by Prisma migrations.

Both must be set in `packages/db/.env`. Get them from Supabase → Project Settings → Database.

### Production deploys

CI/CD should run:
```bash
cd packages/db && pnpm db:migrate-deploy
```

Never run `prisma migrate dev` or `prisma migrate reset` against a production database.
