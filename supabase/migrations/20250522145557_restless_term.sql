/*
  # Initial Schema Setup for Budgetra

  1. New Tables
    - organizations
      - id (uuid, primary key)
      - name (text)
      - created_at (timestamp)
      - updated_at (timestamp)
    
    - organization_members
      - id (uuid, primary key)
      - organization_id (uuid, foreign key)
      - user_id (uuid, foreign key)
      - role (text)
      - created_at (timestamp)
      - updated_at (timestamp)
    
    - budgets
      - id (uuid, primary key)
      - organization_id (uuid, foreign key)
      - name (text)
      - amount (numeric)
      - start_date (date)
      - end_date (date)
      - created_at (timestamp)
      - updated_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for organization access
*/

-- Create organizations table
CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create organization_members table
CREATE TABLE organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'finance_lead', 'member')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, user_id)
);

-- Create budgets table
CREATE TABLE budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  amount numeric NOT NULL CHECK (amount >= 0),
  start_date date NOT NULL,
  end_date date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CHECK (end_date >= start_date)
);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Organizations policies
CREATE POLICY "Users can view their organizations" ON organizations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert organizations" ON organizations
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can update their organizations" ON organizations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = organizations.id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- Organization members policies
CREATE POLICY "Users can view organization members" ON organization_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.organization_id = organization_members.organization_id
      AND om.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage organization members" ON organization_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM organization_members om
      WHERE om.organization_id = organization_members.organization_id
      AND om.user_id = auth.uid()
      AND om.role = 'admin'
    )
  );

-- Budgets policies
CREATE POLICY "Users can view budgets" ON budgets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = budgets.organization_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Finance leads and admins can manage budgets" ON budgets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM organization_members
      WHERE organization_id = budgets.organization_id
      AND user_id = auth.uid()
      AND role IN ('admin', 'finance_lead')
    )
  );