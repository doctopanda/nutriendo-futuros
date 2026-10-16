-- NUTRIENDO FUTUROS SALUDABLES · Esquema inicial v0.1
-- REVISIÓN OBLIGATORIA por responsables de seguridad y datos antes de producción.
-- Ejecutar únicamente en SQL Editor de Supabase. No copiar datos personales a GitHub.
BEGIN;
CREATE SCHEMA IF NOT EXISTS nf_private;
REVOKE ALL ON SCHEMA nf_private FROM PUBLIC, anon, authenticated;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS nf_private.perfiles (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 rol text NOT NULL CHECK (rol IN ('admin_estatal','auditor_estatal','admin_distrital','capturista','clinico')),
 distrito_id smallint CHECK (distrito_id BETWEEN 1 AND 6),
 activo boolean NOT NULL DEFAULT false,
 creado_en timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT distrito_del_rol CHECK (
   (rol IN ('admin_estatal','auditor_estatal') AND distrito_id IS NULL)
   OR (rol NOT IN ('admin_estatal','auditor_estatal') AND distrito_id IS NOT NULL)
 )
);

CREATE TABLE IF NOT EXISTS nf_private.folios_distritales (
 distrito_id smallint PRIMARY KEY CHECK (distrito_id BETWEEN 1 AND 6),
 ultimo_numero bigint NOT NULL DEFAULT 0 CHECK (ultimo_numero >= 0 AND ultimo_numero <= 99999999)
);
INSERT INTO nf_private.folios_distritales(distrito_id)
SELECT generate_series(1,6)
ON CONFLICT (distrito_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS nf_private.pacientes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 folio text NOT NULL UNIQUE CHECK (folio ~ '^NF-DS[1-6]-[0-9]{8}$'),
 distrito_id smallint NOT NULL CHECK (distrito_id BETWEEN 1 AND 6),
 nombre text NOT NULL,
 fecha_nacimiento date NOT NULL,
 sexo text NOT NULL CHECK (sexo IN ('F','M')),
 curp text,
 cuidador text NOT NULL,
 direccion text,
 telefono text,
 claves_identidad text NOT NULL,
 clues text NOT NULL,
 municipio text NOT NULL,
 localidad text NOT NULL,
 primera_evaluacion date NOT NULL,
 datos_contexto jsonb NOT NULL DEFAULT '{}'::jsonb,
 estatus text NOT NULL DEFAULT 'seguimiento' CHECK (estatus IN ('seguimiento','egreso','defuncion','traslado','pendiente_revision')),
 creado_por uuid NOT NULL REFERENCES auth.users(id),
 creado_en timestamptz NOT NULL DEFAULT now(),
 actualizado_en timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS nf_pacientes_curp_unico
 ON nf_private.pacientes(upper(curp)) WHERE curp IS NOT NULL AND curp <> '';
CREATE INDEX IF NOT EXISTS nf_pacientes_claves_idx
 ON nf_private.pacientes(claves_identidad);
CREATE INDEX IF NOT EXISTS nf_pacientes_territorio_idx
 ON nf_private.pacientes(distrito_id, municipio, localidad);

CREATE TABLE IF NOT EXISTS nf_private.seguimientos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 paciente_id uuid NOT NULL REFERENCES nf_private.pacientes(id),
 numero_consulta integer NOT NULL CHECK (numero_consulta >= 1),
 fecha_valoracion date NOT NULL,
 cedula jsonb NOT NULL,
 capturado_por uuid NOT NULL REFERENCES auth.users(id),
 creado_en timestamptz NOT NULL DEFAULT now(),
 UNIQUE (paciente_id, numero_consulta)
);
CREATE TABLE IF NOT EXISTS nf_private.auditoria (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 usuario_id uuid REFERENCES auth.users(id),
 accion text NOT NULL,
 folio text,
 ocurrido_en timestamptz NOT NULL DEFAULT now(),
 detalle jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- Agregados autorizados para divulgación. Esta tabla NO se alimenta automáticamente del nominal.
-- Los responsables deben evaluar supresión y riesgo de reidentificación antes de insertar filas.
CREATE TABLE IF NOT EXISTS public.nf_agregados_autorizados (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 periodo text NOT NULL,
 distrito_id smallint NOT NULL CHECK (distrito_id BETWEEN 1 AND 6),
 municipio text NOT NULL,
 categoria text NOT NULL,
 total integer NOT NULL CHECK (total >= 5),
 fecha_autorizacion date NOT NULL,
 autorizado_por text NOT NULL,
 UNIQUE (periodo,distrito_id,municipio,categoria)
);

-- RLS explícito: sin políticas de lectura/escritura para anon/authenticated en tablas nominales.
ALTER TABLE nf_private.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.folios_distritales ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.seguimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nf_agregados_autorizados ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON ALL TABLES IN SCHEMA nf_private FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA nf_private FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.nf_agregados_autorizados FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.nf_agregados_autorizados TO anon, authenticated;
DROP POLICY IF EXISTS nf_agregados_lectura ON public.nf_agregados_autorizados;
CREATE POLICY nf_agregados_lectura ON public.nf_agregados_autorizados
 FOR SELECT TO anon, authenticated USING (total >= 5);

-- El usuario autenticado ve solo su rol y distrito. No se revela información de pacientes.
CREATE OR REPLACE FUNCTION public.nf_mi_perfil()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE p nf_private.perfiles%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Acceso no autorizado'; END IF;
 SELECT * INTO p FROM nf_private.perfiles WHERE user_id=auth.uid() AND activo=true;
 IF NOT FOUND THEN RAISE EXCEPTION 'Perfil no autorizado'; END IF;
 RETURN jsonb_build_object('rol',p.rol,'distrito_id',p.distrito_id,'activo',true);
END;
$$;

-- Conciliación privada: la clave auxiliar nunca se expone ni se usa como token público.
CREATE OR REPLACE FUNCTION nf_private.normalizar(p_texto text)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path = ''
AS $$ SELECT upper(trim(regexp_replace(coalesce(p_texto,''),'[[:space:]]+',' ','g'))) $$;

-- Registro atómico, folio distrital secuencial y prevención de duplicados.
-- No crear folio si existe coincidencia exacta en CURP o nombre completo/fecha/sexo.
CREATE OR REPLACE FUNCTION public.nf_registrar_cedula(p_documento jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
 v_user uuid := auth.uid();
 v_perfil nf_private.perfiles%ROWTYPE;
 v_ident jsonb := p_documento->'identidad';
 v_consultas jsonb := p_documento->'consultas';
 v_nombre text := nf_private.normalizar(v_ident->>'nombre');
 v_sexo text := upper(coalesce(v_ident->>'sexo',''));
 v_curp text := nullif(upper(trim(coalesce(v_ident->>'curp',''))),'');
 v_dob date;
 v_clave text;
 v_exist nf_private.pacientes%ROWTYPE;
 v_distrito smallint;
 v_numero bigint;
 v_folio text;
 v_id uuid;
 v_consulta jsonb;
 v_n integer := 0;
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT * INTO v_perfil FROM nf_private.perfiles WHERE user_id=v_user AND activo;
 IF NOT FOUND OR v_perfil.rol NOT IN ('capturista','clinico','admin_distrital') THEN
   RAISE EXCEPTION 'Sin permiso para captura';
 END IF;
 v_distrito:=v_perfil.distrito_id;
 IF v_distrito IS NULL THEN RAISE EXCEPTION 'Distrito no asignado'; END IF;
 IF v_ident->>'autorizacion' IS DISTINCT FROM 'si' THEN RAISE EXCEPTION 'Encuesta no autorizada'; END IF;
 IF length(v_nombre)<3 OR length(v_nombre)>160 OR v_sexo NOT IN ('F','M')
    OR length(coalesce(v_ident->>'cuidador',''))<3
    OR length(coalesce(v_ident->>'clues',''))<5
    OR length(coalesce(v_ident->>'municipio',''))<3
    OR length(coalesce(v_ident->>'localidad',''))<2
    OR v_ident->>'fecha_nacimiento' IS NULL THEN
   RAISE EXCEPTION 'Campos obligatorios incompletos';
 END IF;
 IF v_curp IS NOT NULL AND v_curp !~ '^[A-Z0-9]{18}$' THEN RAISE EXCEPTION 'CURP inválida'; END IF;
 IF jsonb_typeof(v_consultas) IS DISTINCT FROM 'array' OR jsonb_array_length(v_consultas) NOT BETWEEN 1 AND 12 THEN
   RAISE EXCEPTION 'Se requieren entre 1 y 12 consultas';
 END IF;
 v_dob:=(v_ident->>'fecha_nacimiento')::date;
 IF v_dob > current_date THEN RAISE EXCEPTION 'Nacimiento futuro'; END IF;
 v_clave := v_nombre||'|'||v_dob::text||'|'||v_sexo;
 -- Evita carreras en cargas simultáneas con la misma identidad normalizada.
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_clave,0));
 SELECT * INTO v_exist FROM nf_private.pacientes
 WHERE (v_curp IS NOT NULL AND curp=v_curp) OR claves_identidad=v_clave
 ORDER BY CASE WHEN distrito_id=v_distrito THEN 0 ELSE 1 END, creado_en
 LIMIT 1;
 IF FOUND THEN
   INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
   VALUES (v_user,'intento_registro_repetido',v_exist.folio,jsonb_build_object('distrito_intento',v_distrito));
   IF v_exist.distrito_id = v_distrito THEN
     RETURN jsonb_build_object('estado','duplicado','folio',v_exist.folio);
   ELSE
     -- No dar a un capturista acceso a folios de otros distritos.
     RETURN jsonb_build_object('estado','requiere_revision','folio',null);
   END IF;
 END IF;
 UPDATE nf_private.folios_distritales SET ultimo_numero=ultimo_numero+1
 WHERE distrito_id=v_distrito AND ultimo_numero<99999999
 RETURNING ultimo_numero INTO v_numero;
 IF v_numero IS NULL THEN RAISE EXCEPTION 'Secuencia de folios agotada'; END IF;
 v_folio:='NF-DS'||v_distrito||'-'||lpad(v_numero::text,8,'0');
 INSERT INTO nf_private.pacientes
 (folio,distrito_id,nombre,fecha_nacimiento,sexo,curp,cuidador,direccion,telefono,
  claves_identidad,clues,municipio,localidad,primera_evaluacion,datos_contexto,creado_por)
 VALUES (v_folio,v_distrito,v_nombre,v_dob,v_sexo,v_curp,
         v_ident->>'cuidador',v_ident->>'direccion',v_ident->>'telefono',v_clave,
         upper(v_ident->>'clues'),v_ident->>'municipio',v_ident->>'localidad',
         (v_ident->>'primera_evaluacion')::date,
         v_ident - ARRAY['autorizacion','nombre','curp','sexo','fecha_nacimiento','cuidador','direccion','telefono','clues','municipio','localidad','primera_evaluacion'],
         v_user)
 RETURNING id INTO v_id;
 FOR v_consulta IN SELECT value FROM jsonb_array_elements(v_consultas)
 LOOP
   v_n:=v_n+1;
   IF v_consulta->>'fecha_valoracion' IS NULL THEN RAISE EXCEPTION 'Fecha de consulta requerida'; END IF;
   INSERT INTO nf_private.seguimientos(paciente_id,numero_consulta,fecha_valoracion,cedula,capturado_por)
   VALUES (v_id,v_n,(v_consulta->>'fecha_valoracion')::date,v_consulta,v_user);
 END LOOP;
 INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
 VALUES (v_user,'registro_creado',v_folio,jsonb_build_object('consultas',v_n));
 RETURN jsonb_build_object('estado','nuevo','folio',v_folio);
