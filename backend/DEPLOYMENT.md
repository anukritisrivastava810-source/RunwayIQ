# RunwayIQ Deployment Notes

## General Prerequisites
- A managed PostgreSQL instance (e.g., AWS RDS, Supabase, Neon).
- Node.js 18+ or a Docker-compatible host.
- Set `NODE_ENV=production` and provide a strong `JWT_SECRET`.

## Option 1: Docker (Recommended for AWS EC2 / DigitalOcean)
The included `docker-compose.yml` and `Dockerfile` are production-ready multi-stage builds.
1. SSH into your instance.
2. Clone the repository and configure `.env`.
3. Run `docker-compose up -d --build`.
4. Run migrations inside the container: `docker exec -it runwayiq_backend npm run db:deploy` (Configure this script in package.json to run `prisma migrate deploy`).

## Option 2: Render / Railway (PaaS)
1. Connect your GitHub repository to Render/Railway.
2. Select the `backend/` directory as the Root Directory.
3. Build Command: `npm install && npx prisma generate`
4. Start Command: `npm start`
5. Inject Environment Variables: `DATABASE_URL` and `JWT_SECRET`.
6. Use the PaaS managed PostgreSQL addon and link it to the app.

## Option 3: Vercel (API Only)
While Express *can* be deployed to Vercel via Serverless Functions, it is not recommended for a stateful Prisma connection without connection pooling (PgBouncer or Prisma Accelerate). If deploying to Vercel, ensure you update the `DATABASE_URL` to use your connection pooler string.
