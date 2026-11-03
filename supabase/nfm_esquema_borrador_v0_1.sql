-- NUTRIENDO FUTUROS · RED MULTINIVEL v0.1 · BORRADOR DE MIGRACIÓN
-- Fecha: 2026-11-03
-- NO APLICAR AUTOMÁTICAMENTE A PRODUCCIÓN. Verificación de seguridad, consentimiento,
-- roles institucionales, catálogos CLUES y aceptación de datos sensibles requerida.
-- Este archivo crea extensiones privadas aditivas al esquema existente y NO activa
-- acceso desde el cliente. Ni siquiera los usuarios authenticated pueden leer tablas.
-- Ejecutar primero en un entorno de pruebas/QA con su propia base de datos.
BEGIN;
CREATE SCHEMA IF NOT EXISTS nf_private;
REVOKE ALL ON SCHEMA nf_private FROM PUBLIC, anon, authenticated;

-- Catálogo de unidades confirmado por personal estatal: no inferir acreditación por cercanía.
CREATE TABLE IF NOT EXISTS nf_private.nfm_unidades (
  clues text PRIMARY KEY REFERENCES nf_private.clues_autorizadas(clues),
  nombre text NOT NULL,
  institucion text NOT NULL CHECK (institucion IN ('IMSS','ISSSTE','ISSSTESON','IMSS_BIENESTAR','OTRA')),
  distrito_id smallint NOT NULL CHECK (distrito_id BETWEEN 1 AND 6),
  municipio text NOT NULL,
  domicilio_publico text,
  lat double precision CHECK(lat IS NULL OR lat BETWEEN -90 AND 90),
  lon double precision CHECK(lon IS NULL OR lon BETWEEN -180 AND 180),
  servicios jsonb NOT NULL DEFAULT '{}'::jsonb,
  habilitada boolean NOT NULL DEFAULT false,
  verificada boolean NOT NULL DEFAULT false,
  revisado_por uuid REFERENCES auth.users(id),
  revisado_en timestamptz,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS nfm_unidades_distrito_idx ON nf_private.nfm_unidades(distrito_id,institucion);

-- Nuevos roles como asignaciones institucionales: NO cambia enum nfs_rol existente,
-- ni los permisos ya otorgados al Promotor, Supervisor, Estatal y Maestro.
CREATE TABLE IF NOT EXISTS nf_private.nfm_asignaciones_institucionales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rol text NOT NULL CHECK(rol IN ('unidad_salud','dif')),
  clues text REFERENCES nf_private.nfm_unidades(clues),
  distrito_id smallint CHECK (distrito_id BETWEEN 1 AND 6),
  activo boolean NOT NULL DEFAULT false,
  autorizado_por uuid REFERENCES auth.users(id),
  autorizado_en timestamptz,
  creado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT nfm_scope_role CHECK (
     (rol='unidad_salud' AND clues IS NOT NULL AND distrito_id IS NULL)
     OR (rol='dif' AND clues IS NULL AND distrito_id IS NOT NULL)
  )
);
CREATE UNIQUE INDEX IF NOT EXISTS nfm_asignacion_unidad_unico ON nf_private.nfm_asignaciones_institucionales(user_id,clues) WHERE rol='unidad_salud';
CREATE UNIQUE INDEX IF NOT EXISTS nfm_asignacion_dif_unico ON nf_private.nfm_asignaciones_institucionales(user_id,distrito_id) WHERE rol='dif';
CREATE INDEX IF NOT EXISTS nfm_asignaciones_usuario_idx ON nf_private.nfm_asignaciones_institucionales(user_id,activo);

