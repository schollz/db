-- PARAMS: hostname (tr.sivers.org or data.sivers.org), email address
CREATE OR REPLACE FUNCTION peeps.custom_reset_email(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	eid integer;
	body text;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($2);
	IF pid IS NULL THEN status := 404;
	js := '{}'; ELSE
		PERFORM peeps.make_newpass(pid);
		SELECT REPLACE(REPLACE(REPLACE(f.body,
			'{host}', $1),
			'{id}', p.id::text),
			'{newpass}', p.newpass) INTO body
		FROM peeps.formletters f, peeps.people p
		WHERE f.id = 4 -- NOTE: hard-coded formletters.id!!!
		AND p.id = pid;
		SELECT outgoing_email INTO eid
		FROM peeps.outgoing_email(2, pid, 'sivers', 'sivers',
			'your password reset link', body, NULL);
		status := 200;
		js := json_build_object('id', eid);
	END IF;
END;
$$ LANGUAGE plpgsql;
