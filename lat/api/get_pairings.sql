--Route{
-- api = "lat.get_pairings",
-- method = "GET",
-- url = "/pairings",
--}
CREATE OR REPLACE FUNCTION lat.get_pairings(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT p.id
		, p.created_at
		, c1.title AS concept1
		, c2.title AS concept2
		FROM lat.pairings p
		INNER JOIN lat.concepts c1 ON p.concept1_id = c1.id
		INNER JOIN lat.concepts c2 ON p.concept2_id = c2.id
		ORDER BY p.id
	) r;
END;
$$ LANGUAGE plpgsql;
