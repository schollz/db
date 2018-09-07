-- person_id=0 to create new
--Route{
--  api = "peeps.set_unknown_person",
--  args = {"emailer_id", "email_id", "person_id"},
--  method = "PUT",
--  url = "/unknowns/([0-9]+)/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id", "person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.set_unknown_person(integer, integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	this_e peeps.emails;
	newperson peeps.people;
	rowcount integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT * INTO this_e
	FROM peeps.emails
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
	) AND id = $2;
	GET DIAGNOSTICS rowcount = ROW_COUNT;
	IF rowcount = 0 THEN status := 404;
	js := '{}'; RETURN; END IF;
	IF $3 = 0 THEN
		SELECT * INTO newperson
		FROM peeps.person_create(this_e.their_name, this_e.their_email);
	ELSE
		SELECT * INTO newperson
		FROM peeps.people
		WHERE id = $3;
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount = 0 THEN status := 404;
	js := '{}'; RETURN; END IF;
		UPDATE peeps.people
		SET email = this_e.their_email,
		notes = concat('OLD EMAIL: ', email, E'\n', notes)
		WHERE id = $3;
	END IF;
	UPDATE peeps.emails
	SET person_id = newperson.id, category = profile
	WHERE id = $2;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
END;
$$ LANGUAGE plpgsql;
