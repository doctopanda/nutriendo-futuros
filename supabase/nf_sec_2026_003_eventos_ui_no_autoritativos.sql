-- NF-SEC-2026-003 · Canal de eventos UI no autoritativo
-- Nunca permitir que el cliente simule eventos internos/administrativos.
-- Conserva la firma RPC. No cambia pacientes ni cuentas.
CREATE OR REPLACE FUNCTION public.nf_registrar_evento_ui(
 p_accion text, p_modulo text, p_folio text DEFAULT NULL,
 p_detalle jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $fn$
DECLARE
  perfil nf_private.perfiles%ROWTYPE;
  v_accion text := btrim(coalesce(p_accion,''));
  v_modulo text := btrim(coalesce(p_modulo,''));
BEGIN
  SELECT * INTO perfil FROM nf_private.perfiles
    WHERE user_id=(select auth.uid()) AND activo IS TRUE;
  IF NOT FOUND OR perfil.rol NOT IN
    ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud')
  THEN RAISE EXCEPTION 'Sesión sin perfil institucional activo'
    USING ERRCODE='42501'; END IF;

  IF length(v_accion) NOT BETWEEN 1 AND 60
     OR length(v_modulo) NOT BETWEEN 1 AND 60
     OR v_accion !~ '^[[:alnum:]_-]+$'
     OR v_modulo !~ '^[[:alnum:]_-]+$'
  THEN RAISE EXCEPTION 'Evento UI inválido' USING ERRCODE='22023'; END IF;
  IF p_detalle IS NOT NULL AND
    (jsonb_typeof(p_detalle) <> 'object' OR length(p_detalle::text)>1000)
  THEN RAISE EXCEPTION 'Metadatos UI inválidos' USING ERRCODE='22023'; END IF;
  IF p_folio IS NOT NULL THEN
    IF length(p_folio)>30 OR NOT EXISTS (
      SELECT 1 FROM nf_private.pacientes v
      WHERE v.folio=p_folio AND
        (perfil.rol IN ('admin_maestro','admin_estatal')
         OR v.distrito_id=perfil.distrito_id)
    ) THEN RAISE EXCEPTION 'Folio fuera de jurisdicción'
      USING ERRCODE='42501'; END IF;
  END IF;
  -- El prefijo distingue hechos declarados por cliente de actos verificados.
  -- No aceptar detalles libres del cliente como evidencia privilegiada.
  PERFORM nf_private.registrar_bitacora(
    'ui_'||v_accion, 'ui_'||v_modulo, p_folio,
    jsonb_build_object('fuente','cliente_no_verificado',
                       'longitud_detalle_recibido',
                       length(coalesce(p_detalle,'{}'::jsonb)::text))
  );
  RETURN jsonb_build_object('estado','ok');
END
$fn$;
