-- Use this for user choosing their own password.
-- USAGE: SELECT set_hashpass(123, 'Th€IR nü FunK¥(!) pá$$werđ');
-- Returns false if that peeps.people.id doesn't exist, otherwise true.
-- PARAMS: persons.id, password
CREATE OR REPLACE FUNCTION peeps.set_hashpass(integer, text) RETURNS boolean AS $$
BEGIN
	IF $2 IS NULL OR length(btrim($2)) < 4 THEN
		RAISE 'short_password';
	END IF;
	UPDATE peeps.people
	SET newpass = NULL,
		hashpass = peeps.crypt($2, peeps.gen_salt('bf', 8))
	WHERE id = $1;
	IF FOUND THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END;
$$ LANGUAGE plpgsql;
