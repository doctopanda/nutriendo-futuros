-- NFS · Migración 0.3: catálogo territorial CLUES y validación estricta.
-- Aplicar después de v0.1 y v0.2.
-- Por diseño, bloquea TODOS los registros nominales hasta cargar CLUES verificadas.
BEGIN;
CREATE TABLE IF NOT EXISTS nf_private.clues_autorizadas (
 clues text PRIMARY KEY,
 municipio text NOT NULL,
 distrito_id smallint NOT NULL CHECK (distrito_id BETWEEN 1 AND 6),
 institucion text,
 nivel text,
 activa boolean NOT NULL DEFAULT false,
 verificada boolean NOT NULL DEFAULT false,
 fuente text NOT NULL,
 revisado_en timestamptz,
 CHECK (length(trim(clues))>=5)
);
ALTER TABLE nf_private.clues_autorizadas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON nf_private.clues_autorizadas FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION nf_private.validar_clues_paciente()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_ok boolean;
BEGIN
 SELECT true INTO v_ok FROM nf_private.clues_autorizadas c
 WHERE upper(trim(c.clues))=upper(trim(NEW.clues))
  AND nf_private.normalizar(c.municipio)=nf_private.normalizar(NEW.municipio)
  AND c.distrito_id=NEW.distrito_id
  AND c.activa=true AND c.verificada=true
 LIMIT 1;
 IF v_ok IS DISTINCT FROM true THEN
   RAISE EXCEPTION 'CLUES, municipio o distrito sin autorización territorial verificada';
 END IF;
 RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS nf_guardia_clues ON nf_private.pacientes;
CREATE TRIGGER nf_guardia_clues
 BEFORE INSERT OR UPDATE OF clues, municipio, distrito_id
 ON nf_private.pacientes
 FOR EACH ROW EXECUTE FUNCTION nf_private.validar_clues_paciente();
REVOKE ALL ON FUNCTION nf_private.validar_clues_paciente() FROM PUBLIC,anon,authenticated;
COMMIT;
-- IMPORTACIÓN RESPONSABLE:
-- Corroborar cada CLUES del catálogo oficial vigente, municipio y distrito.
-- Cargar inicialmente verificada=false; aprobar individualmente por responsable.
-- No inferir el Distrito Sanitario a partir del nombre del municipio.
-- Un registro con CLUES no validada se rechaza, no se mueve a otro distrito.
