"""FastAPI backend for the IMS app.

The file keeps the backend intentionally compact and grouped by feature:
health checks, auth, dashboard, products, stock movement, and suppliers.
"""

from datetime import datetime, timedelta
import hashlib
import os
import secrets
import sqlite3

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
try:
    import mysql.connector
except Exception:  # pragma: no cover - optional when using sqlite
    mysql = None
from pydantic import BaseModel, Field

# Load environment variables from a .env file if it exists.
load_dotenv()

app = FastAPI(title="Beginner IMS API")

DB_ENGINE = os.getenv("DB_ENGINE", "sqlite").strip().lower()
SQLITE_DB_PATH = os.getenv("SQLITE_DB_PATH", "ims_local.db")

# Allow the Flutter client to call the API during local development.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- Request models ----------
class ProductCreate(BaseModel):
    name: str
    sku: str
    category: str
    price: float = Field(ge=0)
    quantity: int = Field(ge=0)


class ProductUpdate(BaseModel):
    name: str
    sku: str
    category: str
    price: float = Field(ge=0)
    quantity: int = Field(ge=0)


class StockMovementRequest(BaseModel):
    product_id: int
    quantity: int = Field(gt=0)


class SupplierCreate(BaseModel):
    name: str
    contact: str
    email: str


class SupplierUpdate(BaseModel):
    name: str
    contact: str
    email: str


class AuthRegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class AuthLoginRequest(BaseModel):
    email: str
    password: str
    remember_me: bool = False


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    reset_code: str
    password: str
    confirm_password: str


class UpdateProfileRequest(BaseModel):
    name: str
    email: str


# ---------- Database helpers ----------
def get_db_connection():
    if DB_ENGINE == "sqlite":
        conn = sqlite3.connect(SQLITE_DB_PATH)
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    if mysql is None:
        raise RuntimeError("mysql-connector-python is not installed")

    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "ims_db"),
    )


def sql(query: str) -> str:
    if DB_ENGINE == "sqlite":
        return query.replace("%s", "?")
    return query


def _now() -> datetime:
    return datetime.utcnow()


def _utc_to_text(value: datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S")


def _hash_password(password: str, salt: str | None = None) -> tuple[str, str]:
    salt_value = salt or secrets.token_hex(16)
    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        bytes.fromhex(salt_value),
        120_000,
    ).hex()
    return password_hash, salt_value


def _verify_password(password: str, salt: str, password_hash: str) -> bool:
    computed_hash, _ = _hash_password(password, salt)
    return secrets.compare_digest(computed_hash, password_hash)


def _session_expiry(remember_me: bool) -> str:
    # Remember-me extends the session lifetime so the user stays signed in longer.
    expiry_hours = 24 * 30 if remember_me else 24
    return _utc_to_text(_now() + timedelta(hours=expiry_hours))


def _generate_reset_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def init_sqlite_database():
    if DB_ENGINE != "sqlite":
        return

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Create every table needed by the app in one place for local SQLite mode.
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                sku TEXT NOT NULL UNIQUE,
                category TEXT NOT NULL,
                price REAL NOT NULL DEFAULT 0,
                quantity INTEGER NOT NULL DEFAULT 0
            )
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS auth_users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                password_salt TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS auth_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                token TEXT NOT NULL UNIQUE,
                remember_me INTEGER NOT NULL DEFAULT 0,
                expires_at TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES auth_users(id) ON DELETE CASCADE
            )
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                email TEXT NOT NULL,
                reset_code TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                used INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES auth_users(id) ON DELETE CASCADE
            )
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                contact TEXT NOT NULL,
                email TEXT NOT NULL
            )
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                type TEXT NOT NULL CHECK (type IN ('in', 'out')),
                quantity INTEGER NOT NULL,
                timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
            )
            """
        )
        conn.commit()
    finally:
        cursor.close()
        conn.close()


@app.on_event("startup")
def startup_init_db():
    init_sqlite_database()


def row_to_product(row):
    return {
        "id": row[0],
        "name": row[1],
        "sku": row[2],
        "category": row[3],
        "price": float(row[4]),
        "quantity": row[5],
    }


def row_to_supplier(row):
    return {
        "id": row[0],
        "name": row[1],
        "contact": row[2],
        "email": row[3],
    }


def row_to_auth_user(row):
    return {
        "id": row[0],
        "name": row[1],
        "email": row[2],
    }


def _get_user_by_email(cursor, email: str):
    cursor.execute(
        sql(
            """
            SELECT id, name, email, password_hash, password_salt
            FROM auth_users
            WHERE lower(email) = lower(%s)
            """
        ),
        (email,),
    )
    return cursor.fetchone()


def _get_user_by_session_token(cursor, token: str):
    # The expiry check lives in SQL so expired sessions never reach the app layer.
    cursor.execute(
        sql(
            """
            SELECT u.id, u.name, u.email
            FROM auth_sessions s
            INNER JOIN auth_users u ON u.id = s.user_id
            WHERE s.token = %s AND s.expires_at > %s
            """
        ),
        (token, _utc_to_text(_now())),
    )
    return cursor.fetchone()


@app.get("/health")
def health_check():
    """Simple process health check used by tools and manual testing."""
    return {"message": "IMS API is running"}


@app.get("/health/db")
def database_health_check():
    """Check whether the configured database is reachable."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(sql("SELECT 1"))
            cursor.fetchone()
        finally:
            cursor.close()
            conn.close()

        return {
            "status": "ok",
            "message": f"Database is online ({DB_ENGINE})",
        }
    except Exception:
        return {
            "status": "offline",
            "message": f"Database offline ({DB_ENGINE}). Check backend DB configuration.",
        }


