-- PARAMS: user.id, recipient name, email
CREATE OR REPLACE FUNCTION earmouth.create_invitation(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	to_person integer;
	from_name text;
	from_email text;
	invite_code text;
	subject text;
	body text;
	email_id integer;
BEGIN
	-- find or create person in peeps.people (or error-out here)
	SELECT id INTO to_person FROM peeps.person_create($2, $3);
	-- get inviter's name & email
	SELECT p.name, p.email
	INTO from_name, from_email
	FROM peeps.people p, earmouth.users u
	WHERE u.person_id = p.id
	AND u.id = $1;
	-- don't invite same person twice
	SELECT code INTO invite_code
	FROM earmouth.invitations
	WHERE person_id = to_person;
	IF invite_code IS NULL THEN
		-- create invitation and retrieve generated code
		INSERT INTO earmouth.invitations (person_id, created_by)
		VALUES (to_person, $1)
		RETURNING code INTO invite_code;
	END IF;
	-- TODO: translation of earmouth_welcome
	subject := 'EarMouth invitation from ' || from_name || ' (' || from_email || ')';
	body := from_name || ' invited you to EarMouth. Your code is: ' || invite_code;
	-- create email message  TODO: earmouth profile, not sivers
	SELECT * INTO email_id
	FROM peeps.outgoing_email(2, to_person, 'sivers', 'earmouth', subject, body, NULL);
	status := 200;
	js := json_build_object('id', email_id);
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

