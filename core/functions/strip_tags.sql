-- PARAMS: any text that needs to be stripped of HTML tags
CREATE OR REPLACE FUNCTION core.strip_tags(text) RETURNS text AS $$
BEGIN
	RETURN regexp_replace($1 , '</?[^>]+?>', '', 'g');
END;
$$ LANGUAGE plpgsql;
