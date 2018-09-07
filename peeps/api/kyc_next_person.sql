-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.kyc_next_person(integer,
	OUT status smallint, OUT js jsonb) AS $$
DECLARE
	person_id integer;
BEGIN
	-- does this emailer have a person open but not finished yet?
	SELECT id INTO person_id
		FROM peeps.people
		WHERE checked_at IS NULL
		AND checked_by = $1;
	IF NOT FOUND THEN
		-- if not, find next and immediately tag with this emailer_id
		SELECT id INTO person_id
			FROM peeps.people
			WHERE checked_at IS NULL
			AND checked_by IS NULL
			AND email IS NOT NULL
			AND email_count > 0
			ORDER BY id DESC LIMIT 1;
		UPDATE peeps.people
			SET checked_by = $1
			WHERE id = person_id;
	END IF;
	status := 200;
	js := jsonb_build_object('person_id', person_id);
END;
$$ LANGUAGE plpgsql;
