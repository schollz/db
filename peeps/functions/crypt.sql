-- pgcrypto for people.hashpass
CREATE OR REPLACE FUNCTION peeps.crypt(text, text) RETURNS text AS '$libdir/pgcrypto', 'pg_crypt' LANGUAGE c IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION peeps.gen_salt(text, integer) RETURNS text AS '$libdir/pgcrypto', 'pg_gen_salt_rounds' LANGUAGE c STRICT;
