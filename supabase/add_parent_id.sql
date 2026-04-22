-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Add parent_id column to tasks table for parent→child hierarchy
-- Run this AFTER seed_tasks.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Add parent_id column (nullable UUID referencing tasks.id)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES tasks(id) ON DELETE CASCADE;

-- 2. Back-fill parent_id for existing SOUS-POSTEs using the code convention
-- e.g. CARSOL-001-01 → parent is CARSOL-001
-- We match by stripping the last "-NN" segment from the child code
UPDATE tasks AS child
SET parent_id = parent.id
FROM tasks AS parent
WHERE child.type_poste = 'SOUS-POSTE'
  AND child.parent_id IS NULL
  AND child.user_id IS NULL
  AND parent.user_id IS NULL
  AND parent.type_poste = 'POSTE'
  AND parent.code = regexp_replace(child.code, '-\d{2}$', '');

-- 3. Index for efficient parent→children queries
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON tasks(parent_id);
