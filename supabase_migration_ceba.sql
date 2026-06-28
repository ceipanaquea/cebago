-- ==========================================
-- CEBA Go — Migration: Extend matriculas for full CEBA enrollment requirements
-- ==========================================
-- Run in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This script is ADDITIVE only — no tables are dropped or recreated.

-- 1. Add CEBA enrollment columns to matriculas
ALTER TABLE public.matriculas
  ADD COLUMN IF NOT EXISTS sexo text,
  ADD COLUMN IF NOT EXISTS fecha_nacimiento date,
  ADD COLUMN IF NOT EXISTS email_contacto text,
  ADD COLUMN IF NOT EXISTS direccion text,
  ADD COLUMN IF NOT EXISTS ultima_institucion text,
  ADD COLUMN IF NOT EXISTS ultimo_grado text,
  ADD COLUMN IF NOT EXISTS ultimo_anio_estudio integer,
  ADD COLUMN IF NOT EXISTS tiene_ausencia_larga boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS solicita_prueba_ubicacion boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS exencion_religion boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS exencion_educacion_fisica boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS modalidad_estudio text DEFAULT 'Presencial',
  ADD COLUMN IF NOT EXISTS tiene_discapacidad boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS url_acta_nacimiento text,
  ADD COLUMN IF NOT EXISTS url_doc_discapacidad text;

-- 2. Extend estado check constraint to include 'En Revisión' and 'Rechazado'
--    (drop old constraint first, then add the extended one)
ALTER TABLE public.matriculas
  DROP CONSTRAINT IF EXISTS matriculas_estado_check;

ALTER TABLE public.matriculas
  ADD CONSTRAINT matriculas_estado_check
  CHECK (estado IN ('Pendiente', 'En Revisión', 'Aprobado', 'Observado', 'Rechazado'));

-- 3. Add student self-update policy (if it doesn't already exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'matriculas'
      AND schemaname = 'public'
      AND policyname = 'Los estudiantes pueden actualizar su propia matrícula'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Los estudiantes pueden actualizar su propia matrícula"
        ON public.matriculas FOR UPDATE
        USING (auth.uid() = perfil_id);
    $policy$;
  END IF;
END;
$$;

-- ==========================================
-- Verification queries (run after migration):
-- SELECT column_name, data_type, column_default, is_nullable
--   FROM information_schema.columns
--   WHERE table_name = 'matriculas' AND table_schema = 'public'
--   ORDER BY ordinal_position;
--
-- SELECT conname, pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conrelid = 'public.matriculas'::regclass AND contype = 'c';
-- ==========================================
