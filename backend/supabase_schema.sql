-- -- Supabase (PostgreSQL) schema for SuperAuto app
-- -- Catatan: Jalankan di Supabase SQL Editor (dialek PostgreSQL).
-- -- Banyak linter IDE default ke SQL Server/T-SQL, yang akan menandai
-- -- sintaks PostgreSQL seperti `IF NOT EXISTS`, `uuid`, `text[]`, `timestamp with time zone` sebagai error.

-- -- Ekstensi untuk UUID acak di Supabase (pgcrypto sudah tersedia)
-- create extension if not exists pgcrypto;
-- create table if not exists users (
--   id uuid primary key default gen_random_uuid(),
--   email text unique not null,
--   name text
-- );

-- create table if not exists cars (
--   id uuid primary key default gen_random_uuid(),
--   user_id uuid references users(id) on delete cascade,
--   brand text not null,
--   model text not null,
--   year int not null,
--   plate_number text,
--   vin text,
--   engine_number text,
--   initial_km int default 0
-- );

-- create table if not exists service_booking (
--   id uuid primary key default gen_random_uuid(),
--   user_id uuid references users(id) on delete cascade,
--   car_id uuid references cars(id) on delete cascade,
--   type text not null,
--   workshop text not null,
--   scheduled_at timestamp with time zone not null,
--   estimated_cost numeric not null,
--   status text not null
-- );

-- create table if not exists service_history (
--   id uuid primary key default gen_random_uuid(),
--   user_id uuid references users(id) on delete cascade,
--   car_id uuid references cars(id) on delete cascade,
--   date date not null,
--   km int not null,
--   jobs text[] not null,
--   parts text[] not null,
--   total_cost numeric not null
-- );

-- create table if not exists product_category (
--   id uuid primary key default gen_random_uuid(),
--   name text unique not null
-- );

-- create table if not exists products (
--   id uuid primary key default gen_random_uuid(),
--   name text not null,
--   category_id uuid references product_category(id),
--   description text,
--   price numeric not null,
--   image_url text,
--   compatible_models text[]
-- );

-- create table if not exists cart (
--   id uuid primary key default gen_random_uuid(),
--   user_id uuid references users(id) on delete cascade,
--   items jsonb not null,
--   applied_promo_id uuid
-- );

-- create table if not exists orders (
--   id uuid primary key default gen_random_uuid(),
--   user_id uuid references users(id) on delete cascade,
--   items jsonb not null,
--   total numeric not null,
--   created_at timestamp with time zone not null default now(),
--   shipping_method text,
--   status text
-- );

-- create table if not exists bundlings (
--   id uuid primary key default gen_random_uuid(),
--   name text not null,
--   description text,
--   product_ids uuid[] not null,
--   bundle_price numeric not null
-- );

-- create table if not exists promos (
--   id uuid primary key default gen_random_uuid(),
--   name text not null,
--   type text not null,
--   value numeric not null,
--   start timestamp with time zone not null,
--   end timestamp with time zone not null
-- );


