CREATE SCHEMA IF NOT EXISTS pgwatch3 AUTHORIZATION pgwatch3;
SET ROLE TO pgwatch3;

CREATE TABLE IF NOT EXISTS pgwatch3.metric (
    m_id serial PRIMARY KEY,
    m_name text NOT NULL,
    m_pg_version_from int NOT NULL,
    m_sql text NOT NULL,
    m_comment text,
    m_is_active boolean NOT NULL DEFAULT 't',
    m_is_helper boolean NOT NULL DEFAULT 'f',
    m_last_modified_on timestamptz NOT NULL DEFAULT now(),
    m_master_only bool NOT NULL DEFAULT FALSE,
    m_standby_only bool NOT NULL DEFAULT FALSE,
    m_column_attrs jsonb, -- currently only useful for Prometheus
    m_sql_su text DEFAULT '',
    UNIQUE (m_name, m_pg_version_from, m_standby_only),
    CHECK (NOT (m_master_only AND m_standby_only)),
    CHECK (m_name ~ E'^[a-z0-9_\\.]+$')
);

CREATE OR REPLACE FUNCTION pgwatch3.update_preset()
	RETURNS TRIGGER
	AS $$
BEGIN
	IF TG_OP = 'DELETE' THEN
		UPDATE pgwatch3.preset 
		SET metrics = metrics - OLD.name::text 
		WHERE metrics ? OLD.name::text;
	ELSIF TG_OP = 'UPDATE' THEN
		IF OLD.name <> NEW.name THEN
			UPDATE pgwatch3.preset
			SET pc_config = jsonb_set(metrics - OLD.name::text, ARRAY[NEW.name::text], metrics -> OLD.name)
			WHERE metrics ? OLD.name::text;
		END IF;
	END IF;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_preset_trigger
	AFTER DELETE OR UPDATE OF name ON pgwatch3.metric
	FOR EACH ROW
	EXECUTE FUNCTION pgwatch3.update_preset();


CREATE TABLE IF NOT EXISTS pgwatch3.source(
	name text NOT NULL PRIMARY KEY,
	connstr text NOT NULL,
	is_superuser boolean NOT NULL DEFAULT FALSE,
	preset_config text REFERENCES pgwatch3.preset(name) DEFAULT 'basic',
	config jsonb,
	is_enabled boolean NOT NULL DEFAULT 't',
	last_modified_on timestamptz NOT NULL DEFAULT now(),
	dbtype text NOT NULL DEFAULT 'postgres',
	include_pattern text, -- valid regex expected. relevant for 'postgres-continuous-discovery'
	exclude_pattern text, -- valid regex expected. relevant for 'postgres-continuous-discovery'
	custom_tags jsonb,
	"group" text NOT NULL DEFAULT 'default',
	host_config jsonb,
	only_if_master bool NOT NULL DEFAULT FALSE,
	preset_config_standby text REFERENCES pgwatch3.preset (name),
	config_standby jsonb,
	CONSTRAINT preset_or_custom_config CHECK (COALESCE(preset_config, config::text) IS NOT NULL AND (preset_config IS NULL OR config IS NULL)),
	CONSTRAINT preset_or_custom_config_standby CHECK (preset_config_standby IS NULL OR config_standby IS NULL),
	CHECK (dbtype IN ('postgres', 'pgbouncer', 'postgres-continuous-discovery', 'patroni', 'patroni-continuous-discovery', 'patroni-namespace-discovery', 'pgpool')),
	CHECK ("group" ~ E'\\w+')
);
