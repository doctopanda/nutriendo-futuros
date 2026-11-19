-- NF-SEC-2026-002: restringir asignación libre al Maestro. La aprobación estatal de solicitudes por RPC separada se conserva.
CREATE OR REPLACE FUNCTION public.nf_asignar_usuario_existente(p_correo text, p_rol text, p_distrito_id smallint DEFAULT NULL::smallint, p_activo boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  perfil nf_private.perfiles%ROWTYPE;
  uid uuid;
BEGIN
  SELECT * INTO perfil FROM nf_private.perfiles WHERE user_id = auth.uid() AND activo;
  IF NOT FOUND OR perfil.rol <> 'admin_maestro' THEN
    RAISE EXCEPTION 'Sólo Administrador Maestro puede asignar o modificar roles existentes';
  END IF;

  IF p_rol NOT IN ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN
    RAISE EXCEPTION 'Rol no válido';
  END IF;
  IF p_rol IN ('admin_maestro','admin_estatal') AND p_distrito_id IS NOT NULL THEN
    RAISE EXCEPTION 'Los roles estatales/maestro no deben llevar distrito';
  END IF;
  IF p_rol IN ('supervisor_distrital','promotor_salud') AND (p_distrito_id IS NULL OR p_distrito_id NOT BETWEEN 1 AND 6) THEN
    RAISE EXCEPTION 'Los roles distritales requieren distrito válido';
  END IF;

  IF perfil.rol='admin_estatal' AND p_rol IN ('admin_maestro','admin_estatal') THEN RAISE EXCEPTION 'Sólo Maestro puede crear o modificar administradores superiores'; END IF; IF lower(trim(p_correo))='ibrahimharos@gmail.com' AND (p_rol<>'admin_maestro' OR p_distrito_id IS NOT NULL OR p_activo IS DISTINCT FROM true) THEN RAISE EXCEPTION 'La cuenta maestra inicial no puede ser desactivada ni degradada'; END IF; SELECT id INTO uid FROM auth.users WHERE lower(email) = lower(trim(p_correo)) LIMIT 1;
  IF uid IS NULL THEN
    RAISE EXCEPTION 'El correo aún no existe en auth.users';
  END IF;

  INSERT INTO nf_private.perfiles(user_id, rol, distrito_id, activo)
  VALUES(uid, p_rol, p_distrito_id, p_activo)
  ON CONFLICT (user_id)
  DO UPDATE SET rol = excluded.rol, distrito_id = excluded.distrito_id, activo = excluded.activo;

  PERFORM nf_private.registrar_bitacora('asignacion_usuario','accesos',NULL,jsonb_build_object('correo', lower(trim(p_correo)), 'rol', p_rol, 'distrito_id', p_distrito_id, 'activo', p_activo));

  RETURN jsonb_build_object('estado','ok','correo',lower(trim(p_correo)),'rol',p_rol,'distrito_id',p_distrito_id,'activo',p_activo);
END;
$function$
;
