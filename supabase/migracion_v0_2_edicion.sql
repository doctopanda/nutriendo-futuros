-- Nutriendo Futuros · Migración 0.2: corrección restringida del registro existente.
-- Ejecutar después de schema_v0_1.sql. Revisar institucionalmente antes de uso real.
BEGIN;
CREATE OR REPLACE FUNCTION public.nf_editar_paciente(
 p_folio text,
 p_cambios jsonb,
 p_motivo text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
 v_user uuid := auth.uid();
 v_perfil nf_private.perfiles%ROWTYPE;
 v_paciente nf_private.pacientes%ROWTYPE;
 v_nombre text; v_dob date; v_sexo text; v_curp text; v_clave text;
 v_conflicto uuid;
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'No autorizado'; END IF;
 SELECT * INTO v_perfil FROM nf_private.perfiles WHERE user_id=v_user AND activo;
 IF NOT FOUND OR v_perfil.rol NOT IN ('admin_estatal','admin_distrital') THEN
   RAISE EXCEPTION 'La corrección requiere autorización administrativa';
 END IF;
 IF p_motivo NOT IN ('Error de transcripción','Rectificación de identidad','Actualización de contacto') THEN
   RAISE EXCEPTION 'Motivo no permitido';
 END IF;
 IF p_cambios IS NULL OR jsonb_typeof(p_cambios)<>'object' THEN
   RAISE EXCEPTION 'Cambios inválidos';
 END IF;
 -- Solo campos explícitos. No se puede alterar folio, distrito ni historial clínico.
 IF EXISTS(SELECT 1 FROM jsonb_object_keys(p_cambios) c(k) WHERE k NOT IN
 ('nombre','fecha_nacimiento','sexo','curp','cuidador','direccion','telefono')) THEN
   RAISE EXCEPTION 'Campo de edición no autorizado';
 END IF;
 SELECT * INTO v_paciente FROM nf_private.pacientes WHERE folio=p_folio FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Folio no encontrado o sin autorización'; END IF;
 IF v_perfil.rol='admin_distrital' AND v_paciente.distrito_id IS DISTINCT FROM v_perfil.distrito_id THEN
   RAISE EXCEPTION 'Folio no encontrado o sin autorización';
 END IF;
 v_nombre:=CASE WHEN p_cambios ? 'nombre'
     THEN nf_private.normalizar(p_cambios->>'nombre') ELSE v_paciente.nombre END;
 v_dob:=CASE WHEN p_cambios ? 'fecha_nacimiento'
     THEN (p_cambios->>'fecha_nacimiento')::date ELSE v_paciente.fecha_nacimiento END;
 v_sexo:=CASE WHEN p_cambios ? 'sexo'
     THEN upper(p_cambios->>'sexo') ELSE v_paciente.sexo END;
 v_curp:=CASE WHEN p_cambios ? 'curp'
     THEN nullif(upper(trim(coalesce(p_cambios->>'curp',''))),'') ELSE v_paciente.curp END;
 IF v_dob IS NULL OR v_dob>current_date OR v_sexo NOT IN ('F','M')
    OR length(v_nombre) NOT BETWEEN 3 AND 160
    OR (v_curp IS NOT NULL AND v_curp !~ '^[A-Z0-9]{18}$') THEN
   RAISE EXCEPTION 'Valor de identidad inválido';
 END IF;
 v_clave:=v_nombre||'|'||v_dob::text||'|'||v_sexo;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_clave,0));
 SELECT id INTO v_conflicto FROM nf_private.pacientes
 WHERE id<>v_paciente.id AND (claves_identidad=v_clave OR (v_curp IS NOT NULL AND curp=v_curp))
 LIMIT 1;
 IF v_conflicto IS NOT NULL THEN RAISE EXCEPTION 'Posible identidad existente. Solicitar conciliación'; END IF;
 UPDATE nf_private.pacientes SET
 nombre=v_nombre, fecha_nacimiento=v_dob, sexo=v_sexo, curp=v_curp, claves_identidad=v_clave,
 cuidador=CASE WHEN p_cambios ? 'cuidador' THEN p_cambios->>'cuidador' ELSE cuidador END,
 direccion=CASE WHEN p_cambios ? 'direccion' THEN p_cambios->>'direccion' ELSE direccion END,
 telefono=CASE WHEN p_cambios ? 'telefono' THEN p_cambios->>'telefono' ELSE telefono END,
 actualizado_en=now()
 WHERE id=v_paciente.id;
 INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
 VALUES(v_user,'correccion_identidad',p_folio,
 jsonb_build_object('motivo',p_motivo,'tipo','edicion_controlada'));
 RETURN jsonb_build_object('estado','actualizado','folio',p_folio);
END; $$;
REVOKE ALL ON FUNCTION public.nf_editar_paciente(text,jsonb,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.nf_editar_paciente(text,jsonb,text) TO authenticated;
COMMIT;
