-- PARAMS: money, number to multiply it by
CREATE OR REPLACE FUNCTION core.multiply_money(core.currency_amount, numeric)
	RETURNS core.currency_amount AS $$
BEGIN
	RETURN ($1.currency, ($1.amount * $2));
END;
$$ LANGUAGE plpgsql;
