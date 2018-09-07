-- maybe don't need
CREATE OR REPLACE FUNCTION words.yes_candidates(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM words.candidates_view
		WHERE yesno IS TRUE
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;

-- maybe don't need
CREATE OR REPLACE FUNCTION words.no_candidates(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM words.candidates_view
		WHERE yesno IS FALSE
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;

-- maybe don't need
CREATE OR REPLACE FUNCTION words.tba_candidates(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM words.candidates_view
		WHERE yesno IS NULL
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;

