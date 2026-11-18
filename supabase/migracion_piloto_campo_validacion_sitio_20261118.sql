-- NUTRIENDO FUTUROS | Migracion consolidada del piloto de campo 2026-11-18
-- Version reproducible del esquema, funciones y triggers APPLICADOS en Supabase.
-- NO ejecutar dos veces sin verificar dependencias. No contiene datos clinicos.
begin;
alter table nf_private.pacientes
 alter column cuidador drop not null,
 alter column clues drop not null,
 alter column municipio drop not null,
 alter column localidad drop not null;
alter table nf_private.pacientes
 add column if not exists validacion_modalidad text not null default 'SITIO',
 add column if not exists validado_en_sitio_en timestamptz,
 add column if not exists validado_en_sitio_por uuid,
 add column if not exists datos_incompletos boolean not null default false,
 add column if not exists campos_faltantes jsonb not null default '[]'::jsonb,
 add column if not exists auditoria_datos_actualizada_en timestamptz;
do $do$ begin
 if not exists(select 1 from pg_constraint where conname='nf_paciente_validacion_modalidad_chk' and conrelid='nf_private.pacientes'::regclass) then
 alter table nf_private.pacientes add constraint nf_paciente_validacion_modalidad_chk check(validacion_modalidad in ('SITIO','ESTATAL')) not valid;
 end if;
