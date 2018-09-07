-- Return the email signature, from core.configs, for this key
-- Really just a little convenience function, used only once
CREATE OR REPLACE FUNCTION peeps.email_sig(text, OUT sig text) AS $$
BEGIN
	SELECT v INTO sig FROM core.configs WHERE k = ($1 || '.signature');
	IF NOT FOUND THEN
		RAISE 'email signature not found';
	END IF;
END;
$$ LANGUAGE plpgsql;
