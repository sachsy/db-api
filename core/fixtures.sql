SET client_encoding = 'UTF8';
SET search_path = core, pg_catalog;

--
-- Data for Name: currencies; Type: TABLE DATA; Schema: core; Owner: d50b
--

ALTER TABLE currencies DISABLE TRIGGER ALL;

INSERT INTO currencies (code, name) VALUES ('AUD', 'Australian Dollar');
INSERT INTO currencies (code, name) VALUES ('BGN', 'Bulgarian Lev');
INSERT INTO currencies (code, name) VALUES ('BRL', 'Brazilian Real');
INSERT INTO currencies (code, name) VALUES ('BTC', 'Bitcoin');
INSERT INTO currencies (code, name) VALUES ('CAD', 'Canadian Dollar');
INSERT INTO currencies (code, name) VALUES ('CHF', 'Swiss Franc');
INSERT INTO currencies (code, name) VALUES ('CNY', 'China Yuan Renminbi');
INSERT INTO currencies (code, name) VALUES ('CZK', 'Czech Koruna');
INSERT INTO currencies (code, name) VALUES ('DKK', 'Danish Krone');
INSERT INTO currencies (code, name) VALUES ('EUR', 'Euro');
INSERT INTO currencies (code, name) VALUES ('GBP', 'Pound Sterling');
INSERT INTO currencies (code, name) VALUES ('HKD', 'Hong Kong Dollar');
INSERT INTO currencies (code, name) VALUES ('HRK', 'Croatian Kuna');
INSERT INTO currencies (code, name) VALUES ('HUF', 'Hungary Forint');
INSERT INTO currencies (code, name) VALUES ('IDR', 'Indonesia Rupiah');
INSERT INTO currencies (code, name) VALUES ('ILS', 'Israeli Sheqel');
INSERT INTO currencies (code, name) VALUES ('INR', 'Indian Rupee');
INSERT INTO currencies (code, name) VALUES ('JPY', 'Japan Yen');
INSERT INTO currencies (code, name) VALUES ('KRW', 'Korea Won');
INSERT INTO currencies (code, name) VALUES ('LTL', 'Lithuanian Litas');
INSERT INTO currencies (code, name) VALUES ('MXN', 'Mexican Peso');
INSERT INTO currencies (code, name) VALUES ('MYR', 'Malaysian Ringgit');
INSERT INTO currencies (code, name) VALUES ('NOK', 'Norwegian Krone');
INSERT INTO currencies (code, name) VALUES ('NZD', 'New Zealand Dollar');
INSERT INTO currencies (code, name) VALUES ('PHP', 'Philippine Peso');
INSERT INTO currencies (code, name) VALUES ('PLN', 'Polish Zloty');
INSERT INTO currencies (code, name) VALUES ('RON', 'New Romanian Leu');
INSERT INTO currencies (code, name) VALUES ('RUB', 'Russian Ruble');
INSERT INTO currencies (code, name) VALUES ('SEK', 'Swedish Krona');
INSERT INTO currencies (code, name) VALUES ('SGD', 'Singapore Dollar');
INSERT INTO currencies (code, name) VALUES ('THB', 'Thai Baht');
INSERT INTO currencies (code, name) VALUES ('TRY', 'Turkish Lira');
INSERT INTO currencies (code, name) VALUES ('USD', 'US Dollar');
INSERT INTO currencies (code, name) VALUES ('ZAR', 'South African Rand');


ALTER TABLE currencies ENABLE TRIGGER ALL;

--
-- Data for Name: currency_rates; Type: TABLE DATA; Schema: core; Owner: d50b
--

ALTER TABLE currency_rates DISABLE TRIGGER ALL;

