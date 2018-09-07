-- PARAMS: money
CREATE OR REPLACE FUNCTION core.round_money(core.currency_amount)
	RETURNS core.currency_amount AS $$
BEGIN
	RETURN ($1.currency, round($1.amount, 2));
END;
$$ LANGUAGE plpgsql;