# ---------- Auth endpoints ----------
@app.post("/auth/register")
def register_user(payload: AuthRegisterRequest):
    """Create a new auth user with a hashed password."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        existing_user = _get_user_by_email(cursor, payload.email)
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="An account already exists for that email",
            )

        password_hash, password_salt = _hash_password(payload.password)
        cursor.execute(
            sql(
                """
                INSERT INTO auth_users (name, email, password_hash, password_salt)
                VALUES (%s, %s, %s, %s)
                """
            ),
            (payload.name.strip(), payload.email.strip().lower(), password_hash, password_salt),
        )
        conn.commit()
        return {
            "message": "Account created successfully",
            "user": {
                "id": cursor.lastrowid,
                "name": payload.name.strip(),
                "email": payload.email.strip().lower(),
            },
        }
    finally:
        cursor.close()
        conn.close()


@app.post("/auth/login")
def login_user(payload: AuthLoginRequest):
    """Validate credentials and create a bearer session token."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user = _get_user_by_email(cursor, payload.email.strip().lower())
        if not user:
            raise HTTPException(status_code=404, detail="No account found for that email")

        user_id, name, email, password_hash, password_salt = user
        if not _verify_password(payload.password, password_salt, password_hash):
            raise HTTPException(status_code=401, detail="Invalid password")

        token = secrets.token_urlsafe(32)
        cursor.execute(
            sql(
                """
                INSERT INTO auth_sessions (user_id, token, remember_me, expires_at)
                VALUES (%s, %s, %s, %s)
                """
            ),
            (
                user_id,
                token,
                1 if payload.remember_me else 0,
                _session_expiry(payload.remember_me),
            ),
        )
        conn.commit()
        return {
            "message": "Login successful",
            "token_type": "bearer",
            "access_token": token,
            "remember_me": payload.remember_me,
            "user": row_to_auth_user((user_id, name, email)),
        }
    finally:
        cursor.close()
        conn.close()


@app.get("/auth/me")
def current_user(authorization: str | None = Header(default=None)):
    """Return the current user from the bearer token in the request header."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing access token")

    token = authorization.split(" ", 1)[1].strip()
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user = _get_user_by_session_token(cursor, token)
        if not user:
            raise HTTPException(status_code=401, detail="Session expired or invalid")

        return {"user": row_to_auth_user(user)}
    finally:
        cursor.close()
        conn.close()


@app.put("/auth/profile")
def update_profile(
    payload: UpdateProfileRequest,
    authorization: str | None = Header(default=None),
):
    """Update the signed-in user's display name and email address."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing access token")

    token = authorization.split(" ", 1)[1].strip()
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user = _get_user_by_session_token(cursor, token)
        if not user:
            raise HTTPException(status_code=401, detail="Session expired or invalid")

        user_id = user[0]
        normalized_email = payload.email.strip().lower()
        cursor.execute(
            sql(
                """
                SELECT id
                FROM auth_users
                WHERE lower(email) = lower(%s) AND id != %s
                """
            ),
            (normalized_email, user_id),
        )
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="An account already exists for that email")

        cursor.execute(
            sql(
                """
                UPDATE auth_users
                SET name = %s, email = %s
                WHERE id = %s
                """
            ),
            (payload.name.strip(), normalized_email, user_id),
        )
        conn.commit()

        return {
            "message": "Profile updated successfully",
            "user": {
                "id": user_id,
                "name": payload.name.strip(),
                "email": normalized_email,
            },
        }
    finally:
        cursor.close()
        conn.close()


