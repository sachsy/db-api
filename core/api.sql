------------------------------------------------
-------------------------------------- JSON API:
------------------------------------------------ 


-- GET /currencies
-- PARAMS: -none-
-- RETURNS array of objects:
-- [{"code":"AUD","name":"Australian Dollar"},{"code":"BGN","name":"Bulgarian Lev"}... ]
CREATE OR REPLACE FUNCTION core.all_currencies(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM core.currencies ORDER BY code) r;
END;
$$ LANGUAGE plpgsql;


-- GET /currency_names
-- PARAMS: -none-
-- RETURNS single code:name object:
-- {"AUD":"Australian Dollar", "BGN":"Bulgarian Lev", ...}
CREATE OR REPLACE FUNCTION core.currency_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_object(
		ARRAY(SELECT code FROM core.currencies ORDER BY code),
		ARRAY(SELECT name FROM core.currencies ORDER BY code));
END;
$$ LANGUAGE plpgsql;


