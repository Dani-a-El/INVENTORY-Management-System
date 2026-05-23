-- Create the database if it does not exist.
CREATE DATABASE IF NOT EXISTS ims_db;
USE ims_db;

-- Table: products
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 0
);

-- Table: suppliers
CREATE TABLE IF NOT EXISTS suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL
);

-- Table: auth_users
CREATE TABLE IF NOT EXISTS auth_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    password_salt VARCHAR(64) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table: auth_sessions
CREATE TABLE IF NOT EXISTS auth_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    remember_me TINYINT(1) NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auth_sessions_user
        FOREIGN KEY (user_id) REFERENCES auth_users(id)
        ON DELETE CASCADE
);

-- Table: password_reset_tokens
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email VARCHAR(150) NOT NULL,
    reset_code VARCHAR(12) NOT NULL,
    expires_at DATETIME NOT NULL,
    used TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_reset_tokens_user
        FOREIGN KEY (user_id) REFERENCES auth_users(id)
        ON DELETE CASCADE
);

-- Table: transactions
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    type ENUM('in', 'out') NOT NULL,
    quantity INT NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transactions_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE CASCADE
);
