# Fresh Supabase Database

This project uses Supabase PostgreSQL for application records and Supabase Auth for administrator accounts. The repository does not contain database credentials, and creating a new Supabase project must be done in your Supabase account.

## Create the empty project

1. Create a new Supabase project and save its database password securely.
2. In the new project's SQL Editor, run `server/migrations/001_initial_schema.sql`. This creates the application tables and indexes but inserts no records.
3. In Authentication > Users, create the first administrator account and confirm its email. Sign in to the app with that email and password. Additional accounts created through the protected registration API will be stored in this project's Supabase Auth.
4. Do not run `npm --prefix server run seed` if you want to keep the project empty. That optional script inserts demonstration records.

## Configure the backend

Set these variables for the `server` Vercel service and in `server/.env` for local backend development:

- `DATABASE_URL`: the new project's PostgreSQL connection URI from Supabase Database settings. Use a connection option supported by the deployment environment, such as Supabase's session pooler when direct IPv6 connectivity is unavailable.
- `SUPABASE_URL`: the new project's API URL.
- `SUPABASE_SERVICE_ROLE_KEY`: the new project's service-role secret. Keep it server-only; never add it to a `VITE_` variable or frontend code.
- `JWT_SECRET`: a randomly generated secret of at least 32 characters, as required by the API middleware.

Keep any existing SMTP variables configured if the app should send emails. The frontend does not connect directly to Supabase; it calls the backend at `/api`.

For deployment, set the environment variables on the Vercel `server` service, then redeploy. For local setup, copy `server/.env.example` to `server/.env` and replace the placeholders. Do not commit the `.env` file.

## Cut over

The current application data and Auth accounts are not copied. This setup points the backend at a new, empty project; the existing database is not modified. After schema setup and environment configuration, verify the backend's `/api/health` endpoint and a database-backed endpoint such as `/api/reviews/approved` before directing production traffic to the new deployment.