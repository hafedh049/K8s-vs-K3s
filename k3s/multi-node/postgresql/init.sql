-- PostgreSQL initialization for K3s
-- Run as: sudo -u postgres psql -f init.sql

-- Create user
CREATE USER k3suser WITH PASSWORD 'k3s@Secure2026';

-- Create database
CREATE DATABASE k3s OWNER k3suser;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE k3s TO k3suser;

-- Verify
\l k3s
\du k3suser
