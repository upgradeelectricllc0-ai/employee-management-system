-- ============================================================
-- Migration 002: Row Level Security Policies
-- EMS — Employee Management System
-- Single-tenant deployment: role-based (admin/employee) only
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_titles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Helper function: get current user's role
-- ============================================================
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================
-- companies — admin read/write, employee read-only
-- ============================================================
CREATE POLICY "admin_all_companies" ON companies
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_companies" ON companies
  FOR SELECT USING (get_user_role() = 'employee');

-- ============================================================
-- company_settings — admin read/write, employee read-only
-- ============================================================
CREATE POLICY "admin_all_settings" ON company_settings
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_settings" ON company_settings
  FOR SELECT USING (get_user_role() = 'employee');

-- ============================================================
-- departments — admin write, all authenticated read
-- ============================================================
CREATE POLICY "admin_write_departments" ON departments
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_departments" ON departments
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- job_titles — admin write, all authenticated read
-- ============================================================
CREATE POLICY "admin_write_job_titles" ON job_titles
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_job_titles" ON job_titles
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- profiles — admin: all; employee: own row only
-- ============================================================
CREATE POLICY "admin_all_profiles" ON profiles
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_own_profile" ON profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "employee_update_own_profile" ON profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = 'employee'  -- cannot escalate own role
  );

-- ============================================================
-- attendance_records — admin: all; employee: own records only
-- ============================================================
CREATE POLICY "admin_all_attendance" ON attendance_records
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_own_attendance" ON attendance_records
  FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "employee_insert_own_attendance" ON attendance_records
  FOR INSERT WITH CHECK (employee_id = auth.uid());

CREATE POLICY "employee_update_own_attendance" ON attendance_records
  FOR UPDATE USING (
    employee_id = auth.uid()
    AND is_manually_edited = false  -- cannot modify admin-edited records
  );

-- ============================================================
-- schedule_shifts — admin write; employee read own shifts
-- ============================================================
CREATE POLICY "admin_all_schedules" ON schedule_shifts
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_own_schedule" ON schedule_shifts
  FOR SELECT USING (employee_id = auth.uid());

-- ============================================================
-- leave_requests — admin: all; employee: own requests
-- ============================================================
CREATE POLICY "admin_all_leave" ON leave_requests
  FOR ALL USING (get_user_role() = 'admin');

CREATE POLICY "employee_read_own_leave" ON leave_requests
  FOR SELECT USING (employee_id = auth.uid());

CREATE POLICY "employee_insert_own_leave" ON leave_requests
  FOR INSERT WITH CHECK (employee_id = auth.uid());

CREATE POLICY "employee_cancel_own_leave" ON leave_requests
  FOR UPDATE USING (
    employee_id = auth.uid()
    AND status = 'pending'  -- can only cancel pending requests
  )
  WITH CHECK (status = 'cancelled');

-- ============================================================
-- audit_logs — admin read-only; employees cannot read
-- ============================================================
CREATE POLICY "admin_read_audit_logs" ON audit_logs
  FOR SELECT USING (get_user_role() = 'admin');

CREATE POLICY "system_insert_audit_logs" ON audit_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
