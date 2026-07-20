# RunwayIQ Backend API

The RunwayIQ Backend is an enterprise-grade Financial Operating System for Startups, built on Node.js, Express, Prisma, and PostgreSQL.

## Features
- **Clean Architecture:** Controllers, Services, and Repositories are strictly decoupled.
- **Financial Engine:** Dynamic, real-time calculations for Burn Rate, Runway, Cash, and Payroll.
- **Scenario Simulator:** In-memory "What-if" simulations without mutating production records.
- **Security:** Hardened with Helmet, XSS-Clean, HPP, Express Rate Limit, and strict CORS.
- **Observability:** Winston structured JSON logging and `/health/system` monitoring endpoints.
- **CI/CD & Docker:** Multi-stage Docker builds and automated GitHub Actions workflows.

## Environment Setup
1. Clone the repository and navigate to `/backend`.
2. Run `npm install` to install dependencies.
3. Copy `.env.example` to `.env` and configure your `DATABASE_URL` and `JWT_SECRET`.

## Database Setup
1. Start the database: `docker-compose up -d db`
2. Run migrations: `npm run db:migrate`
3. Seed the database: `npm run db:seed`
4. View data: `npm run db:studio`

## Running the Application
- **Development:** `npm run dev`
- **Production:** `npm start` (Make sure `NODE_ENV=production`)
- **Docker:** `docker-compose up --build -d`

## Testing
Run the Jest test suite with:
\`\`\`bash
npm test
\`\`\`
*(Tests use `jest-mock-extended` to stub the database for lightning-fast execution)*

## Documentation
- Swagger OpenAPI documentation is available at `http://localhost:3000/api/docs`.

## Deployment
Refer to `DEPLOYMENT.md` for AWS, Render, and Docker deployment instructions.

## Common Errors & Troubleshooting
- **`EADDRINUSE: address already in use :::3000`**: Kill the existing Node process using port 3000.
- **Prisma Client not found**: Ensure you run `npx prisma generate` after modifying the schema or installing dependencies.
- **JWT Errors**: Ensure your `.env` contains a valid `JWT_SECRET`.