@app.post("/auth/logout")
def logout_user(authorization: str | None = Header(default=None)):
    """Delete the bearer session token if one was supplied."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return {"message": "Already logged out"}

    token = authorization.split(" ", 1)[1].strip()
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("DELETE FROM auth_sessions WHERE token = %s"), (token,))
        conn.commit()
        return {"message": "Logged out successfully"}
    finally:
        cursor.close()
        conn.close()


@app.post("/auth/forgot-password")
def forgot_password(payload: ForgotPasswordRequest):
    """Create a reset code for the current demo/reset flow."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user = _get_user_by_email(cursor, payload.email.strip().lower())
        if not user:
            raise HTTPException(status_code=404, detail="No account found for that email")

        user_id, _, email, _, _ = user
        reset_code = _generate_reset_code()
        cursor.execute(
            sql(
                """
                INSERT INTO password_reset_tokens (user_id, email, reset_code, expires_at)
                VALUES (%s, %s, %s, %s)
                """
            ),
            (user_id, email, reset_code, _session_expiry(False)),
        )
        conn.commit()
        return {
            "message": "Password reset code created",
            "reset_code": reset_code,
        }
    finally:
        cursor.close()
        conn.close()


@app.post("/auth/reset-password")
def reset_password(payload: ResetPasswordRequest):
    """Verify the reset code and store a new hashed password."""
    if payload.password != payload.confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        user = _get_user_by_email(cursor, payload.email.strip().lower())
        if not user:
            raise HTTPException(status_code=404, detail="No account found for that email")

        user_id = user[0]
        cursor.execute(
            sql(
                """
                SELECT id, reset_code
                FROM password_reset_tokens
                WHERE user_id = %s AND used = 0 AND expires_at > %s
                ORDER BY id DESC
                LIMIT 1
                """
            ),
            (user_id, _utc_to_text(_now())),
        )
        token_row = cursor.fetchone()
        if not token_row:
            raise HTTPException(status_code=400, detail="No active reset code found")

        if token_row[1] != payload.reset_code.strip():
            raise HTTPException(status_code=400, detail="Reset code is invalid")

        password_hash, password_salt = _hash_password(payload.password)
        cursor.execute(
            sql(
                """
                UPDATE auth_users
                SET password_hash = %s, password_salt = %s
                WHERE id = %s
                """
            ),
            (password_hash, password_salt, user_id),
        )
        cursor.execute(
            sql("UPDATE password_reset_tokens SET used = 1 WHERE id = %s"),
            (token_row[0],),
        )
        conn.commit()
        return {"message": "Password updated successfully"}
    finally:
        cursor.close()
        conn.close()


@app.get("/dashboard")
def get_dashboard_data():
    """Return summary numbers for dashboard cards."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("SELECT COUNT(*) FROM products"))
        total_products = cursor.fetchone()[0]

        cursor.execute(sql("SELECT COALESCE(SUM(quantity), 0) FROM products"))
        total_stock = cursor.fetchone()[0]

        cursor.execute(sql("SELECT COUNT(*) FROM products WHERE quantity < 5"))
        low_stock_count = cursor.fetchone()[0]

        return {
            "total_products": total_products,
            "total_stock": int(total_stock),
            "low_stock_count": low_stock_count,
        }
    finally:
        cursor.close()
        conn.close()


# ---------- Product endpoints ----------
@app.get("/products")
def get_products():
    """Return the full product list ordered from newest to oldest."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            SELECT id, name, sku, category, price, quantity
            FROM products
            ORDER BY id DESC
            """
            )
        )
        rows = cursor.fetchall()
        return [row_to_product(row) for row in rows]
    finally:
        cursor.close()
        conn.close()


@app.post("/products")
def create_product(product: ProductCreate):
    """Insert a new product row."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            INSERT INTO products (name, sku, category, price, quantity)
            VALUES (%s, %s, %s, %s, %s)
            """,
            ),
            (product.name, product.sku, product.category, product.price, product.quantity),
        )
        conn.commit()
        return {"message": "Product created successfully", "id": cursor.lastrowid}
    finally:
        cursor.close()
        conn.close()


@app.put("/products/{product_id}")
def update_product(product_id: int, product: ProductUpdate):
    """Update an existing product row by id."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            UPDATE products
            SET name = %s, sku = %s, category = %s, price = %s, quantity = %s
            WHERE id = %s
            """,
            ),
            (
                product.name,
                product.sku,
                product.category,
                product.price,
                product.quantity,
                product_id,
            ),
        )
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Product not found")
        return {"message": "Product updated successfully"}
    finally:
        cursor.close()
        conn.close()


@app.delete("/products/{product_id}")
def delete_product(product_id: int):
    """Delete a product row if it still exists."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("DELETE FROM products WHERE id = %s"), (product_id,))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Product not found")
        return {"message": "Product deleted successfully"}
    finally:
        cursor.close()
        conn.close()


