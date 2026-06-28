-- ==========================================
-- CONFIGURACIÓN COMPLETA SUPABASE - CEBA GO
-- Ejecutar este script en el SQL Editor de Supabase Dashboard
-- URL: https://supabase.com/dashboard/project/lqdxnvcaxbgupagwiygc/sql
-- ==========================================

-- ==========================================
-- 1. STORAGE BUCKET para Documentos
-- ==========================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documentos-matricula',
  'documentos-matricula',
  false,
  10485760, -- 10MB máximo
  ARRAY['image/jpeg', 'image/png', 'image/jpg', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 2. POLÍTICAS DE STORAGE (RLS)
-- ==========================================

-- Los estudiantes pueden subir sus propios documentos (organizados por user ID)
CREATE POLICY "Estudiantes pueden subir documentos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documentos-matricula'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Los estudiantes pueden ver sus propios documentos
CREATE POLICY "Estudiantes pueden ver sus documentos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documentos-matricula'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Los estudiantes pueden reemplazar sus propios documentos
CREATE POLICY "Estudiantes pueden actualizar sus documentos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'documentos-matricula'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Los administradores pueden ver todos los documentos
CREATE POLICY "Administradores pueden ver todos los documentos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documentos-matricula'
  AND EXISTS (
    SELECT 1 FROM public.perfiles 
    WHERE id = auth.uid() AND rol IN ('administrador', 'director')
  )
);

-- ==========================================
-- 3. POLÍTICA DE NOTIFICACIONES PARA ADMINS
-- Permite a administradores insertar notificaciones para estudiantes
-- ==========================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'notificaciones' 
    AND policyname = 'Administradores pueden crear notificaciones'
  ) THEN
    CREATE POLICY "Administradores pueden crear notificaciones"
      ON public.notificaciones FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.perfiles 
          WHERE id = auth.uid() AND rol IN ('administrador', 'director')
        )
      );
  END IF;
END $$;

-- ==========================================
-- 4. FUNCIÓN PARA GENERAR CÓDIGO DE MATRÍCULA ÚNICO
-- ==========================================
CREATE OR REPLACE FUNCTION public.generar_codigo_matricula()
RETURNS text AS $$
DECLARE
  codigo text;
  contador integer := 0;
BEGIN
  LOOP
    codigo := 'MAT-2026-' || upper(to_hex(floor(random() * 65535)::integer));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.matriculas WHERE codigo_ticket = codigo);
    contador := contador + 1;
    IF contador > 100 THEN
      RAISE EXCEPTION 'No se pudo generar código único';
    END IF;
  END LOOP;
  RETURN codigo;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- VERIFICACIÓN: Confirmar que todo se creó
-- ==========================================
SELECT 
  'Bucket creado:' AS tipo,
  name AS nombre
FROM storage.buckets 
WHERE id = 'documentos-matricula'
UNION ALL
SELECT 
  'Tablas disponibles:' AS tipo,
  tablename AS nombre
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('perfiles', 'vacantes', 'matriculas', 'notificaciones', 'tickets_soporte');
