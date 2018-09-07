-- PARAMS: money1 - money2. Uses money1.currency!
CREATE OR REPLACE FUNCTION core.subtract_money(core.currency_amount, core.currency_amount)
	RETURNS core.currency_amount AS $$
BEGIN
	IF $1.currency = $2.currency THEN
		RETURN ($1.currency, ($1.amount - $2.amount));
	ELSE
		RETURN ($1.currency, ($1.amount - (core.money_to($2, $1.currency)).amount));
	END IF;
END;
$$ LANGUAGE plpgsql;