INSERT INTO currency_rates (code, day, rate) VALUES ('AUD', '2015-09-13', 1.41017);
INSERT INTO currency_rates (code, day, rate) VALUES ('BGN', '2015-09-13', 1.724862);
INSERT INTO currency_rates (code, day, rate) VALUES ('BRL', '2015-09-13', 3.872716);
INSERT INTO currency_rates (code, day, rate) VALUES ('BTC', '2015-09-13', 0.0042510609);
INSERT INTO currency_rates (code, day, rate) VALUES ('CAD', '2015-09-13', 1.326437);
INSERT INTO currency_rates (code, day, rate) VALUES ('CHF', '2015-09-13', 0.969076);
INSERT INTO currency_rates (code, day, rate) VALUES ('CNY', '2015-09-13', 6.37508);
INSERT INTO currency_rates (code, day, rate) VALUES ('CZK', '2015-09-13', 23.91434);
INSERT INTO currency_rates (code, day, rate) VALUES ('DKK', '2015-09-13', 6.579911);
INSERT INTO currency_rates (code, day, rate) VALUES ('EUR', '2015-09-13', 0.882016);
INSERT INTO currency_rates (code, day, rate) VALUES ('GBP', '2015-09-13', 0.648278);
INSERT INTO currency_rates (code, day, rate) VALUES ('HKD', '2015-09-13', 7.750787);
INSERT INTO currency_rates (code, day, rate) VALUES ('HRK', '2015-09-13', 6.659929);
INSERT INTO currency_rates (code, day, rate) VALUES ('HUF', '2015-09-13', 276.391);
INSERT INTO currency_rates (code, day, rate) VALUES ('IDR', '2015-09-13', 14282.75);
INSERT INTO currency_rates (code, day, rate) VALUES ('ILS', '2015-09-13', 3.864147);
INSERT INTO currency_rates (code, day, rate) VALUES ('INR', '2015-09-13', 66.339049);
INSERT INTO currency_rates (code, day, rate) VALUES ('JPY', '2015-09-13', 120.5828);
INSERT INTO currency_rates (code, day, rate) VALUES ('KRW', '2015-09-13', 1183.271649);
INSERT INTO currency_rates (code, day, rate) VALUES ('LTL', '2015-09-13', 3.024144);
INSERT INTO currency_rates (code, day, rate) VALUES ('MXN', '2015-09-13', 16.83589);
INSERT INTO currency_rates (code, day, rate) VALUES ('MYR', '2015-09-13', 4.306162);
INSERT INTO currency_rates (code, day, rate) VALUES ('NOK', '2015-09-13', 8.15405);
INSERT INTO currency_rates (code, day, rate) VALUES ('NZD', '2015-09-13', 1.582998);
INSERT INTO currency_rates (code, day, rate) VALUES ('PHP', '2015-09-13', 46.82617);
INSERT INTO currency_rates (code, day, rate) VALUES ('PLN', '2015-09-13', 3.711043);
INSERT INTO currency_rates (code, day, rate) VALUES ('RON', '2015-09-13', 3.896958);
INSERT INTO currency_rates (code, day, rate) VALUES ('RUB', '2015-09-13', 67.818659);
INSERT INTO currency_rates (code, day, rate) VALUES ('SEK', '2015-09-13', 8.237221);
INSERT INTO currency_rates (code, day, rate) VALUES ('SGD', '2015-09-13', 1.412002);
INSERT INTO currency_rates (code, day, rate) VALUES ('THB', '2015-09-13', 36.02786);
INSERT INTO currency_rates (code, day, rate) VALUES ('TRY', '2015-09-13', 3.04605);
INSERT INTO currency_rates (code, day, rate) VALUES ('USD', '2015-09-13', 1);
INSERT INTO currency_rates (code, day, rate) VALUES ('ZAR', '2015-09-13', 13.54672);
INSERT INTO currency_rates (code, day, rate) VALUES ('AUD', '2015-09-14', 1.411198);
INSERT INTO currency_rates (code, day, rate) VALUES ('BGN', '2015-09-14', 1.723632);
INSERT INTO currency_rates (code, day, rate) VALUES ('BRL', '2015-09-14', 3.872126);
INSERT INTO currency_rates (code, day, rate) VALUES ('BTC', '2015-09-14', 0.0043640185);
INSERT INTO currency_rates (code, day, rate) VALUES ('CAD', '2015-09-14', 1.325562);
INSERT INTO currency_rates (code, day, rate) VALUES ('CHF', '2015-09-14', 0.968597);
INSERT INTO currency_rates (code, day, rate) VALUES ('CNY', '2015-09-14', 6.37494);
INSERT INTO currency_rates (code, day, rate) VALUES ('CZK', '2015-09-14', 23.89345);
INSERT INTO currency_rates (code, day, rate) VALUES ('DKK', '2015-09-14', 6.574201);
INSERT INTO currency_rates (code, day, rate) VALUES ('EUR', '2015-09-14', 0.881057);
INSERT INTO currency_rates (code, day, rate) VALUES ('GBP', '2015-09-14', 0.647524);
INSERT INTO currency_rates (code, day, rate) VALUES ('HKD', '2015-09-14', 7.750173);
INSERT INTO currency_rates (code, day, rate) VALUES ('HRK', '2015-09-14', 6.655889);
INSERT INTO currency_rates (code, day, rate) VALUES ('HUF', '2015-09-14', 276.152);
INSERT INTO currency_rates (code, day, rate) VALUES ('IDR', '2015-09-14', 14304.583333);
INSERT INTO currency_rates (code, day, rate) VALUES ('ILS', '2015-09-14', 3.866847);
INSERT INTO currency_rates (code, day, rate) VALUES ('INR', '2015-09-14', 66.341039);
INSERT INTO currency_rates (code, day, rate) VALUES ('JPY', '2015-09-14', 120.560899);
INSERT INTO currency_rates (code, day, rate) VALUES ('KRW', '2015-09-14', 1183.206667);
INSERT INTO currency_rates (code, day, rate) VALUES ('LTL', '2015-09-14', 3.023184);
INSERT INTO currency_rates (code, day, rate) VALUES ('MXN', '2015-09-14', 16.83392);
INSERT INTO currency_rates (code, day, rate) VALUES ('MYR', '2015-09-14', 4.305022);
INSERT INTO currency_rates (code, day, rate) VALUES ('NOK', '2015-09-14', 8.14338);
INSERT INTO currency_rates (code, day, rate) VALUES ('NZD', '2015-09-14', 1.582201);
INSERT INTO currency_rates (code, day, rate) VALUES ('PHP', '2015-09-14', 46.77787);
INSERT INTO currency_rates (code, day, rate) VALUES ('PLN', '2015-09-14', 3.709163);
INSERT INTO currency_rates (code, day, rate) VALUES ('RON', '2015-09-14', 3.895618);
INSERT INTO currency_rates (code, day, rate) VALUES ('RUB', '2015-09-14', 67.800239);
INSERT INTO currency_rates (code, day, rate) VALUES ('SEK', '2015-09-14', 8.231851);
INSERT INTO currency_rates (code, day, rate) VALUES ('SGD', '2015-09-14', 1.412496);
INSERT INTO currency_rates (code, day, rate) VALUES ('THB', '2015-09-14', 36.03304);
INSERT INTO currency_rates (code, day, rate) VALUES ('TRY', '2015-09-14', 3.04726);
INSERT INTO currency_rates (code, day, rate) VALUES ('USD', '2015-09-14', 1);
INSERT INTO currency_rates (code, day, rate) VALUES ('ZAR', '2015-09-14', 13.56145);


ALTER TABLE currency_rates ENABLE TRIGGER ALL;
