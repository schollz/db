-- PARAMS: JSON of currency rates https://openexchangerates.org/documentation
CREATE OR REPLACE FUNCTION core.update_currency_rates(jsonb) RETURNS void AS $$
DECLARE
	rates jsonb;
	acurrency core.currencies;
	acode core.currency;
	arate numeric;
BEGIN
	rates := jsonb_extract_path($1, 'rates');
	FOR acurrency IN SELECT * FROM core.currencies LOOP
		acode := acurrency.code;
		arate := CAST((rates ->> CAST(acode AS text)) AS numeric);
		INSERT INTO core.currency_rates (code, rate) VALUES (acode, arate);
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;