# ---------- Stock movement endpoints ----------
@app.post("/stock_in")
def stock_in(request: StockMovementRequest):
    """Increase product quantity and record an inbound transaction."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("SELECT id FROM products WHERE id = %s"), (request.product_id,))
        product = cursor.fetchone()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")

        cursor.execute(
            sql("UPDATE products SET quantity = quantity + %s WHERE id = %s"),
            (request.quantity, request.product_id),
        )

        cursor.execute(
            sql(
            """
            INSERT INTO transactions (product_id, type, quantity, timestamp)
            VALUES (%s, %s, %s, %s)
            """,
            ),
            (request.product_id, "in", request.quantity, datetime.now()),
        )

        conn.commit()
        return {"message": "Stock added successfully"}
    finally:
        cursor.close()
        conn.close()


@app.post("/stock_out")
def stock_out(request: StockMovementRequest):
    """Decrease product quantity and record an outbound transaction."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql("SELECT quantity FROM products WHERE id = %s"),
            (request.product_id,),
        )
        product = cursor.fetchone()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")

        current_quantity = int(product[0])
        if current_quantity < request.quantity:
            raise HTTPException(
                status_code=400,
                detail="Not enough stock for this stock-out operation",
            )

        cursor.execute(
            sql("UPDATE products SET quantity = quantity - %s WHERE id = %s"),
            (request.quantity, request.product_id),
        )

        cursor.execute(
            sql(
            """
            INSERT INTO transactions (product_id, type, quantity, timestamp)
            VALUES (%s, %s, %s, %s)
            """,
            ),
            (request.product_id, "out", request.quantity, datetime.now()),
        )

        conn.commit()
        return {"message": "Stock removed successfully"}
    finally:
        cursor.close()
        conn.close()


@app.get("/transactions")
def get_transactions():
    """Return transaction history joined with product names."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            SELECT t.id, t.product_id, p.name, t.type, t.quantity, t.timestamp
            FROM transactions t
            INNER JOIN products p ON p.id = t.product_id
            ORDER BY t.id DESC
            """
            )
        )
        rows = cursor.fetchall()

        response = []
        for row in rows:
            response.append(
                {
                    "id": row[0],
                    "product_id": row[1],
                    "product_name": row[2],
                    "type": row[3],
                    "quantity": row[4],
                    "timestamp": row[5],
                }
            )

        return response
    finally:
        cursor.close()
        conn.close()


# ---------- Supplier endpoints ----------
@app.get("/suppliers")
def get_suppliers():
    """Return the supplier list ordered from newest to oldest."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("SELECT id, name, contact, email FROM suppliers ORDER BY id DESC"))
        rows = cursor.fetchall()
        return [row_to_supplier(row) for row in rows]
    finally:
        cursor.close()
        conn.close()


@app.post("/suppliers")
def create_supplier(supplier: SupplierCreate):
    """Insert a new supplier row."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            INSERT INTO suppliers (name, contact, email)
            VALUES (%s, %s, %s)
            """,
            ),
            (supplier.name, supplier.contact, supplier.email),
        )
        conn.commit()
        return {"message": "Supplier created successfully", "id": cursor.lastrowid}
    finally:
        cursor.close()
        conn.close()


@app.put("/suppliers/{supplier_id}")
def update_supplier(supplier_id: int, supplier: SupplierUpdate):
    """Update an existing supplier row by id."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            sql(
            """
            UPDATE suppliers
            SET name = %s, contact = %s, email = %s
            WHERE id = %s
            """,
            ),
            (supplier.name, supplier.contact, supplier.email, supplier_id),
        )
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Supplier not found")
        return {"message": "Supplier updated successfully"}
    finally:
        cursor.close()
        conn.close()


@app.delete("/suppliers/{supplier_id}")
def delete_supplier(supplier_id: int):
    """Delete a supplier row if it still exists."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql("DELETE FROM suppliers WHERE id = %s"), (supplier_id,))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Supplier not found")
        return {"message": "Supplier deleted successfully"}
    finally:
        cursor.close()
        conn.close()
