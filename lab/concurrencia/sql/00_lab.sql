-- NF-SEC-012: isolated concurrency model. No production schema or data.
CREATE SCHEMA IF NOT EXISTS demo;
CREATE TABLE IF NOT EXISTS demo.contador(distrito smallint PRIMARY KEY CHECK(distrito BETWEEN 1 AND 6),ultimo bigint NOT NULL DEFAULT 0 CHECK(ultimo BETWEEN 0 AND 99999999));
INSERT INTO demo.contador(distrito) SELECT d FROM generate_series(1,6) d ON CONFLICT DO NOTHING;
CREATE TABLE IF NOT EXISTS demo.paciente(folio text PRIMARY KEY CHECK(folio ~ '^NF-DS[1-6]-[0-9]{8}$'),distrito smallint NOT NULL REFERENCES demo.contador(distrito),clave_identidad text NOT NULL UNIQUE,creado_en timestamptz NOT NULL DEFAULT now());
CREATE OR REPLACE FUNCTION demo.registrar(p_distrito smallint,p_clave text) RETURNS jsonb LANGUAGE plpgsql AS $fn$
DECLARE n bigint; f text; existente text;
BEGIN
IF p_distrito NOT BETWEEN 1 AND 6 OR p_clave IS NULL OR length(p_clave)<8 THEN RAISE EXCEPTION 'Invalid synthetic input'; END IF;
PERFORM pg_advisory_xact_lock(hashtextextended(p_clave,0));
SELECT folio INTO existente FROM demo.paciente WHERE clave_identidad=p_clave LIMIT 1;
IF existente IS NOT NULL THEN RETURN jsonb_build_object('estado','requiere_revision'); END IF;
PERFORM pg_sleep(0.35);
UPDATE demo.contador SET ultimo=ultimo+1 WHERE distrito=p_distrito AND ultimo<99999999 RETURNING ultimo INTO n;
IF n IS NULL THEN RAISE EXCEPTION 'Counter not available'; END IF;
f:='NF-DS'||p_distrito||'-'||lpad(n::text,8,'0');
INSERT INTO demo.paciente(folio,distrito,clave_identidad) VALUES(f,p_distrito,p_clave);
RETURN jsonb_build_object('estado','nuevo','folio',f);
END $fn$;