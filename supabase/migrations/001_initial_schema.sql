-- ============================================================
-- Migration 001: Initial Schema
-- EMS — Employee Management System
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: companies
-- ============================================================
CREATE TABLE companies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(100) UNIQUE NOT NULL,
  logo_url    TEXT,
  timezone    VARCHAR(100) NOT NULL DEFAULT 'UTC',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_companies_slug ON companies (slug);
CREATE INDEX idx_companies_is_active ON companies (is_active);

-- ============================================================
-- TABLE: company_settings
-- ============================================================
CREATE TABLE company_settings (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id                  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  work_start_time             TIME NOT NULL DEFAULT '09:00',
  work_end_time               TIME NOT NULL DEFAULT '17:00',
  late_grace_minutes          INTEGER NOT NULL DEFAULT 15,
  early_leave_grace_minutes   INTEGER NOT NULL DEFAULT 10,
  work_days                   INTEGER[] NOT NULL DEFAULT '{1,2,3,4,5}',
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id)
);

-- ============================================================
-- TABLE: departments
-- ============================================================
CREATE TABLE departments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, name)
);

-- ============================================================
-- TABLE: job_titles
-- ============================================================
CREATE TABLE job_titles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, name)
);

-- ============================================================
-- TABLE: profiles
-- Extends Supabase auth.users
-- ============================================================
CREATE TABLE profiles (
  id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id        UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  role              TEXT NOT NULL CHECK (role IN ('admin', 'employee')),
  first_name        VARCHAR(100) NOT NULL,
  last_name         VARCHAR(100) NOT NULL,
  email             VARCHAR(255) NOT NULL,
  phone             VARCHAR(30),
  avatar_url        TEXT,
  department_id     UUID REFERENCES departments(id) ON DELETE SET NULL,
  job_title_id      UUID REFERENCES job_titles(id) ON DELETE SET NULL,
  employment_status TEXT NOT NULL DEFAULT 'full_time'
                    CHECK (employment_status IN ('full_time','part_time','contract','intern')),
  hire_date         DATE,
  employee_id_code  VARCHAR(50),
  is_active         BOOLEAN NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, email)
);

CREATE INDEX idx_profiles_company_id ON profiles (company_id);
CREATE INDEX idx_profiles_department_id ON profiles (department_id);
CREATE INDEX idx_profiles_is_active ON profiles (is_active);

-- ============================================================
-- TABLE: attendance_records
-- ============================================================
CREATE TABLE attendance_records (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  clock_in_at         TIMESTAMPTZ,
  clock_out_at        TIMESTAMPTZ,
  scheduled_start     TIME,
  scheduled_end       TIME,
  net_hours           DECIMAL(5,2),
  status              TEXT NOT NULL DEFAULT 'present'
                      CHECK (status IN ('present','absent','late','half_day','on_leave')),
  is_late             BOOLEAN NOT NULL DEFAULT false,
  is_early_departure  BOOLEAN NOT NULL DEFAULT false,
  late_minutes        INTEGER,
  admin_note          TEXT,
  is_manually_edited  BOOLEAN NOT NULL DEFAULT false,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);

CREATE INDEX idx_attendance_company_date ON attendance_records (company_id, date);
CREATE INDEX idx_attendance_employee_date ON attendance_records (employee_id, date);

-- ============================================================
-- TABLE: schedule_shifts
-- ============================================================
CREATE TABLE schedule_shifts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  week_start_date DATE NOT NULL,
  shift_start     TIME,
  shift_end       TIME,
  is_day_off      BOOLEAN NOT NULL DEFAULT false,
  notes           TEXT,
  created_by      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);

CREATE INDEX idx_schedule_company_week ON schedule_shifts (company_id, week_start_date);
CREATE INDEX idx_schedule_employee_date ON schedule_shifts (employee_id, date);

-- ============================================================
-- TABLE: leave_requests
-- ============================================================
CREATE TABLE leave_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  leave_type      TEXT NOT NULL CHECK (leave_type IN ('annual','sick','unpaid','other')),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  duration_days   INTEGER NOT NULL,
  reason          TEXT,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','approved','rejected','cancelled')),
  reviewed_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  rejection_note  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_leave_company_status ON leave_requests (company_id, status);
CREATE INDEX idx_leave_employee_status ON leave_requests (employee_id, status);

-- ============================================================
-- TABLE: audit_logs
-- ============================================================
CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  actor_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action      VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id   UUID,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_company_created ON audit_logs (company_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id);
