# Production Database Setup

This project uses Supabase PostgreSQL for application data and Supabase Auth for administrator accounts. Its Vercel project defines two services: `app` (Vite) and `server` (Express). Browser API requests use `/api/*`, which Vercel routes to `server`.

This guide creates a new, empty production database. It does not copy data or users from the current project.

## 1. Create the Supabase project

1. Create a new Supabase project. Choose a region near the Vercel server's function region to reduce database latency.
2. Save the database password in a password manager. Do not put credentials in source files or commit them.
3. In the new project's SQL Editor, open `server/migrations/001_initial_schema.sql` in this repository, copy the file contents, paste the SQL statements into the editor, and run them. Do not enter the file path as SQL. The migration creates the application's 12 tables and indexes, enables row-level security, and inserts no records.
4. Confirm the migration succeeded and the tables appear under the `public` schema. Do not run the optional seed script for an empty production database.

## 2. Configure Supabase Auth

1. In Supabase Authentication settings, set the production Site URL to the website's real HTTPS origin and add any production callback/redirect URLs used by your auth configuration.
2. Disable public sign-ups unless anonymous account creation is an intended product feature. This app's account registration endpoint is protected and uses the server-only service role.
3. In Authentication > Users, create the first administrator with the email/password that should be used to sign in, and confirm the email if required by the project's Auth settings.
4. Keep the Supabase service-role secret private. Never expose it in browser code or a `VITE_` environment variable.

## 3. Add production environment variables

In Vercel's project settings, add the following variables to the **`server` service only**, for the Production environment. Use the same new Supabase project for all three Supabase values:

- `DATABASE_URL` (or Vercel's `POSTGRES_URL`): PostgreSQL connection string from Supabase Database settings. Prefer a Supabase pooler connection supported by the Vercel runtime; use the connection string format and port shown by Supabase. If the database password contains reserved URL characters, use the correctly URL-encoded password.
- `SUPABASE_URL` (or `NEXT_PUBLIC_SUPABASE_URL`): the new project's API URL.
- `SUPABASE_SERVICE_ROLE_KEY`: the new project's service-role secret key.
- `JWT_SECRET` (or Vercel's `SUPABASE_JWT_SECRET`): a secret of at least 32 characters. The backend accepts Vercel's existing Supabase variable names as fallbacks. If setting a separate `JWT_SECRET`, generate it locally with `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` and enter it directly in Vercel; do not commit it.

If production email notifications are needed, also configure `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, and `COMPANY_EMAIL`. Set `FRONTEND_URL` to `https://summitgolbalexpress.com` so links in emails point to the deployed site.

Do not add database or service-role credentials to the `app` service. The frontend talks to the Express API at `/api` and does not need direct database credentials.

## 4. Deploy and verify before cutover

1. Save the variables and redeploy the Vercel project so the `server` service receives them.
2. Check `https://<production-domain>/api/health`. A response with `"status":"ok"` confirms the API process is reachable; it does not by itself prove database connectivity.
3. Check `https://<production-domain>/api/reviews/approved`. A successful HTTP 200 response such as `{"reviews":[]}` confirms the API can query the new database and that the reviews table exists.
4. Sign in with the first administrator. Then verify an authenticated, read-only admin view loads. Do not use the seed script or submit test records if production should remain empty.
5. After verification, direct the production domain to this deployment. Keep the previous project available until the new deployment has been confirmed.

For local backend development, copy `server/.env.example` to `server/.env` and fill in development credentials. The repository's `.gitignore` excludes `.env` files; keep it that way.