END;
$$;

-- Seguimiento: conserva historial, jamás sobrescribe una valoración.
CREATE OR REPLACE FUNCTION public.nf_agregar_seguimiento(p_folio text,p_consulta jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_user uuid:=auth.uid();
 v_perfil nf_private.perfiles%ROWTYPE;
 v_paciente nf_private.pacientes%ROWTYPE;
 v_num integer;
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT * INTO v_perfil FROM nf_private.perfiles WHERE user_id=v_user AND activo;
 IF NOT FOUND OR v_perfil.rol NOT IN ('capturista','clinico','admin_distrital','admin_estatal') THEN
   RAISE EXCEPTION 'Sin permiso'; END IF;
 SELECT * INTO v_paciente FROM nf_private.pacientes WHERE folio=p_folio FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Folio no encontrado o sin permiso'; END IF;
 IF v_perfil.rol<>'admin_estatal' AND v_paciente.distrito_id IS DISTINCT FROM v_perfil.distrito_id THEN
   RAISE EXCEPTION 'Folio no encontrado o sin permiso'; END IF;
 IF p_consulta->>'fecha_valoracion' IS NULL THEN RAISE EXCEPTION 'Falta fecha de valoración'; END IF;
 SELECT coalesce(max(numero_consulta),0)+1 INTO v_num FROM nf_private.seguimientos WHERE paciente_id=v_paciente.id;
 INSERT INTO nf_private.seguimientos(paciente_id,numero_consulta,fecha_valoracion,cedula,capturado_por)
 VALUES(v_paciente.id,v_num,(p_consulta->>'fecha_valoracion')::date,p_consulta,v_user);
 INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
 VALUES(v_user,'seguimiento_agregado',p_folio,jsonb_build_object('consulta',v_num));
 RETURN jsonb_build_object('estado','ok','folio',p_folio,'consulta_numero',v_num);
END;
$$;

-- No permitir invocación anónima de funciones SECURITY DEFINER.
REVOKE ALL ON FUNCTION public.nf_mi_perfil() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.nf_registrar_cedula(jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.nf_agregar_seguimiento(text,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nf_mi_perfil() TO authenticated;
GRANT EXECUTE ON FUNCTION public.nf_registrar_cedula(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.nf_agregar_seguimiento(text,jsonb) TO authenticated;
-- Bloquear ejecución de función auxiliar al usuario API.
REVOKE ALL ON FUNCTION nf_private.normalizar(text) FROM PUBLIC, anon, authenticated;
COMMIT;

-- HABILITACIÓN MANUAL (no ejecutar automáticamente):
-- 1. Crear cuenta institucional en Supabase Auth.
-- 2. Tomar su UUID de auth.users, sin publicar nombre ni correo.
-- 3. Dar alta en nf_private.perfiles (por SQL Editor):
-- INSERT INTO nf_private.perfiles(user_id, rol, distrito_id, activo)
-- VALUES ('UUID-DE-AUTH', 'capturista', 5, true);
-- 4. Probar: llamadas anónimas fallan; distrito 5 no puede consultar/editar otro.
-- 5. Verificar políticas, privilegios, auditoría, retención y respaldos ANTES de datos reales.
