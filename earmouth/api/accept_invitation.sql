CREATE OR REPLACE FUNCTION earmouth.accept_invitation(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	invitee_pid integer;
	inviter_uid integer;
	invitee_uid integer;
BEGIN
	-- in one query: update, if found, and return two IDs
	UPDATE earmouth.invitations
	SET claimed_at = NOW()
	WHERE code = $1
	AND claimed_at IS NULL
	RETURNING person_id, created_by INTO invitee_pid, inviter_uid;
	-- if invitation not found, return empty 404
	IF invitee_pid IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		-- otherwise create new earmouth user
		INSERT INTO earmouth.users (person_id, public_name)
		SELECT id, name
		FROM peeps.people
		WHERE id = invitee_pid
		RETURNING id INTO invitee_uid;
		-- create connection between two users
		INSERT INTO earmouth.connections(user1, user2)
		VALUES (inviter_uid, invitee_uid);
		-- return new user info WITH API KEYS (just this once)
		status := 200;
		js := row_to_json(r) FROM (
			SELECT u.id,
				CONCAT(u.apiuser, ':', u.apipass) AS apikey,
				u.public_id,
				u.public_name,
				p.city,
				p.state,
				p.country,
				u.bio, (
				SELECT json_agg(x) AS urls
				FROM (
					SELECT id,
						url,
						main
					FROM peeps.urls
					WHERE person_id = u.person_id
					ORDER BY main DESC NULLS LAST, id
				) x)
			FROM earmouth.users u, peeps.people p
			WHERE u.person_id = p.id
			AND u.id = invitee_uid
		) r;
	END IF;  -- invitee_pid IS (not) NULL 
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

