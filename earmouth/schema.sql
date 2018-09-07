BEGIN;
SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS earmouth CASCADE;
CREATE SCHEMA earmouth;
SET search_path = earmouth;

CREATE EXTENSION intarray; -- for unique pair indexes

CREATE TABLE earmouth.users (
	id serial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	apiuser char(8) not null UNIQUE CONSTRAINT valid_apiuser CHECK (apiuser ~ '\A[a-zA-Z0-9]{8}\Z'),
	apipass char(8) not null UNIQUE CONSTRAINT valid_apipass CHECK (apipass ~ '\A[a-zA-Z0-9]{8}\Z'),
	created_at date not null default current_date,
	deleted_at date,
	public_id char(3) not null UNIQUE CONSTRAINT valid_public_id CHECK (public_id ~ '\A[a-zA-Z0-9]{3}\Z'),
	public_name varchar(40) not null CONSTRAINT no_public_name CHECK (length(public_name) > 0),
	bio text
);

CREATE TABLE earmouth.invitations (
	id serial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	code char(6) not null UNIQUE CONSTRAINT valid_code CHECK (code ~ '\A[a-zA-Z0-9]{6}\Z'),
	created_by integer not null REFERENCES earmouth.users(id),
	created_at date not null default current_date,
	claimed_at date
);

CREATE TABLE earmouth.requests (
	id serial primary key,
	requester integer not null REFERENCES earmouth.users(id),
	requestee integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_request_self CHECK (requester != requestee),
	created_at date not null default current_date,
	approved boolean,
	closed_at date
);
CREATE UNIQUE INDEX unique_request_pair on earmouth.requests(earmouth.sort(array[requester, requestee]));

CREATE TABLE earmouth.connections (
	id serial primary key,
	user1 integer not null REFERENCES earmouth.users(id),
	user2 integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_connect_self CHECK (user1 != user2),
	created_at date not null default current_date,
	revoked_at date,
	revoked_by integer REFERENCES earmouth.users(id)
);
CREATE UNIQUE INDEX unique_connection_pair on earmouth.connections(earmouth.sort(array[user1, user2]));

CREATE TABLE earmouth.calls (
	id serial primary key,
	public_id char(4) not null UNIQUE CONSTRAINT valid_call_id CHECK (public_id ~ '\A[a-zA-Z0-9]{4}\Z'),
	caller integer not null REFERENCES earmouth.users(id),
	callee integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_call_self CHECK (caller != callee),
	started_at timestamp(0) with time zone not null DEFAULT current_timestamp,
	finished_at timestamp(0) with time zone
);



DROP VIEW IF EXISTS earmouth.user_fullview CASCADE;
CREATE VIEW earmouth.user_fullview AS
	SELECT u.id,
		u.public_id,
		u.public_name,
		CONCAT('https://earmouth.com/images/', u.public_id, '.jpg') AS image,
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
	AND u.deleted_at IS NULL;



DROP VIEW IF EXISTS earmouth.user_view CASCADE;
CREATE VIEW earmouth.user_view AS
	SELECT u.id,
		u.public_id,
		u.public_name,
		CONCAT('https://earmouth.com/images/', u.public_id, '.jpg') AS image,
		p.city,
		p.state,
		p.country,
		u.bio
	FROM earmouth.users u, peeps.people p
	WHERE u.person_id = p.id
	AND u.deleted_at IS NULL;



-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.connected_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
	SELECT user1 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NULL
		AND user2 = $1)
	UNION (
	SELECT user2 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NULL
		AND user1 = $1);
END;
$$ LANGUAGE plpgsql;



-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.blocked_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
	SELECT user1 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NOT NULL
		AND user2 = $1)
	UNION (
	SELECT user2 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NOT NULL
		AND user1 = $1)
	UNION (
	SELECT requestee AS uid
		FROM earmouth.requests
		WHERE requester = $1
		AND approved = 'f');
END;
$$ LANGUAGE plpgsql;



-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.request_in_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT requester
		FROM earmouth.requests
		WHERE requestee = $1
		AND approved IS NULL
	);
END;
$$ LANGUAGE plpgsql;



-- PARAMS: users1.id, users2.id
-- (user1 = who's asking.  user2 = who they're asking about)
CREATE OR REPLACE FUNCTION earmouth.relationship_from_to(integer, integer) RETURNS text AS $$
DECLARE
	yesno integer;
