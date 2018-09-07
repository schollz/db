-- PARAMS: money, new_currency_code
CREATE OR REPLACE FUNCTION core.money_to(core.currency_amount, core.currency)
	RETURNS core.currency_amount AS $$
BEGIN
	IF $1.currency = 'USD' THEN
		RETURN (SELECT ($2, ($1.amount * rate)) 
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1);
	ELSIF $2 = 'USD' THEN
		RETURN (SELECT ($2, ($1.amount / rate))
			FROM core.currency_rates WHERE code = $1.currency
			ORDER BY day DESC LIMIT 1);
	ELSE
		RETURN (SELECT ($2, ((SELECT $1.amount / rate
			FROM core.currency_rates WHERE code = $1.currency
			ORDER BY day DESC LIMIT 1) * rate))
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1);
	END IF;
END;
$$ LANGUAGE plpgsql;