end $do$;
create table if not exists nf_private.auditoria_datos(
 id bigint generated always as identity primary key,
 paciente_id uuid not null references nf_private.pacientes(id),
 folio text not null,
 usuario_id uuid,
 evento text not null check (evento in ('ALTA','VALORACION','RECTIFICACION','REVISION')),
 campos_faltantes jsonb not null default '[]'::jsonb,
 incompleto boolean not null default false,
 ocurrido_en timestamptz not null default now()
);
create index if not exists nf_auditoria_datos_paciente_fecha_idx on nf_private.auditoria_datos(paciente_id,ocurrido_en desc);
alter table nf_private.auditoria_datos enable row level security;
revoke all on nf_private.auditoria_datos from public,anon,authenticated;
revoke all on sequence nf_private.auditoria_datos_id_seq from public,anon,authenticated;
CREATE OR REPLACE FUNCTION nf_private.nf_evaluar_integridad(p_ident jsonb, p_consulta jsonb, p_d smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare pendientes jsonb:='[]'::jsonb; c text; ok boolean;
begin
  foreach c in array array['nombre','fecha_nacimiento','sexo','cuidador','direccion','telefono','clues','municipio','localidad','primera_evaluacion'] loop
    if nullif(btrim(coalesce(p_ident->>c,'')),'') is null then
      pendientes:=pendientes||pg_catalog.jsonb_build_array(c);
    end if;
  end loop;
  foreach c in array array['fecha_valoracion','talla_cm','peso_kg','pbm_cm'] loop
    if nullif(btrim(coalesce(p_consulta->>c,'')),'') is null or
      (c in ('talla_cm','peso_kg','pbm_cm') and (p_consulta->>c) ~ '^0+(\\.0+)?$')
    then pendientes:=pendientes||pg_catalog.jsonb_build_array(c); end if;
  end loop;
  if nullif(btrim(coalesce(p_ident->>'clues','')),'') is not null then
    select exists(select 1 from nf_private.clues_autorizadas z
      where pg_catalog.upper(pg_catalog.btrim(z.clues))=pg_catalog.upper(pg_catalog.btrim(p_ident->>'clues'))
        and nf_private.normalizar(z.municipio)=nf_private.normalizar(p_ident->>'municipio')
        and z.distrito_id=p_d and z.activa and z.verificada)
     into ok;
    if not ok then pendientes:=pendientes||'["clues_catalogo_no_verificada"]'::jsonb;end if;
  end if;
  return pendientes;
end $function$;

CREATE OR REPLACE FUNCTION nf_private.nf_refrescar_auditoria_datos(p_paciente uuid, p_evento text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare v nf_private.pacientes%rowtype; c jsonb:='{}'::jsonb; identidad jsonb;
       pendientes jsonb; ev text;
begin
  select * into v from nf_private.pacientes where id=p_paciente;
  if not found then return; end if;
  select cedula into c from nf_private.seguimientos where paciente_id=v.id
    order by numero_consulta desc limit 1;
  identidad:=pg_catalog.jsonb_build_object(
    'nombre',v.nombre,'fecha_nacimiento',v.fecha_nacimiento,'sexo',v.sexo,
    'cuidador',v.cuidador,'direccion',v.direccion,'telefono',v.telefono,
    'clues',v.clues,'municipio',v.municipio,'localidad',v.localidad,
    'primera_evaluacion',v.primera_evaluacion);
  pendientes:=nf_private.nf_evaluar_integridad(identidad,coalesce(c,'{}'::jsonb),v.distrito_id);
  ev:=case when p_evento in ('ALTA','VALORACION','RECTIFICACION','REVISION') then p_evento else 'REVISION' end;
  update nf_private.pacientes
     set datos_incompletos=(pg_catalog.jsonb_array_length(pendientes)>0),
         campos_faltantes=pendientes,
         auditoria_datos_actualizada_en=now()
   where id=v.id;
  insert into nf_private.auditoria_datos(paciente_id,folio,usuario_id,evento,campos_faltantes,incompleto)
  values(v.id,v.folio,auth.uid(),ev,pendientes,pg_catalog.jsonb_array_length(pendientes)>0);
end $function$;

CREATE OR REPLACE FUNCTION nf_private.nf_tg_auditoria_datos()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if TG_TABLE_NAME='seguimientos' then
    perform nf_private.nf_refrescar_auditoria_datos(NEW.paciente_id,
      case when NEW.numero_consulta=1 and TG_OP='INSERT' then 'ALTA' else 'VALORACION' end);
  else
    perform nf_private.nf_refrescar_auditoria_datos(NEW.id,'RECTIFICACION');
  end if;
  return NEW;
end $function$;

CREATE OR REPLACE FUNCTION nf_private.validar_clues_paciente()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare validada boolean;
begin
  if nullif(pg_catalog.btrim(coalesce(NEW.clues,'')),'') is not null then
    select exists(select 1 from nf_private.clues_autorizadas c
      where pg_catalog.upper(pg_catalog.btrim(c.clues))=pg_catalog.upper(pg_catalog.btrim(NEW.clues))
        and nf_private.normalizar(c.municipio)=nf_private.normalizar(NEW.municipio)
        and c.distrito_id=NEW.distrito_id and c.activa and c.verificada)
      into validada;
    if not validada then
      insert into nf_private.auditoria(usuario_id,accion,folio,detalle)
      values(auth.uid(),'clues_pendiente_piloto',NEW.folio,
        pg_catalog.jsonb_build_object('distrito',NEW.distrito_id,'requiere_revision_catalogo',true));
    end if;
  end if;
  -- Piloto: no bloquear ingreso ni alterar estado asistencial por catálogo territorial
  return NEW;
end $function$;

CREATE OR REPLACE FUNCTION public.nf_prevalidar_cedula(p_documento jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); p nf_private.perfiles%rowtype; i jsonb; a jsonb;
 d smallint; faltantes jsonb; bloqueos jsonb:='[]'::jsonb;
begin
  select * into p from nf_private.perfiles where user_id=u and activo;
  if not found or p.rol not in ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') then
     raise exception 'Acceso denegado';
  end if;
  if p_documento is null or pg_catalog.jsonb_typeof(p_documento)<>'object'
     or pg_catalog.length(p_documento::text)>65000 then raise exception 'Documento inválido'; end if;
  i:=p_documento->'identidad';a:=p_documento->'consultas';
  if pg_catalog.jsonb_typeof(i)<>'object' or pg_catalog.jsonb_typeof(a)<>'array' then
    raise exception 'Cédula sin estructura válida';
  end if;
  d:=case when p.rol in ('admin_maestro','admin_estatal') then nullif(i->>'distrito_id','')::smallint else p.distrito_id end;
  if d is null or d not between 1 and 6 then bloqueos:=bloqueos||'["distrito_id"]'::jsonb;end if;
  if i->>'autorizacion' is distinct from 'si' then bloqueos:=bloqueos||'["autorizacion"]'::jsonb;end if;
  if nullif(pg_catalog.btrim(coalesce(i->>'nombre','')),'') is null then bloqueos:=bloqueos||'["nombre"]'::jsonb;end if;
  if nullif(i->>'fecha_nacimiento','') is null then bloqueos:=bloqueos||'["fecha_nacimiento"]'::jsonb;end if;
  if i->>'sexo' not in ('F','M') or i->>'sexo' is null then bloqueos:=bloqueos||'["sexo"]'::jsonb;end if;
  if pg_catalog.jsonb_array_length(a)=0 or nullif(a->0->>'fecha_valoracion','') is null then bloqueos:=bloqueos||'["fecha_valoracion"]'::jsonb;end if;
  faltantes:=nf_private.nf_evaluar_integridad(i,coalesce(a->0,'{}'::jsonb),d);
  return pg_catalog.jsonb_build_object('modalidad','SITIO','bloqueantes',bloqueos,'campos_faltantes',faltantes,
    'datos_incompletos',pg_catalog.jsonb_array_length(faltantes)>0,'guardable',pg_catalog.jsonb_array_length(bloqueos)=0);
end $function$;

CREATE OR REPLACE FUNCTION public.nf_registrar_cedula(p_documento jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE u uuid:=auth.uid(); p nf_private.perfiles%ROWTYPE; ident jsonb; consultas jsonb;
 d smallint; nombre text; sexo text; curp text; dob date; clave text;
 existe nf_private.pacientes%ROWTYPE; numero bigint; folio_nuevo text; paciente_nuevo uuid;
 c jsonb; n integer:=0; fecha_primera date;
BEGIN
 IF u IS NULL THEN RAISE EXCEPTION 'Sesión requerida'; END IF;
 SELECT * INTO p FROM nf_private.perfiles WHERE user_id=u AND activo;
 IF NOT FOUND OR p.rol NOT IN ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN RAISE EXCEPTION 'No autorizado para capturar'; END IF;
 IF p_documento IS NULL OR jsonb_typeof(p_documento)<>'object' OR length(p_documento::text)>65000 THEN RAISE EXCEPTION 'Documento inválido'; END IF;
 ident:=p_documento->'identidad'; consultas:=p_documento->'consultas';
 IF jsonb_typeof(ident)<>'object' OR jsonb_typeof(consultas)<>'array' OR jsonb_array_length(consultas) NOT BETWEEN 1 AND 12 THEN RAISE EXCEPTION 'Cédula incompleta'; END IF;
 IF ident->>'autorizacion' IS DISTINCT FROM 'si' THEN RAISE EXCEPTION 'Registro sin autorización documentada'; END IF;
 IF p.rol IN ('admin_estatal','admin_maestro') THEN d:=nullif(ident->>'distrito_id','')::smallint;
 ELSE d:=p.distrito_id;
 END IF;
 IF d IS NULL OR d NOT BETWEEN 1 AND 6 THEN RAISE EXCEPTION 'Distrito inválido'; END IF;
 nombre:=nf_private.normalizar(coalesce(ident->>'nombre',''));
 sexo:=upper(coalesce(ident->>'sexo',''));
 curp:=nullif(upper(trim(coalesce(ident->>'curp',''))),'');
 IF length(nombre) NOT BETWEEN 3 AND 160 OR sexo NOT IN ('F','M') THEN RAISE EXCEPTION 'Identidad esencial insuficiente'; END IF;
 IF curp IS NOT NULL AND curp !~ '^[A-Z0-9]{18}$' THEN RAISE EXCEPTION 'CURP con formato inválido'; END IF;
 dob:=nullif(ident->>'fecha_nacimiento','')::date;
 fecha_primera:=nullif(ident->>'primera_evaluacion','')::date;
 IF dob IS NULL OR dob>current_date OR fecha_primera IS NULL OR fecha_primera<dob OR fecha_primera>current_date THEN RAISE EXCEPTION 'Fechas inválidas'; END IF;
   IF curp IS NOT NULL THEN
    IF NOT nf_private.nfs_curp_estructura_correcta(curp) THEN RAISE EXCEPTION 'CURP con estructura o digito verificador invalidos'; END IF;
    IF substring(curp from 5 for 6)<>pg_catalog.to_char(dob,'YYMMDD')
       OR substring(curp from 11 for 1)<>(CASE WHEN sexo='M' THEN 'H' ELSE 'M' END)
       OR (extract(year from dob)>=2000 AND substring(curp from 17 for 1) !~ '^[A-J]$')
       OR (extract(year from dob)<2000 AND substring(curp from 17 for 1) !~ '^[0-9]$')
    THEN RAISE EXCEPTION 'CURP no coincide con fecha o sexo; verificar documento'; END IF;
   END IF;
 clave:=nombre||'|'||dob::text||'|'||sexo;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(clave,0));
 SELECT * INTO existe FROM nf_private.pacientes
 WHERE (NULLIF(upper(trim(coalesce(ident->>'curp',''))),'') IS NOT NULL AND pacientes.curp=NULLIF(upper(trim(coalesce(ident->>'curp',''))),'')) OR claves_identidad=clave
 ORDER BY CASE WHEN distrito_id=d THEN 0 ELSE 1 END,creado_en LIMIT 1;
 IF FOUND THEN
    INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle) VALUES(u,'intento_registro_repetido',existe.folio,jsonb_build_object('distrito',d));
    RETURN jsonb_build_object('estado','requiere_revision','folio',CASE WHEN p.rol IN ('admin_estatal','admin_maestro') THEN existe.folio ELSE NULL END);
 END IF;
 UPDATE nf_private.folios_distritales SET ultimo_numero=ultimo_numero+1
  WHERE distrito_id=d AND ultimo_numero<99999999 RETURNING ultimo_numero INTO numero;
 IF numero IS NULL THEN RAISE EXCEPTION 'Folios agotados'; END IF;
 folio_nuevo:='NF-DS'||d||'-'||pg_catalog.lpad(numero::text,8,'0');
 INSERT INTO nf_private.pacientes(folio,distrito_id,nombre,fecha_nacimiento,sexo,curp,cuidador,direccion,telefono,claves_identidad,clues,municipio,localidad,primera_evaluacion,datos_contexto,creado_por)
 VALUES(folio_nuevo,d,nombre,dob,sexo,curp,trim(ident->>'cuidador'),ident->>'direccion',ident->>'telefono',clave,upper(trim(ident->>'clues')),trim(ident->>'municipio'),trim(ident->>'localidad'),fecha_primera,
  -- Almacenar solo el código escolar, nunca posición exacta de vivienda en JSON contextual
  jsonb_build_object('escuela_cct',nullif(upper(trim(coalesce(ident->>'escuela_cct',''))),''),
                      'entidad_nacimiento_curp_codigo',CASE WHEN curp IS NULL THEN NULL ELSE substring(curp from 12 for 2) END),u)
 RETURNING id INTO paciente_nuevo;
 UPDATE nf_private.pacientes SET validacion_modalidad='SITIO', validado_en_sitio_en=now(), validado_en_sitio_por=u WHERE id=paciente_nuevo;
 FOR c IN SELECT value FROM pg_catalog.jsonb_array_elements(consultas) LOOP
   n:=n+1;
   IF jsonb_typeof(c)<>'object' OR nullif(c->>'fecha_valoracion','') IS NULL OR pg_catalog.length(c::text)>14000 THEN RAISE EXCEPTION 'Valoración inválida'; END IF;
   INSERT INTO nf_private.seguimientos(paciente_id,numero_consulta,fecha_valoracion,cedula,capturado_por)
   VALUES(paciente_nuevo,n,(c->>'fecha_valoracion')::date,c,u);
 END LOOP;
 INSERT INTO nf_private.eventos_seguimiento(paciente_id,distrito_id,tipo,ocurrido_en,registrado_por)
 VALUES(paciente_nuevo,d,'TAMIZAJE',fecha_primera::timestamptz,u);
 INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
 VALUES(u,'registro_creado',folio_nuevo,jsonb_build_object('distrito',d,'valoraciones',n));
 RETURN jsonb_build_object('estado','nuevo','folio',folio_nuevo,'validacion_modalidad','SITIO',
  'datos_incompletos',(SELECT datos_incompletos FROM nf_private.pacientes WHERE id=paciente_nuevo),
  'campos_faltantes',(SELECT campos_faltantes FROM nf_private.pacientes WHERE id=paciente_nuevo));
END $function$;

CREATE OR REPLACE FUNCTION public.nf_listar_folios(p_busqueda text DEFAULT NULL::text, p_limite integer DEFAULT 150)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE p nf_private.perfiles%ROWTYPE; lista jsonb;
BEGIN
 SELECT * INTO p FROM nf_private.perfiles WHERE user_id=auth.uid() AND activo;
 IF NOT FOUND OR p.rol NOT IN ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN RAISE EXCEPTION 'Acceso denegado'; END IF;
 IF p_busqueda IS NOT NULL AND length(p_busqueda)>25 THEN RAISE EXCEPTION 'Búsqueda inválida'; END IF;
 SELECT coalesce(pg_catalog.jsonb_agg(to_jsonb(q) ORDER BY q.folio),'[]'::jsonb) INTO lista FROM (
  SELECT v.folio,v.distrito_id,v.municipio,
   v.localidad AS localidad,
   v.estatus,v.validacion_modalidad,v.datos_incompletos,
   pg_catalog.jsonb_array_length(v.campos_faltantes) AS numero_campos_faltantes,
   ((extract(year FROM age(current_date,v.fecha_nacimiento))::integer*12)+extract(month FROM age(current_date,v.fecha_nacimiento))::integer) AS edad_meses,
   CASE WHEN p.rol IN ('admin_maestro','admin_estatal','supervisor_distrital') OR v.creado_por=auth.uid() THEN v.datos_contexto->>'escuela_cct' ELSE NULL END AS escuela_cct,
   (SELECT max(s.fecha_valoracion) FROM nf_private.seguimientos s WHERE s.paciente_id=v.id) AS ultima_consulta,
   (SELECT count(*)::integer FROM nf_private.seguimientos s WHERE s.paciente_id=v.id) AS consultas
  FROM nf_private.pacientes v
  WHERE (p.rol IN ('admin_estatal','admin_maestro') OR v.distrito_id=p.distrito_id)
  AND (p_busqueda IS NULL OR v.folio ILIKE '%'||p_busqueda||'%')
  ORDER BY v.creado_en DESC LIMIT least(greatest(coalesce(p_limite,150),1),200)
 )q;
 RETURN lista;
END $function$;

CREATE OR REPLACE FUNCTION public.nf_auditar_integridad(p_folio text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE p nf_private.perfiles%ROWTYPE;outjson jsonb;
BEGIN
 SELECT * INTO p FROM nf_private.perfiles WHERE user_id=auth.uid() AND activo;
 IF NOT FOUND OR p.rol NOT IN ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN RAISE EXCEPTION 'Sin permiso'; END IF;
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.folio),'[]'::jsonb) INTO outjson FROM (
  SELECT v.folio,v.distrito_id,v.validacion_modalidad,v.datos_incompletos,
    v.campos_faltantes,v.auditoria_datos_actualizada_en,
   (v.telefono IS NULL OR btrim(v.telefono)='') AS telefono_faltante,
   (v.direccion IS NULL OR btrim(v.direccion)='') AS direccion_faltante,
   (v.datos_contexto->>'escuela_cct' IS NULL OR v.datos_contexto->>'escuela_cct'='') AS cct_faltante,
   (ultimo.cedula IS NULL OR nullif(ultimo.cedula->>'talla_cm','') IS NULL) AS talla_faltante,
   (ultimo.cedula IS NULL OR nullif(ultimo.cedula->>'peso_kg','') IS NULL) AS peso_faltante,
   (ultimo.cedula IS NULL OR nullif(ultimo.cedula->>'pbm_cm','') IS NULL) AS pbm_faltante,
   (SELECT count(*)::integer FROM nf_private.solicitudes_contacto r WHERE r.paciente_id=v.id AND r.estado IN ('PENDIENTE','EN_GESTION')) AS solicitudes_contacto_abiertas
  FROM nf_private.pacientes v
  LEFT JOIN LATERAL (SELECT cedula FROM nf_private.seguimientos WHERE paciente_id=v.id ORDER BY numero_consulta DESC LIMIT 1)ultimo ON TRUE
  WHERE (p.rol IN ('admin_estatal','admin_maestro') OR v.distrito_id=p.distrito_id) AND (p_folio IS NULL OR v.folio=p_folio)
  ORDER BY v.creado_en DESC LIMIT 250
 )q;
 RETURN outjson;
