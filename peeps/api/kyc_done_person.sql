-- PARAMS: person_id
-- TODO: if I want to get strict: error checking, auth checking emailer_id matches, and that it's not done already
CREATE OR REPLACE FUNCTION peeps.kyc_done_person(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.people SET checked_at=NOW() WHERE id = $1;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;