BEGIN
	IF $1 = $2 THEN RETURN 'self'; END IF;
	-- "connection-request-out"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE requester = $1
		AND requestee = $2
		AND approved IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connection-request-out'; END IF;
	-- "connection-request-in"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE requester = $2
		AND requestee = $1
		AND approved IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connection-request-in'; END IF;
	-- "blocked"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE ((requester = $1
		AND requestee = $2) OR (requester = $2
		AND requestee = $1))
		AND approved IS FALSE;
	IF yesno IS NOT NULL THEN RETURN 'blocked'; END IF;
	-- "blocked"
	SELECT id INTO yesno
		FROM earmouth.connections
		WHERE ((user1 = $1
		AND user2 = $2) OR (user1 = $2
		AND user2 = $1))
		AND revoked_at IS NOT NULL;
	IF yesno IS NOT NULL THEN RETURN 'blocked'; END IF;
	-- "connected"
	SELECT id INTO yesno
		FROM earmouth.connections
		WHERE ((user1 = $1
		AND user2 = $2) OR (user1 = $2
		AND user2 = $1))
		AND revoked_at IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connected';
	-- else "unconnected"
	ELSE
		return 'unconnected';
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.request_out_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT requestee
		FROM earmouth.requests
		WHERE requester = $1
		AND approved IS NULL
	);
END;
$$ LANGUAGE plpgsql;



