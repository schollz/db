-- Returns unopened emails.* that this emailer is authorized to see
-- PARAMS: emailers.id
CREATE OR REPLACE FUNCTION peeps.emailer_get_unopened(integer) RETURNS SETOF peeps.emails AS $$
DECLARE
	qry text := 'SELECT * FROM peeps.emails WHERE opened_at IS NULL AND person_id IS NOT NULL';
	emailer peeps.emailers;
BEGIN
	SELECT * INTO emailer FROM peeps.emailers WHERE id = $1;
	IF (emailer.profiles != '{ALL}') THEN
		qry := qry || ' AND profile IN (SELECT UNNEST(profiles) FROM peeps.emailers WHERE id=' || $1 || ')';
	END IF;
	IF (emailer.categories != '{ALL}') THEN
		qry := qry || ' AND category IN (SELECT UNNEST(categories) FROM peeps.emailers WHERE id=' || $1 || ')';
	END IF;
	qry := qry || ' ORDER BY id ASC';
	RETURN QUERY EXECUTE qry;
END;
$$ LANGUAGE plpgsql;
-- Returns unopened emails.* that this emailer is authorized to see
-- PARAMS: emailers.id
CREATE OR REPLACE FUNCTION peeps.emailer_get_unopened(integer) RETURNS SETOF peeps.emails AS $$
	SELECT *
	FROM peeps.emails
	WHERE opened_at IS NULL
	AND person_id IS NOT NULL
	ORDER BY id;
END;
$$ LANGUAGE sql;
