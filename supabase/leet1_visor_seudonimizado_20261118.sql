-- Nutriendo Futuros: LEET-1, alias privado y visor seudonimizado.
-- Este archivo documenta el estado final del cambio aplicado el 2026-11-18.
-- No ejecutar nuevamente sin comparar primero con el esquema en producción.
BEGIN;

CREATE TABLE IF NOT EXISTS nf_private.leet_aliases (
  paciente_id uuid PRIMARY KEY REFERENCES nf_private.pacientes(id) ON DELETE CASCADE,
  token_uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  codigo text GENERATED ALWAYS AS (
    'NF-L33T1-' || pg_catalog.translate(
      pg_catalog.upper(pg_catalog.replace(token_uuid::text, '-', '')),
      '0123456789ABCDEF','01345789ABCDEFGH'
    )
  ) STORED UNIQUE,
  version smallint NOT NULL DEFAULT 1 CHECK (version=1),
  creado_en timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE nf_private.leet_aliases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON nf_private.leet_aliases FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION nf_private.nf_leet_crear_alias_tras_alta()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
BEGIN
  INSERT INTO nf_private.leet_aliases(paciente_id) VALUES(NEW.id)
  ON CONFLICT(paciente_id) DO NOTHING;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION nf_private.nf_leet_crear_alias_tras_alta() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS nf_leet_alias_tras_alta ON nf_private.pacientes;
CREATE TRIGGER nf_leet_alias_tras_alta AFTER INSERT ON nf_private.pacientes
FOR EACH ROW EXECUTE FUNCTION nf_private.nf_leet_crear_alias_tras_alta();

CREATE OR REPLACE FUNCTION public.nf_leet_codigo_por_folio(p_folio text)
RETURNS text LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $$
DECLARE v_rol text;v_distrito smallint;v_codigo text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Acceso no autorizado' USING ERRCODE='42501';
  END IF;
  SELECT p.rol,p.distrito_id INTO v_rol,v_distrito
  FROM nf_private.perfiles p WHERE p.user_id=auth.uid() AND p.activo IS TRUE;
  IF NOT FOUND OR v_rol NOT IN
    ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN
    RAISE EXCEPTION 'Perfil no autorizado' USING ERRCODE='42501';
  END IF;
  SELECT a.codigo INTO v_codigo FROM nf_private.pacientes c
  JOIN nf_private.leet_aliases a ON a.paciente_id=c.id
  WHERE c.folio=p_folio AND
   (v_rol IN ('admin_maestro','admin_estatal') OR c.distrito_id=v_distrito);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Folio no disponible' USING ERRCODE='42501';
  END IF;
  INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
  VALUES(auth.uid(),'consulta_codigo_leet',p_folio,
         jsonb_build_object('version','LEET-1'));
  RETURN v_codigo;
END $$;
REVOKE ALL ON FUNCTION public.nf_leet_codigo_por_folio(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.nf_leet_codigo_por_folio(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.nf_listar_folios(
  p_busqueda text DEFAULT NULL::text,p_limite integer DEFAULT 150
)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $$
DECLARE p nf_private.perfiles%ROWTYPE;lista jsonb;
BEGIN
  SELECT * INTO p FROM nf_private.perfiles WHERE user_id=auth.uid() AND activo=true;
  IF NOT FOUND OR p.rol NOT IN
    ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN
    RAISE EXCEPTION 'Acceso denegado' USING ERRCODE='42501';
  END IF;
  IF p_busqueda IS NOT NULL AND length(p_busqueda)>25 THEN
    RAISE EXCEPTION 'Búsqueda inválida';
  END IF;
  SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.folio),'[]'::jsonb)
  INTO lista FROM (
    SELECT v.folio,a.codigo AS codigo_leet,v.distrito_id,
      NULL::text AS municipio,NULL::text AS localidad,
      v.estatus,v.validacion_modalidad,v.datos_incompletos,
      jsonb_array_length(v.campos_faltantes) AS numero_campos_faltantes,
      NULL::integer AS edad_meses,
      CASE WHEN v.fecha_nacimiento >= (current_date - interval '12 months') THEN '0-11m'
           WHEN v.fecha_nacimiento >= (current_date - interval '24 months') THEN '12-23m'
           WHEN v.fecha_nacimiento >= (current_date - interval '60 months') THEN '24-59m'
           ELSE '60m+' END AS grupo_edad,
      NULL::text AS escuela_cct,NULL::date AS ultima_consulta,
      (SELECT count(*)::integer FROM nf_private.seguimientos s
       WHERE s.paciente_id=v.id) AS consultas
    FROM nf_private.pacientes v
    INNER JOIN nf_private.leet_aliases a ON a.paciente_id=v.id
    WHERE (p.rol IN ('admin_maestro','admin_estatal') OR v.distrito_id=p.distrito_id)
      AND (p_busqueda IS NULL OR v.folio ILIKE '%'||p_busqueda||'%')
    ORDER BY v.creado_en DESC
    LIMIT least(greatest(coalesce(p_limite,150),1),200)
  )q;
  RETURN lista;
END $$;
REVOKE ALL ON FUNCTION public.nf_listar_folios(text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.nf_listar_folios(text,integer) TO authenticated;

INSERT INTO nf_private.leet_aliases(paciente_id)
SELECT id FROM nf_private.pacientes ON CONFLICT(paciente_id) DO NOTHING;

COMMIT;