-- Coordenadas de hogares: USO RESTRINGIDO. El origen y exactitud se documentan;
-- NO son parte de una capa pública o agregados georreferenciados publicados.
CREATE TABLE IF NOT EXISTS nf_private.nfm_domicilios (
  paciente_id uuid PRIMARY KEY REFERENCES nf_private.pacientes(id) ON DELETE CASCADE,
  direccion_confirmada text NOT NULL,
  lat double precision CHECK (lat IS NULL OR lat BETWEEN -90 AND 90),
  lon double precision CHECK (lon IS NULL OR lon BETWEEN -180 AND 180),
  fuente text NOT NULL CHECK (fuente IN ('captura_manual','geocodificacion_verificada','verificacion_campo')),
  precision_geocodificacion text CHECK (precision_geocodificacion IN ('domicilio','calle','colonia','localidad','desconocida')),
  lugar_id_proveedor text,
  validado_por uuid REFERENCES auth.users(id),
  verificado_en timestamptz,
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

-- Consentimiento/fundamento por alcance. Las revocaciones se agregan como eventos,
-- nunca se omiten. No basta un checkbox del frontend para autorizar a DIF.
CREATE TABLE IF NOT EXISTS nf_private.nfm_autorizaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id uuid NOT NULL REFERENCES nf_private.pacientes(id) ON DELETE CASCADE,
  alcance text NOT NULL CHECK (alcance IN ('REFERENCIA_CLINICA','INTERCAMBIO_DIF','CONTACTO_DOMICILIARIO')),
  accion text NOT NULL CHECK (accion IN ('OTORGADA','REVOCADA')),
  sustento text NOT NULL CHECK (length(btrim(sustento)) >= 5),
  version_aviso text NOT NULL,
  responsable_legal text,
  registrado_por uuid NOT NULL REFERENCES auth.users(id),
  registrado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS nfm_autorizaciones_paciente_idx
  ON nf_private.nfm_autorizaciones(paciente_id,alcance,registrado_en DESC);

-- Seguimiento append-only: conservar las referencias originales ya creadas
-- mediante public.nf_guardar_referencia(). No sobreescribir una atención previa.
CREATE TABLE IF NOT EXISTS nf_private.nfm_eventos_referencia (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  referencia_id uuid NOT NULL REFERENCES nf_private.referencias(id),
  tipo text NOT NULL CHECK (tipo IN (
    'REFERENCIA_EMITIDA','CITA_CONFIRMADA','CITA_REAGENDADA','ATENDIDA_NUEVA_CITA',
    'ATENDIDA_DERIVADA','NO_ACUDIO','CONTACTO_DISTRITAL','SEGUIMIENTO_DIF','CIERRE'
  )),
  fecha_evento timestamptz NOT NULL DEFAULT now(),
  fecha_proxima_cita timestamptz,
  clues_actor text,
  clues_destino_derivacion text,
  nota_minima text CHECK(nota_minima IS NULL OR length(nota_minima)<=2000),
  actor_id uuid NOT NULL REFERENCES auth.users(id),
  origen_institucional text NOT NULL,
  registrado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS nfm_eventos_ref_idx ON nf_private.nfm_eventos_referencia(referencia_id,registrado_en DESC);

-- DIF recibe aviso de existencia, NO una copia de cédula clínica.
CREATE TABLE IF NOT EXISTS nf_private.nfm_avisos_dif (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referencia_id uuid NOT NULL UNIQUE REFERENCES nf_private.referencias(id),
  distrito_id smallint NOT NULL CHECK (distrito_id BETWEEN 1 AND 6),
  emitido_en timestamptz NOT NULL DEFAULT now(),
  estado text NOT NULL DEFAULT 'AVISO' CHECK(estado IN ('AVISO','VALORACION','EN_SEGUIMIENTO','CERRADO'))
);
CREATE INDEX IF NOT EXISTS nfm_avisos_dif_distrito_idx ON nf_private.nfm_avisos_dif(distrito_id,emitido_en DESC);

-- Visita de hogar DIF; composición exacta declarada o verificada EN CAMPO,
-- no derivada del dato agregado del Censo INEGI.
CREATE TABLE IF NOT EXISTS nf_private.nfm_evaluaciones_sociales (
  referencia_id uuid PRIMARY KEY REFERENCES nf_private.referencias(id),
  menores_domicilio smallint CHECK (menores_domicilio BETWEEN 0 AND 40),
  adultos_mayores_domicilio smallint CHECK (adultos_mayores_domicilio BETWEEN 0 AND 40),
  otros_adultos_domicilio smallint CHECK (otros_adultos_domicilio BETWEEN 0 AND 40),
  sosten_principal text CHECK (sosten_principal IN ('MADRE','PADRE','OTRO_FAMILIAR','APOYO_EXTERNO','NO_IDENTIFICADO')),
  etapa text NOT NULL DEFAULT 'PENDIENTE' CHECK (etapa IN ('PENDIENTE','CONTACTADA','VISITA_PROGRAMADA','VALORADA','APOYO_EN_GESTION','CERRADA')),
  fecha_visita date,
  capturado_por uuid NOT NULL REFERENCES auth.users(id),
  registrado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now()
);

-- Cierre seguro por defecto. Ninguna tabla de este módulo es API pública.
ALTER TABLE nf_private.nfm_unidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_asignaciones_institucionales ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_domicilios ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_autorizaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_eventos_referencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_avisos_dif ENABLE ROW LEVEL SECURITY;
ALTER TABLE nf_private.nfm_evaluaciones_sociales ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE
  nf_private.nfm_unidades, nf_private.nfm_asignaciones_institucionales,
  nf_private.nfm_domicilios, nf_private.nfm_autorizaciones,
  nf_private.nfm_eventos_referencia, nf_private.nfm_avisos_dif,
  nf_private.nfm_evaluaciones_sociales FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SEQUENCE nf_private.nfm_eventos_referencia_id_seq FROM PUBLIC, anon, authenticated;
COMMIT;

-- PENDIENTE EN FASE 2 (NO ES PARTE DEL SCRIPT):
-- 1. RPC autenticadas con VALIDACIÓN DE ROL, unidad, distrito, alcance y evento previo.
-- 2. Funciones de lectura con proyección de columnas por rol (NO SELECT general).
-- 3. pruebas de denegación cruzada, revocación, autenticación y auditoría.
-- 4. integración con catálogo CLUES de Sonora + red institucional y agenda verificada.
-- 5. conexión a proveedor de direcciones bajo contrato de privacidad y aviso aplicable.
