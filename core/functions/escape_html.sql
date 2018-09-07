-- PARAMS: any text that needs HTML escape
CREATE OR REPLACE FUNCTION core.escape_html(text) RETURNS text AS $$
DECLARE
	nu text;
BEGIN
	nu := replace($1, '&', '&amp;');
	nu := replace(nu, '''', '&#39;');
	nu := replace(nu, '"', '&quot;');
	nu := replace(nu, '<', '&lt;');
	nu := replace(nu, '>', '&gt;');
	RETURN nu;
END;
$$ LANGUAGE plpgsql;
