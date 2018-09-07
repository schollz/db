-- When a person has multiple entries in peeps.people, merge two into one, updating foreign keys.
-- USAGE: SELECT person_merge_from_to(5432, 4321);
-- Returns array of tables actually updated in schema.table format like {'muckwork.clients', 'sivers.comments'}
-- (Return value is probably unneeded, but here it is anyway, just in case.)
CREATE OR REPLACE FUNCTION peeps.person_merge_from_to(old_id integer, new_id integer) RETURNS text[] AS $$
DECLARE
	res RECORD;
	done_tables text[] := ARRAY[]::text[];
	rowcount integer;
	old_p peeps.people;
	new_p peeps.people;
	move_public_id text;
BEGIN
	-- update ids to point to new one
	FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
		EXECUTE format ('UPDATE %s SET %I=%s WHERE %I=%s',
			res.tablename, res.colname, new_id, res.colname, old_id);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount > 0 THEN
			done_tables := done_tables || res.tablename;
		END IF;
	END LOOP;
	SELECT * INTO old_p FROM peeps.people WHERE id = old_id;
	SELECT * INTO new_p FROM peeps.people WHERE id = new_id;
	-- if both have a public_id, we've got a problem
	IF LENGTH(old_p.public_id) = 4 AND LENGTH(new_p.public_id) = 4 THEN
		RAISE 'both_have_public_id';
	END IF;
	-- copy better(longer) data from old to new
	-- public_id, company, city, state, country, categorize_as
	IF COALESCE(LENGTH(old_p.public_id), 0) > COALESCE(LENGTH(new_p.public_id), 0) THEN
		move_public_id := old_p.public_id; -- because must be unique:
		UPDATE peeps.people SET public_id = NULL WHERE id = old_id;
		UPDATE peeps.people SET public_id = move_public_id WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.company), 0) > COALESCE(LENGTH(new_p.company), 0) THEN
		UPDATE peeps.people SET company = old_p.company WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.city), 0) > COALESCE(LENGTH(new_p.city), 0) THEN
		UPDATE peeps.people SET city = old_p.city WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.state), 0) > COALESCE(LENGTH(new_p.state), 0) THEN
		UPDATE peeps.people SET state = old_p.state WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.country), 0) > COALESCE(LENGTH(new_p.country), 0) THEN
		UPDATE peeps.people SET country = old_p.country WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.categorize_as), 0) > COALESCE(LENGTH(new_p.categorize_as), 0) THEN
		UPDATE peeps.people SET categorize_as = old_p.categorize_as WHERE id = new_id;
	END IF;
	IF LENGTH(old_p.notes) > 0 THEN  -- combine notes
		UPDATE peeps.people SET notes = CONCAT(old_p.notes, E'\n', notes) WHERE id = new_id;
	END IF;
	-- Done! delete old one
	DELETE FROM peeps.people WHERE id = old_id;
	RETURN done_tables;
END;
$$ LANGUAGE plpgsql;