END $function$;

CREATE OR REPLACE FUNCTION public.nf_detalle_folio(p_folio text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE p nf_private.perfiles%ROWTYPE;v nf_private.pacientes%ROWTYPE;visitas jsonb;
BEGIN
 SELECT * INTO p FROM nf_private.perfiles WHERE user_id=auth.uid() AND activo;
 IF NOT FOUND OR p.rol NOT IN ('admin_maestro','admin_estatal','supervisor_distrital','promotor_salud') THEN RAISE EXCEPTION 'Sin acceso clínico'; END IF;
 SELECT * INTO v FROM nf_private.pacientes WHERE folio=p_folio;
 IF NOT FOUND OR (p.rol NOT IN ('admin_estatal','admin_maestro') AND v.distrito_id IS DISTINCT FROM p.distrito_id) THEN RAISE EXCEPTION 'Folio fuera de jurisdicción'; END IF;
 SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
  'numero_consulta',s.numero_consulta,
  'fecha_valoracion',s.fecha_valoracion,
  'cedula',(SELECT coalesce(pg_catalog.jsonb_object_agg(key,value),'{}'::jsonb) FROM pg_catalog.jsonb_each(s.cedula)
    WHERE key IN ('fecha_valoracion','edad_anos','edad_meses','talla_cm','peso_kg','pbm_cm','hgb','lactancia','tomas_dia','biberon','otros_alimentos','agua','gripe_tos','fiebre','diarrea','vomito','anorexia','discapacidad','tipo_discapacidad','prueba_apetito','edema','grado_edema','pz_plt','pz_lte','pz_pe','clasificacion_pz','clasificacion_pbm','desparasitacion','dosis_desparasitacion','micronutrientes','dosis_micronutrientes','intervencion','sobres','aceptabilidad','resultado','abandono'))
 ) ORDER BY s.numero_consulta),'[]'::jsonb) INTO visitas
 FROM nf_private.seguimientos s WHERE s.paciente_id=v.id;
 INSERT INTO nf_private.auditoria(usuario_id,accion,folio,detalle)
 VALUES(auth.uid(),'consulta_folio_clinico',p_folio,jsonb_build_object('distrito',v.distrito_id));
 RETURN pg_catalog.jsonb_build_object('folio',v.folio,'distrito_id',v.distrito_id,'municipio',v.municipio,'estatus',v.estatus,'validacion_modalidad',v.validacion_modalidad,'datos_incompletos',v.datos_incompletos,'campos_faltantes',v.campos_faltantes,'consultas',visitas);