-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.unconnected_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT id
		FROM earmouth.users
		WHERE id != $1
		AND id NOT IN (
			SELECT * FROM earmouth.connected_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.blocked_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.request_in_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.request_out_userids_for($1)
		)
	);
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.clean_user() RETURNS TRIGGER AS $$
BEGIN
	NEW.public_name = btrim(regexp_replace(NEW.public_name, '\s+', ' ', 'g'));
	NEW.bio = btrim(regexp_replace(NEW.bio, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_user ON earmouth.users CASCADE;
CREATE TRIGGER clean_user
	BEFORE INSERT OR UPDATE OF public_name, bio ON earmouth.users
	FOR EACH ROW EXECUTE PROCEDURE earmouth.clean_user();



CREATE OR REPLACE FUNCTION earmouth.callgen() RETURNS TRIGGER AS $$
BEGIN
	NEW.public_id = core.unique_for_table_field(4, 'earmouth.calls', 'public_id');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS callgen ON earmouth.calls CASCADE;
CREATE TRIGGER callgen
	BEFORE INSERT ON earmouth.calls
	FOR EACH ROW WHEN (NEW.public_id IS NULL)
	EXECUTE PROCEDURE earmouth.callgen();



CREATE OR REPLACE FUNCTION earmouth.invitationgen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(6, 'earmouth.invitations', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS invitationgen ON earmouth.invitations CASCADE;
CREATE TRIGGER invitationgen
	BEFORE INSERT ON earmouth.invitations
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE earmouth.invitationgen();



CREATE OR REPLACE FUNCTION earmouth.usergen() RETURNS TRIGGER AS $$
BEGIN
	NEW.apiuser = core.unique_for_table_field(8, 'earmouth.users', 'apiuser');
	NEW.apipass = core.unique_for_table_field(8, 'earmouth.users', 'apipass');
	NEW.public_id = core.unique_for_table_field(3, 'earmouth.users', 'public_id');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS usergen ON earmouth.users CASCADE;
CREATE TRIGGER usergen
	BEFORE INSERT ON earmouth.users
	FOR EACH ROW WHEN (NEW.apiuser IS NULL AND NEW.apipass IS NULL AND NEW.public_id IS NULL)
	EXECUTE PROCEDURE earmouth.usergen();



-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.get_unknown_users_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id IN (
			SELECT *
			FROM earmouth.unconnected_userids_for($1)
		)
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



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



-- Can use this to go back and accept a request previously refused
-- PARAMS: users.id of requestee, users.id of requester
CREATE OR REPLACE FUNCTION earmouth.accept_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
	connection_id integer;
BEGIN
	UPDATE earmouth.requests
	SET approved = 't', closed_at = NOW()
	WHERE requestee = $1
	AND requester = $2
	RETURNING id INTO request_id;
	IF request_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		-- already connected? quietly skip insert
		SELECT id INTO connection_id
		FROM earmouth.connections
		WHERE (earmouth.sort(array[user1, user2])) = earmouth.sort(array[$1, $2]);
		IF connection_id IS NULL THEN
			INSERT INTO earmouth.connections (user1, user2)
			VALUES ($1, $2);
		END IF;
		SELECT x.status, x.js INTO status, js FROM earmouth.get_user($2) x;
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: apiuser, apipass
CREATE OR REPLACE FUNCTION earmouth.auth_user(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id
		FROM earmouth.users
		WHERE apiuser = $1
		AND apipass = $2) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.connections_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id IN (
			SELECT *
			FROM earmouth.connected_userids_for($1))
		ORDER BY id DESC) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



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



-- PARAMS: users.id of requester, users.id of requestee
CREATE OR REPLACE FUNCTION earmouth.create_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	connection_id integer;
	request_id integer;
BEGIN
	-- already connected? refuse
	SELECT id INTO connection_id
	FROM earmouth.connections
	WHERE (earmouth.sort(array[user1, user2])) = earmouth.sort(array[$1, $2]);
	IF connection_id IS NOT NULL THEN
		RAISE 'already_connected';
	ELSE
		INSERT INTO earmouth.requests (requester, requestee)
		VALUES ($1, $2)
		RETURNING id INTO request_id;
		status := 200;
		js := json_build_object('id', request_id);
	END IF;
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



-- PARAMS: users.id of requester, users.id of reqestee
CREATE OR REPLACE FUNCTION earmouth.delete_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
BEGIN
	DELETE FROM earmouth.requests
	WHERE requester = $1
	AND requestee = $2
	AND closed_at IS NULL
	RETURNING id INTO request_id;
	IF request_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		status := 200;
		js := json_build_object('id', request_id);
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.delete_user(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
	UPDATE earmouth.users
		SET deleted_at = NOW()
		WHERE id = $1;
	DELETE FROM earmouth.connections
		WHERE user1 = $1
		OR user2 = $1;
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



CREATE OR REPLACE FUNCTION earmouth.get_user_full(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_fullview,
		earmouth.relationship_from_to(2, 1) AS relationship
		WHERE id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.get_user(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: users.id of requestee, users.id of requester
CREATE OR REPLACE FUNCTION earmouth.refuse_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
BEGIN
	UPDATE earmouth.requests
	SET approved = 'f', closed_at = NOW()
	WHERE requestee = $1
	AND requester = $2
	AND closed_at IS NULL
	RETURNING id INTO request_id;
	IF request_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		status := 200;
		js := json_build_object('id', request_id);
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.get_users(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		ORDER BY id
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.user_update_public_name(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE earmouth.users SET public_name = $2 WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
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



-- PARAMS: users.id requesting revokation, other users.id 
CREATE OR REPLACE FUNCTION earmouth.revoke_connection(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	connection_id integer;
BEGIN
	UPDATE earmouth.connections
	SET revoked_at = NOW(), revoked_by = $1
	WHERE ((user1 = $1 AND user2 = $2)
	OR (user2 = $1 AND user1 = $2))
	AND revoked_at IS NULL
	RETURNING id INTO connection_id;
	IF connection_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		status := 200;
		js := json_build_object('id', connection_id);
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.user_get_user(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id = $2
		AND id NOT IN (
			SELECT *
			FROM earmouth.blocked_userids_for($1))
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.user_get_users(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id != $1
		AND id NOT IN (
			SELECT *
			FROM earmouth.blocked_userids_for($1))
		ORDER BY id
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.user_get_user_full(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_fullview,
		earmouth.relationship_from_to($1, $2) AS relationship
		WHERE id = $2
		AND id NOT IN (
			SELECT *
			FROM earmouth.blocked_userids_for($1)
		)
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION earmouth.user_update_bio(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE earmouth.users SET bio = $2 WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
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



-- PARAMS: users.id, country code, state code or NULL, city
CREATE OR REPLACE FUNCTION earmouth.user_update_country_state_city(integer, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE peeps.people
	SET country = $2,
		state = $3,
		city = $4
	WHERE id = (
		SELECT person_id
		FROM earmouth.users
		WHERE id = $1
	);
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
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



-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.requests_in_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id IN (
			SELECT *
			FROM earmouth.request_in_userids_for($1)
		)
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.requests_out_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id IN (
			SELECT *
			FROM earmouth.request_out_userids_for($1)
		)
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.user_counts(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	connected integer;
	unconnected integer;
	request_out integer;
	request_in integer;
BEGIN
	SELECT COUNT(*) INTO connected
		FROM earmouth.connected_userids_for($1);
	SELECT COUNT(*) INTO unconnected
		FROM earmouth.unconnected_userids_for($1);
	SELECT COUNT(*) INTO request_out
		FROM earmouth.request_out_userids_for($1);
	SELECT COUNT(*) INTO request_in
		FROM earmouth.request_in_userids_for($1);
	status := 200;
	js := json_build_object(
		'connected', connected,
		'unconnected', unconnected,
		'request_out', request_out,
		'request_in', request_in
	);
END;
$$ LANGUAGE plpgsql;



COMMIT;


