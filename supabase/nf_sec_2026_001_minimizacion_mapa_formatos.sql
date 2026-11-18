-- NF-SEC-2026-001 · 2026-11-18
-- Minimización del mapa privado y retiro de roles heredados en formatos nominales.
-- No altera datos, folios, validación en sitio ni políticas de captura.
CREATE OR REPLACE FUNCTION public.nf_folios_para_mapa(
  p_distrito smallint DEFAULT NULL,
  p_limite integer DEFAULT 200
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  perfil nf_private.perfiles%ROWTYPE;
  salida jsonb;
BEGIN
  SELECT * INTO perfil FROM nf_private.perfiles
  WHERE user_id = (SELECT auth.uid()) AND activo IS TRUE;
  IF NOT FOUND OR perfil.rol NOT IN
    ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud')
  THEN RAISE EXCEPTION 'Acceso denegado' USING ERRCODE='42501'; END IF;
  IF p_distrito IS NOT NULL AND p_distrito NOT BETWEEN 1 AND 6
  THEN RAISE EXCEPTION 'Distrito inválido' USING ERRCODE='22023'; END IF;
  SELECT COALESCE(jsonb_agg(to_jsonb(q) ORDER BY q.folio), '[]'::jsonb)
  INTO salida
  FROM (
    SELECT v.folio, a.codigo AS codigo_leet, v.distrito_id,
      v.estatus, v.datos_incompletos,
      jsonb_array_length(v.campos_faltantes) AS pendientes,
      h.lat, h.lon,
      CASE WHEN h.lat IS NOT NULL AND h.lon IS NOT NULL
           THEN 'hospital_referencia_verificado'::text ELSE NULL::text END
        AS origen_coordenadas
    FROM nf_private.pacientes v
    JOIN nf_private.leet_aliases a ON a.paciente_id=v.id
    LEFT JOIN nf_private.hospitales_referencia h ON
      h.clues=v.clues AND h.verificado IS TRUE
      AND h.distrito_id=v.distrito_id
      AND h.lat BETWEEN 25 AND 33 AND h.lon BETWEEN -115 AND -108
    WHERE (perfil.rol IN ('admin_maestro','admin_estatal')
           OR v.distrito_id=perfil.distrito_id)
      AND (p_distrito IS NULL OR v.distrito_id=p_distrito)
    ORDER BY v.creado_en DESC
    LIMIT LEAST(GREATEST(COALESCE(p_limite,200),1),200)
  ) q;
  RETURN salida;
END $$;

CREATE OR REPLACE FUNCTION public.nf_datos_para_envio(p_folio text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
  u uuid := (SELECT auth.uid());
  perfil nf_private.perfiles%ROWTYPE;
  pac nf_private.pacientes%ROWTYPE;
  c jsonb;
BEGIN
  IF u IS NULL THEN
    RAISE EXCEPTION 'No autorizado' USING ERRCODE='42501';
  END IF;
  SELECT * INTO perfil FROM nf_private.perfiles
    WHERE user_id=u AND activo IS TRUE;
  IF NOT FOUND OR perfil.rol NOT IN ('admin_maestro','admin_estatal')
  THEN RAISE EXCEPTION 'Sin permiso para emitir formatos nominales'
    USING ERRCODE='42501'; END IF;
  SELECT * INTO pac FROM nf_private.pacientes WHERE folio=p_folio;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Folio inexistente o sin permiso' USING ERRCODE='42501';
  END IF;
  SELECT cedula INTO c FROM nf_private.seguimientos
    WHERE paciente_id=pac.id ORDER BY numero_consulta DESC LIMIT 1;
  INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
    VALUES (u,'consulta_identidad_para_formato',p_folio,
      jsonb_build_object('uso','generar_pdf_envio'));
  RETURN jsonb_build_object(
    'folio',pac.folio,'nombre',pac.nombre,'curp',pac.curp,
    'sexo',pac.sexo,'fecha_nacimiento',pac.fecha_nacimiento,
    'cuidador',pac.cuidador,'direccion',pac.direccion,
    'telefono',pac.telefono,'municipio',pac.municipio,
    'localidad',pac.localidad,'clues',pac.clues,
    'distrito_id',pac.distrito_id,'ultima_consulta',COALESCE(c,'{}'::jsonb)
  );
END $$;
