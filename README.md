# GEMSTORE

A Mobile Legends: Bang Bang (MLBB) diamond top-up platform with a working
login/register system backed by Express + MySQL, and a simple static
frontend.

## Project Structure

```
gemstore/
├── backend/              # Express API (auth, server)
│   ├── server.js
│   ├── db.js
│   ├── routes/auth.js
│   ├── middleware/auth.js
│   ├── .env              # local environment variables
│   └── package.json
├── public/                # Static frontend served by the backend
│   ├── index.html
│   ├── login.html
│   ├── register.html
│   ├── dashboard.html
│   ├── cart.html
│   ├── css/style.css
│   └── js/auth.js
├── gemstore.sql           # Database schema + seed data
├── docker-compose.yml
└── package.json
```

## Option 1: Run with Docker Compose (recommended)

1. Install Docker Desktop.
2. From the repo root, run:

   ```bash
   docker compose up --build
   ```

3. Open the site at:

   - **App (frontend + API)**: http://localhost:5000
   - **API health check**: http://localhost:5000/api/health

4. The MySQL database is automatically initialized from `gemstore.sql`
   the first time the `db` container starts (an empty `mysql_data` volume).
   If you've run this before with old data, remove the volume first:

   ```bash
   docker compose down -v
   docker compose up --build
   ```

To stop the app:

```bash
docker compose down
```

## Option 2: Run locally without Docker

1. Make sure MySQL is running locally and import the schema:

   ```bash
   mysql -u root -p < gemstore.sql
   ```

2. Configure `backend/.env` (copy from `backend/.env.example` if needed)
   with your local MySQL credentials and a `JWT_SECRET`.

3. Install dependencies and start the server:

   ```bash
   cd backend
   npm install
   npm start
   ```

4. Open http://localhost:5000 in your browser.

## How Login/Register Works

- `POST /api/auth/register` — creates a user (hashes the password with
  bcrypt, generates a unique referral code, sets a JWT in an httpOnly
  cookie).
- `POST /api/auth/login` — verifies email/password and sets the JWT cookie.
- `POST /api/auth/logout` — clears the session cookie.
- `GET /api/auth/me` — returns the logged-in user's profile (used by the
  frontend to populate the navbar and dashboard, and to protect pages).

The frontend pages (`login.html`, `register.html`, `dashboard.html`,
`cart.html`) call these endpoints with `fetch(..., { credentials: "include" })`
so the session cookie is sent automatically.

### Important: Set a real JWT secret

Before deploying anywhere beyond your own machine, change `JWT_SECRET` in
`backend/.env` to a long, random value. Anyone who knows this secret can
forge login sessions.
