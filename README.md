# IMS — Inventory Management System

An Inventory Management System (IMS) with a simple Python backend and a Flutter frontend. I built this as a final-year / learning project to practice full-stack development: designing REST APIs with FastAPI, persisting data with SQLite/MySQL, and building a cross-platform UI in Flutter.

## Project overview

- What it does: provides a basic inventory workflow — manage products and suppliers, record stock in/out transactions, and view simple dashboard summaries.
- Why it exists: a compact, hands-on project to learn building a backend API, a mobile/desktop UI with Flutter, and optional Docker-based local deployment.

## Features

- User authentication (register, login, session tokens)
- Product CRUD (create, list, update, delete)
- Supplier CRUD
- Stock movements: record inbound (`/stock_in`) and outbound (`/stock_out`) transactions
- Transaction history and simple dashboard metrics (total products, total stock, low-stock count)
- Health checks and FastAPI interactive docs (`/docs`)
- Easy local setup: SQLite for quick local runs, or MySQL + Docker Compose for a more realistic environment

## Tech stack

- Backend: FastAPI + Uvicorn (Python)
- Database: SQLite (local) or MySQL (via Docker Compose)
- Frontend: Flutter (in `frontend/ims_app`)
- Dev / deployment: Docker Compose (database + backend)

## Installation & setup

There are two simple ways to run the project locally: quick local mode (SQLite) or Docker Compose (MySQL + backend).

1) Quick local (recommended for development)

	- Create and activate a Python virtual environment

	```bash
	python -m venv .venv
	source .venv/bin/activate
	pip install -r backend/requirements.txt
	```

	- Run the backend (defaults to SQLite and will create a local `ims_local.db`)

	```bash
	cd backend
	uvicorn main:app --reload --host 0.0.0.0 --port 8000
	```

	- Open the API docs in your browser: http://localhost:8000/docs

	- Run the Flutter app (in a separate terminal)

	```bash
	cd frontend/ims_app
	flutter pub get
	flutter run
	```

2) Docker Compose (MySQL backend)

	- Start services

	```bash
	docker compose up --build
	```

	- Backend will be available at http://localhost:8000 (depends on compose settings)

Notes:
- Environment variables and DB engine are configurable via the service environment or a `.env` file. By default the backend uses SQLite for quick testing.

## Usage

- API: Most functionality is exposed via REST endpoints in `backend/main.py`. Example endpoints:
	- `GET /health` — basic health check
	- `GET /products` — list products
	- `POST /products` — create product
	- `POST /stock_in` and `POST /stock_out` — record stock movements
	- `GET /transactions` — transaction history
- FastAPI provides interactive docs at `/docs` which is handy for manual testing.
- Frontend: the Flutter app is a simple client that talks to the backend. Open `frontend/ims_app/lib/main.dart` to see how it connects to the API.

## Project structure (high level)

- `backend/` — FastAPI app, database helpers, and API endpoints
	- `main.py` — single-file, compact API implementation used for the project
	- `requirements.txt` — backend Python deps
- `frontend/ims_app/` — Flutter app
- `docker-compose.yml` — helper to start a MySQL container and the backend
- `database.sql` — initial SQL to seed MySQL when using Docker Compose

## Screenshots 
Open frontend/ims app to access the screenshot folder with the UI interfaces.

## Future improvements

- Add pagination, filtering and search on product lists
- Improve UI/UX and make layout responsive for phones/tablets
- Add role-based access control (admin/staff) and permissions
- Add CSV import/export for bulk product updates
- Add automated tests for the backend endpoints
- Add CI workflow for linting and running tests