END $function$;

-- Disparadores: auditoria al crear valoracion y al rectificar datos de captura.
drop trigger if exists nf_auditar_valoracion on nf_private.seguimientos;
create trigger nf_auditar_valoracion after insert or update of cedula,fecha_valoracion
 on nf_private.seguimientos for each row execute function nf_private.nf_tg_auditoria_datos();
drop trigger if exists nf_auditar_rectificacion on nf_private.pacientes;
create trigger nf_auditar_rectificacion after update of nombre,fecha_nacimiento,sexo,cuidador,direccion,telefono,clues,municipio,localidad
 on nf_private.pacientes for each row execute function nf_private.nf_tg_auditoria_datos();
drop trigger if exists nf_guardia_clues on nf_private.pacientes;
create trigger nf_guardia_clues before insert or update of clues,municipio,distrito_id
 on nf_private.pacientes for each row execute function nf_private.validar_clues_paciente();
revoke all on function nf_private.nf_evaluar_integridad(jsonb,jsonb,smallint) from public,anon,authenticated;
revoke all on function nf_private.nf_refrescar_auditoria_datos(uuid,text) from public,anon,authenticated;
revoke all on function nf_private.nf_tg_auditoria_datos() from public,anon,authenticated;
revoke all on function nf_private.validar_clues_paciente() from public,anon,authenticated;
revoke all on function public.nf_prevalidar_cedula(jsonb) from public,anon;
grant execute on function public.nf_prevalidar_cedula(jsonb) to authenticated;
comment on table nf_private.auditoria_datos is 'Historial protegido de advertencias de campos faltantes por ingreso, valoración o rectificación';
comment on column nf_private.pacientes.validacion_modalidad is 'Validación operativa en sitio durante piloto; no implica revisión clínica estatal ni autorización jurídica';
comment on column nf_private.pacientes.campos_faltantes is 'Última revisión de integridad de captura: nombres de campos, sin valores nominales';
commit;
