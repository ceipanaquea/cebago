-- ==========================================
-- SCRIPT DE BASE DE DATOS COMPLETO - CEBA GO
-- ==========================================
-- Este script crea el esquema de base de datos relacional para CEBA Go en Supabase.
-- Incluye tablas, disparadores (triggers), políticas de seguridad RLS y datos iniciales de prueba.

-- Habilitar extensión UUID
create extension if not exists "uuid-ossp";

-- ==========================================
-- 1. TABLA: perfiles
-- ==========================================
-- Extiende la tabla auth.users de Supabase para almacenar información adicional de estudiantes y personal.
create table public.perfiles (
    id uuid references auth.users on delete cascade primary key,
    nombres text not null,
    apellidos text not null,
    dni text unique not null check (length(dni) = 8),
    email text not null,
    telefono text,
    rol text not null default 'estudiante' check (rol in ('estudiante', 'administrador', 'director')),
    codigo_estudiante text unique,
    promedio_general numeric(4,2) default 0.0 check (promedio_general >= 0.0 and promedio_general <= 20.0),
    asistencia numeric(5,2) default 0.0 check (asistencia >= 0.0 and asistencia <= 100.0),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Habilitar RLS en perfiles
alter table public.perfiles enable row level security;

-- ==========================================
-- 2. TABLA: vacantes
-- ==========================================
-- Almacena los talleres técnicos y ciclos académicos disponibles con sus detalles y ocupación.
create table public.vacantes (
    id uuid default gen_random_uuid() primary key,
    titulo text not null,
    descripcion text not null,
    ciclo_escolar text not null, -- Ej: '2026-I'
    sede text not null,          -- Ej: 'Sede Central - Lima'
    taller_tecnico text not null,-- Ej: 'Computación e Informática'
    modalidad text not null check (modalidad in ('Presencial', 'Semi-presencial', 'A Distancia')),
    cupos_totales integer not null default 30 check (cupos_totales > 0),
    cupos_ocupados integer not null default 0 check (cupos_ocupados >= 0),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint cupos_coherentes check (cupos_ocupados <= cupos_totales)
);

-- Habilitar RLS en vacantes
alter table public.vacantes enable row level security;

-- ==========================================
-- 3. TABLA: matriculas
-- ==========================================
-- Almacena las solicitudes de matrícula y el expediente digital de los estudiantes.
create table public.matriculas (
    id uuid default gen_random_uuid() primary key,
    perfil_id uuid references public.perfiles(id) on delete cascade not null,
    codigo_ticket text unique not null, -- Ej: MAT-2026-A9F3
    nombres text not null,
    apellidos text not null,
    dni text not null check (length(dni) = 8),
    telefono text not null,
    edad integer not null check (edad >= 14),
    ciclo text not null,
    estado text not null default 'Pendiente' check (estado in ('Pendiente', 'Aprobado', 'Observado')),
    url_dni text,                         -- Enlace al documento DNI en Storage
    url_certificado_primaria text,       -- Enlace al certificado escolar
    url_certificado_secundaria text,     -- Enlace al certificado de secundaria
    url_foto text,                        -- Enlace a la foto del alumno
    observaciones text,                  -- Feedback del administrador en caso de observaciones
    fecha_creacion timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Habilitar RLS en matriculas
alter table public.matriculas enable row level security;

-- ==========================================
-- 4. TABLA: notificaciones
-- ==========================================
-- Almacena las notificaciones de los estudiantes sobre su matrícula o talleres.
create table public.notificaciones (
    id uuid default gen_random_uuid() primary key,
    perfil_id uuid references public.perfiles(id) on delete cascade not null,
    titulo text not null,
    mensaje text not null,
    categoria text not null default 'General' check (categoria in ('Matrícula', 'Taller', 'General')),
    leido boolean not null default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Habilitar RLS en notificaciones
alter table public.notificaciones enable row level security;

-- ==========================================
-- 5. TABLA: tickets_soporte
-- ==========================================
-- Almacena las solicitudes de soporte técnico y consultas de los estudiantes con las respuestas de la secretaría.
create table public.tickets_soporte (
    id uuid default gen_random_uuid() primary key,
    perfil_id uuid references public.perfiles(id) on delete cascade not null,
    categoria text not null, -- Ej: 'Problema Técnico', 'Consulta sobre Pagos', 'Horario de Clases'
    asunto text not null,
    mensaje text not null,
    estado text not null default 'Abierto' check (estado in ('Abierto', 'Respondido', 'Cerrado')),
    respuesta_soporte text,  -- Respuesta de la secretaría académica
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Habilitar RLS en tickets_soporte
alter table public.tickets_soporte enable row level security;


-- ==========================================
-- FUNCIONES Y TRIGGERS DE SINCRONIZACIÓN
-- ==========================================

-- Función para sincronizar la creación de usuarios desde auth.users a public.perfiles
create or replace function public.handle_new_user()
returns trigger as $$
declare
    v_rol text;
    v_nombres text;
    v_apellidos text;
    v_dni text;
    v_telefono text;
    v_codigo text;
begin
    -- Extraer valores del metadata si existen, de lo contrario colocar valores por defecto
    v_rol := coalesce(new.raw_user_meta_data->>'rol', 'estudiante');
    v_nombres := coalesce(new.raw_user_meta_data->>'nombres', 'Nuevo');
    v_apellidos := coalesce(new.raw_user_meta_data->>'apellidos', 'Usuario');
    v_dni := coalesce(new.raw_user_meta_data->>'dni', substring(new.id::text from 1 for 8));
    v_telefono := new.raw_user_meta_data->>'telefono';
    
    -- Generar código estudiantil aleatorio si el rol es estudiante
    if v_rol = 'estudiante' then
        v_codigo := 'CEBA-2026-' || floor(random() * (9999 - 1000 + 1) + 1000)::text;
    else
        v_codigo := null;
    end if;

    insert into public.perfiles (
        id,
        nombres,
        apellidos,
        dni,
        email,
        telefono,
        rol,
        codigo_estudiante,
        promedio_general,
        asistencia
    ) values (
        new.id,
        v_nombres,
        v_apellidos,
        v_dni,
        new.email,
        v_telefono,
        v_rol,
        v_codigo,
        0.0,
        0.0
    );
    return new;
end;
$$ language plpgsql security definer;

-- Crear disparador
create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();


-- Funciones auxiliares con "security definer" para evitar recursión infinita en las políticas RLS
create or replace function public.es_admin(user_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.perfiles
    where id = user_id and rol = 'administrador'
  );
end;
$$ language plpgsql security definer;

create or replace function public.es_admin_o_director(user_id uuid)
returns boolean as $$
begin
  return exists (
    select 1 from public.perfiles
    where id = user_id and rol in ('administrador', 'director')
  );
end;
$$ language plpgsql security definer;


-- ==========================================
-- POLÍTICAS DE ROW LEVEL SECURITY (RLS)
-- ==========================================

-- 1. Políticas de la tabla perfiles
create policy "Los usuarios pueden ver su propio perfil" 
    on public.perfiles for select 
    using (auth.uid() = id);

create policy "Los administradores y directores pueden ver todos los perfiles" 
    on public.perfiles for select 
    using (public.es_admin_o_director(auth.uid()));

create policy "Los usuarios pueden actualizar su propio perfil" 
    on public.perfiles for update 
    using (auth.uid() = id);

create policy "Los administradores pueden modificar cualquier perfil" 
    on public.perfiles for all 
    using (public.es_admin(auth.uid()));

-- 2. Políticas de la tabla vacantes
create policy "Cualquier usuario autenticado puede ver vacantes"
    on public.vacantes for select
    using (auth.role() = 'authenticated');

create policy "Solo administradores pueden crear o modificar vacantes"
    on public.vacantes for all
    using (public.es_admin(auth.uid()));

-- 3. Políticas de la tabla matriculas
create policy "Los estudiantes pueden ver su propia matrícula"
    on public.matriculas for select
    using (auth.uid() = perfil_id);

create policy "Los estudiantes pueden crear su propia matrícula"
    on public.matriculas for insert
    with check (auth.uid() = perfil_id);

create policy "Los administradores y directores pueden gestionar matrículas"
    on public.matriculas for all
    using (public.es_admin_o_director(auth.uid()));

-- 4. Políticas de la tabla notificaciones
create policy "Los estudiantes pueden ver sus propias notificaciones"
    on public.notificaciones for select
    using (auth.uid() = perfil_id);

create policy "Los estudiantes pueden marcar como leídas sus notificaciones"
    on public.notificaciones for update
    using (auth.uid() = perfil_id);

create policy "Los administradores pueden gestionar todas las notificaciones"
    on public.notificaciones for all
    using (public.es_admin(auth.uid()));

-- 5. Políticas de la tabla tickets_soporte
create policy "Los estudiantes pueden ver sus propios tickets"
    on public.tickets_soporte for select
    using (auth.uid() = perfil_id);

create policy "Los estudiantes pueden crear sus propios tickets"
    on public.tickets_soporte for insert
    with check (auth.uid() = perfil_id);

create policy "Los administradores pueden gestionar todos los tickets"
    on public.tickets_soporte for all
    using (public.es_admin(auth.uid()));


-- ==========================================
-- DATOS SEMILLA (SEED DATA) EN ESPAÑOL
-- ==========================================

-- Insertar vacantes de muestra
insert into public.vacantes (titulo, descripcion, ciclo_escolar, sede, taller_tecnico, modalidad, cupos_totales, cupos_ocupados) values
('Taller de Computación e Informática - Lima Central', 'Aprende herramientas ofimáticas avanzadas, diseño básico y navegación en internet orientada al trabajo.', 'Ciclo Inicial / Intermedio', 'Sede Central - Lima', 'Computación e Informática', 'Presencial', 30, 26),
('Electrónica General - Sede Norte', 'Fundamentos de electricidad, reparación de electrodomésticos y armado de circuitos básicos de control.', 'Ciclo Avanzado', 'Sede Norte - Los Olivos', 'Electrónica y Electricidad', 'Presencial', 25, 12),
('Confección Textil y Costura - Sede Sur', 'Diseño de modas, trazo de patrones y costura a máquina. Formación orientada al emprendimiento.', 'Ciclo Inicial / Intermedio', 'Sede Sur - SJM', 'Confección Textil', 'Presencial', 20, 18),
('Asistente de Contabilidad - Aula Virtual', 'Gestión de libros contables, tributación básica para MYPES y uso de hojas de cálculo contables en la nube.', 'Ciclo Avanzado', 'Aula Virtual CEBA', 'Contabilidad Básica', 'A Distancia', 100, 78),
('Taller de Computación - Sede Este', 'Curso básico para adultos sobre uso de computadoras, redacción de documentos y correo electrónico.', 'Ciclo Inicial / Intermedio', 'Sede Este - SJL', 'Computación e Informática', 'Semi-presencial', 25, 10);
