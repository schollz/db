-- PARAMS: json from Twitter API as seen here:
-- https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline
CREATE OR REPLACE FUNCTION peeps.add_tweet(jsonb,
	OUT status smallint, OUT js jsonb) AS $$
DECLARE
	new_id bigint;
	new_ca timestamp(0) with time zone;
	new_handle varchar(15);
	new_pid integer;
	new_msg text;
	new_ref bigint;
	r record;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	new_id := ($1->>'id')::bigint;
	status := 200;
	js := json_build_object('id', new_id);
	-- If already exists, don't insert. just return status+js now.
	PERFORM 1 FROM peeps.tweets WHERE id = new_id;
	IF FOUND THEN RETURN; END IF;
	new_ca := $1->>'created_at';
	new_handle := $1->'user'->>'screen_name';
	new_pid := peeps.pid_for_twitter_handle(new_handle);
	new_msg := replace($1->>'text', E'\n', ' ');
	FOR r IN
		SELECT *
		FROM jsonb_array_elements($1->'entities'->'urls')
	LOOP
		new_msg := replace(new_msg, r.value->>'url', r.value->>'expanded_url');
	END LOOP;
	IF LENGTH($1->>'in_reply_to_status_id') > 0 THEN
		new_ref := ($1->>'in_reply_to_status_id')::bigint;
	END IF;
	INSERT INTO peeps.tweets (
		entire,
		id,
		created_at,
		handle,
		person_id,
		message,
		reference_id
	) VALUES (
		$1,
		new_id,
		new_ca,
		new_handle,
		new_pid,
		new_msg,
		new_ref
	);
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
