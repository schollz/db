--Route{
-- api = "lat.untag_concept",
-- args = {"concept_id", "tag_id"},
-- method = "DELETE",
-- url = "/concepts/([0-9]+)/tags/([0-9]+)",
-- captures = {"concept_id", "tag_id"},
--}
CREATE OR REPLACE FUNCTION lat.untag_concept(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM lat.concepts_tags
		WHERE concept_id = $1
		AND tag_id = $2;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
END;
$$ LANGUAGE plpgsql;
