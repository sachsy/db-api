--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = peeps, pg_catalog;

--
-- Data for Name: countries; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE countries DISABLE TRIGGER ALL;

INSERT INTO countries (code, name) VALUES ('AD', 'Andorra');
INSERT INTO countries (code, name) VALUES ('AE', 'United Arab Emirates');
INSERT INTO countries (code, name) VALUES ('AF', 'Afghanistan');
INSERT INTO countries (code, name) VALUES ('AG', 'Antigua and Barbuda');
INSERT INTO countries (code, name) VALUES ('AI', 'Anguilla');
INSERT INTO countries (code, name) VALUES ('AL', 'Albania');
INSERT INTO countries (code, name) VALUES ('AM', 'Armenia');
INSERT INTO countries (code, name) VALUES ('AN', 'Netherlands Antilles');
INSERT INTO countries (code, name) VALUES ('AO', 'Angola');
INSERT INTO countries (code, name) VALUES ('AR', 'Argentina');
INSERT INTO countries (code, name) VALUES ('AS', 'American Samoa');
INSERT INTO countries (code, name) VALUES ('AT', 'Austria');
INSERT INTO countries (code, name) VALUES ('AU', 'Australia');
INSERT INTO countries (code, name) VALUES ('AW', 'Aruba');
INSERT INTO countries (code, name) VALUES ('AX', 'Åland Islands');
INSERT INTO countries (code, name) VALUES ('AZ', 'Azerbaijan');
INSERT INTO countries (code, name) VALUES ('BA', 'Bosnia and Herzegovina');
INSERT INTO countries (code, name) VALUES ('BB', 'Barbados');
INSERT INTO countries (code, name) VALUES ('BD', 'Bangladesh');
INSERT INTO countries (code, name) VALUES ('BE', 'Belgium');
INSERT INTO countries (code, name) VALUES ('BF', 'Burkina Faso');
INSERT INTO countries (code, name) VALUES ('BG', 'Bulgaria');
INSERT INTO countries (code, name) VALUES ('BH', 'Bahrain');
INSERT INTO countries (code, name) VALUES ('BI', 'Burundi');
INSERT INTO countries (code, name) VALUES ('BJ', 'Benin');
INSERT INTO countries (code, name) VALUES ('BL', 'Saint Barthélemy');
INSERT INTO countries (code, name) VALUES ('BM', 'Bermuda');
INSERT INTO countries (code, name) VALUES ('BN', 'Brunei Darussalam');
INSERT INTO countries (code, name) VALUES ('BO', 'Bolivia');
INSERT INTO countries (code, name) VALUES ('BR', 'Brazil');
INSERT INTO countries (code, name) VALUES ('BS', 'Bahamas');
INSERT INTO countries (code, name) VALUES ('BT', 'Bhutan');
INSERT INTO countries (code, name) VALUES ('BW', 'Botswana');
INSERT INTO countries (code, name) VALUES ('BY', 'Belarus');
INSERT INTO countries (code, name) VALUES ('BZ', 'Belize');
INSERT INTO countries (code, name) VALUES ('CA', 'Canada');
INSERT INTO countries (code, name) VALUES ('CC', 'Cocos Islands');
INSERT INTO countries (code, name) VALUES ('CD', 'Congo, Democratic Republic');
INSERT INTO countries (code, name) VALUES ('CF', 'Central African Republic');
INSERT INTO countries (code, name) VALUES ('CG', 'Congo');
INSERT INTO countries (code, name) VALUES ('CH', 'Switzerland');
INSERT INTO countries (code, name) VALUES ('CI', 'Côte d’Ivoire');
INSERT INTO countries (code, name) VALUES ('CK', 'Cook Islands');
INSERT INTO countries (code, name) VALUES ('CL', 'Chile');
INSERT INTO countries (code, name) VALUES ('CM', 'Cameroon');
INSERT INTO countries (code, name) VALUES ('CN', 'China');
INSERT INTO countries (code, name) VALUES ('CO', 'Colombia');
INSERT INTO countries (code, name) VALUES ('CR', 'Costa Rica');
INSERT INTO countries (code, name) VALUES ('CU', 'Cuba');
INSERT INTO countries (code, name) VALUES ('CV', 'Cape Verde');
INSERT INTO countries (code, name) VALUES ('CW', 'Curaçao');
INSERT INTO countries (code, name) VALUES ('CX', 'Christmas Island');
INSERT INTO countries (code, name) VALUES ('CY', 'Cyprus');
INSERT INTO countries (code, name) VALUES ('CZ', 'Czech Republic');
INSERT INTO countries (code, name) VALUES ('DE', 'Germany');
INSERT INTO countries (code, name) VALUES ('DJ', 'Djibouti');
INSERT INTO countries (code, name) VALUES ('DK', 'Denmark');
INSERT INTO countries (code, name) VALUES ('DM', 'Dominica');
INSERT INTO countries (code, name) VALUES ('DO', 'Dominican Republic');
INSERT INTO countries (code, name) VALUES ('DZ', 'Algeria');
INSERT INTO countries (code, name) VALUES ('EC', 'Ecuador');
INSERT INTO countries (code, name) VALUES ('EE', 'Estonia');
INSERT INTO countries (code, name) VALUES ('EG', 'Egypt');
INSERT INTO countries (code, name) VALUES ('EH', 'Western Sahara');
INSERT INTO countries (code, name) VALUES ('ER', 'Eritrea');
INSERT INTO countries (code, name) VALUES ('ES', 'Spain');
INSERT INTO countries (code, name) VALUES ('ET', 'Ethiopia');
INSERT INTO countries (code, name) VALUES ('FI', 'Finland');
INSERT INTO countries (code, name) VALUES ('FJ', 'Fiji');
INSERT INTO countries (code, name) VALUES ('FK', 'Falkland Islands');
INSERT INTO countries (code, name) VALUES ('FM', 'Micronesia');
INSERT INTO countries (code, name) VALUES ('FO', 'Faroe Islands');
INSERT INTO countries (code, name) VALUES ('FR', 'France');
INSERT INTO countries (code, name) VALUES ('GA', 'Gabon');
INSERT INTO countries (code, name) VALUES ('GB', 'United Kingdom');
INSERT INTO countries (code, name) VALUES ('GD', 'Grenada');
INSERT INTO countries (code, name) VALUES ('GE', 'Georgia');
INSERT INTO countries (code, name) VALUES ('GF', 'French Guiana');
INSERT INTO countries (code, name) VALUES ('GG', 'Guernsey');
INSERT INTO countries (code, name) VALUES ('GH', 'Ghana');
INSERT INTO countries (code, name) VALUES ('GI', 'Gibraltar');
INSERT INTO countries (code, name) VALUES ('GL', 'Greenland');
INSERT INTO countries (code, name) VALUES ('GM', 'Gambia');
INSERT INTO countries (code, name) VALUES ('GN', 'Guinea');
INSERT INTO countries (code, name) VALUES ('GP', 'Guadeloupe');
INSERT INTO countries (code, name) VALUES ('GQ', 'Equatorial Guinea');
INSERT INTO countries (code, name) VALUES ('GR', 'Greece');
INSERT INTO countries (code, name) VALUES ('GT', 'Guatemala');
INSERT INTO countries (code, name) VALUES ('GU', 'Guam');
INSERT INTO countries (code, name) VALUES ('GW', 'Guinea-Bissau');
INSERT INTO countries (code, name) VALUES ('GY', 'Guyana');
INSERT INTO countries (code, name) VALUES ('HK', 'Hong Kong');
INSERT INTO countries (code, name) VALUES ('HN', 'Honduras');
INSERT INTO countries (code, name) VALUES ('HR', 'Croatia');
INSERT INTO countries (code, name) VALUES ('HT', 'Haiti');
INSERT INTO countries (code, name) VALUES ('HU', 'Hungary');
INSERT INTO countries (code, name) VALUES ('ID', 'Indonesia');
INSERT INTO countries (code, name) VALUES ('IE', 'Ireland');
INSERT INTO countries (code, name) VALUES ('IL', 'Israel');
INSERT INTO countries (code, name) VALUES ('IM', 'Isle of Man');
INSERT INTO countries (code, name) VALUES ('IN', 'India');
INSERT INTO countries (code, name) VALUES ('IO', 'British Indian Ocean');
INSERT INTO countries (code, name) VALUES ('IQ', 'Iraq');
INSERT INTO countries (code, name) VALUES ('IR', 'Iran');
INSERT INTO countries (code, name) VALUES ('IS', 'Iceland');
INSERT INTO countries (code, name) VALUES ('IT', 'Italy');
INSERT INTO countries (code, name) VALUES ('JE', 'Jersey');
INSERT INTO countries (code, name) VALUES ('JM', 'Jamaica');
INSERT INTO countries (code, name) VALUES ('JO', 'Jordan');
INSERT INTO countries (code, name) VALUES ('JP', 'Japan');
INSERT INTO countries (code, name) VALUES ('KE', 'Kenya');
INSERT INTO countries (code, name) VALUES ('KG', 'Kyrgyzstan');
INSERT INTO countries (code, name) VALUES ('KH', 'Cambodia');
INSERT INTO countries (code, name) VALUES ('KI', 'Kiribati');
INSERT INTO countries (code, name) VALUES ('KM', 'Comoros');
INSERT INTO countries (code, name) VALUES ('KN', 'Saint Kitts and Nevis');
INSERT INTO countries (code, name) VALUES ('KP', 'Korea, North');
INSERT INTO countries (code, name) VALUES ('KR', 'Korea, South');
INSERT INTO countries (code, name) VALUES ('KW', 'Kuwait');
INSERT INTO countries (code, name) VALUES ('KY', 'Cayman Islands');
INSERT INTO countries (code, name) VALUES ('KZ', 'Kazakhstan');
INSERT INTO countries (code, name) VALUES ('LA', 'Laos');
INSERT INTO countries (code, name) VALUES ('LB', 'Lebanon');
INSERT INTO countries (code, name) VALUES ('LC', 'Saint Lucia');
INSERT INTO countries (code, name) VALUES ('LI', 'Liechtenstein');
INSERT INTO countries (code, name) VALUES ('LK', 'Sri Lanka');
INSERT INTO countries (code, name) VALUES ('LR', 'Liberia');
INSERT INTO countries (code, name) VALUES ('LS', 'Lesotho');
INSERT INTO countries (code, name) VALUES ('LT', 'Lithuania');
INSERT INTO countries (code, name) VALUES ('LU', 'Luxembourg');
INSERT INTO countries (code, name) VALUES ('LV', 'Latvia');
INSERT INTO countries (code, name) VALUES ('LY', 'Libyan Arab Jamahiriya');
INSERT INTO countries (code, name) VALUES ('MA', 'Morocco');
INSERT INTO countries (code, name) VALUES ('MC', 'Monaco');
INSERT INTO countries (code, name) VALUES ('MD', 'Moldova, Republic of');
INSERT INTO countries (code, name) VALUES ('ME', 'Montenegro');
INSERT INTO countries (code, name) VALUES ('MF', 'Saint Martin (French)');
INSERT INTO countries (code, name) VALUES ('MG', 'Madagascar');
INSERT INTO countries (code, name) VALUES ('MH', 'Marshall Islands');
INSERT INTO countries (code, name) VALUES ('MK', 'Macedonia');
INSERT INTO countries (code, name) VALUES ('ML', 'Mali');
INSERT INTO countries (code, name) VALUES ('MM', 'Myanmar');
INSERT INTO countries (code, name) VALUES ('MN', 'Mongolia');
INSERT INTO countries (code, name) VALUES ('MO', 'Macao');
INSERT INTO countries (code, name) VALUES ('MP', 'Northern Mariana Islands');
INSERT INTO countries (code, name) VALUES ('MQ', 'Martinique');
INSERT INTO countries (code, name) VALUES ('MR', 'Mauritania');
INSERT INTO countries (code, name) VALUES ('MS', 'Montserrat');
INSERT INTO countries (code, name) VALUES ('MT', 'Malta');
INSERT INTO countries (code, name) VALUES ('MU', 'Mauritius');
INSERT INTO countries (code, name) VALUES ('MV', 'Maldives');
INSERT INTO countries (code, name) VALUES ('MW', 'Malawi');
INSERT INTO countries (code, name) VALUES ('MX', 'Mexico');
INSERT INTO countries (code, name) VALUES ('MY', 'Malaysia');
INSERT INTO countries (code, name) VALUES ('MZ', 'Mozambique');
INSERT INTO countries (code, name) VALUES ('NA', 'Namibia');
INSERT INTO countries (code, name) VALUES ('NC', 'New Caledonia');
INSERT INTO countries (code, name) VALUES ('NE', 'Niger');
INSERT INTO countries (code, name) VALUES ('NF', 'Norfolk Island');
INSERT INTO countries (code, name) VALUES ('NG', 'Nigeria');
INSERT INTO countries (code, name) VALUES ('NI', 'Nicaragua');
INSERT INTO countries (code, name) VALUES ('NL', 'Netherlands');
INSERT INTO countries (code, name) VALUES ('NO', 'Norway');
INSERT INTO countries (code, name) VALUES ('NP', 'Nepal');
INSERT INTO countries (code, name) VALUES ('NR', 'Nauru');
INSERT INTO countries (code, name) VALUES ('NU', 'Niue');
INSERT INTO countries (code, name) VALUES ('NZ', 'New Zealand');
INSERT INTO countries (code, name) VALUES ('OM', 'Oman');
INSERT INTO countries (code, name) VALUES ('PA', 'Panama');
INSERT INTO countries (code, name) VALUES ('PE', 'Peru');
INSERT INTO countries (code, name) VALUES ('PF', 'French Polynesia');
INSERT INTO countries (code, name) VALUES ('PG', 'Papua New Guinea');
INSERT INTO countries (code, name) VALUES ('PH', 'Philippines');
INSERT INTO countries (code, name) VALUES ('PK', 'Pakistan');
INSERT INTO countries (code, name) VALUES ('PL', 'Poland');
INSERT INTO countries (code, name) VALUES ('PM', 'Saint Pierre and Miquelon');
INSERT INTO countries (code, name) VALUES ('PN', 'Pitcairn');
INSERT INTO countries (code, name) VALUES ('PR', 'Puerto Rico');
INSERT INTO countries (code, name) VALUES ('PS', 'Palestinian Territory');
INSERT INTO countries (code, name) VALUES ('PT', 'Portugal');
INSERT INTO countries (code, name) VALUES ('PW', 'Palau');
INSERT INTO countries (code, name) VALUES ('PY', 'Paraguay');
INSERT INTO countries (code, name) VALUES ('QA', 'Qatar');
INSERT INTO countries (code, name) VALUES ('RE', 'Réunion');
INSERT INTO countries (code, name) VALUES ('RO', 'Romania');
INSERT INTO countries (code, name) VALUES ('RS', 'Serbia');
INSERT INTO countries (code, name) VALUES ('RU', 'Russian Federation');
INSERT INTO countries (code, name) VALUES ('RW', 'Rwanda');
INSERT INTO countries (code, name) VALUES ('SA', 'Saudi Arabia');
INSERT INTO countries (code, name) VALUES ('SB', 'Solomon Islands');
INSERT INTO countries (code, name) VALUES ('SC', 'Seychelles');
INSERT INTO countries (code, name) VALUES ('SD', 'Sudan');
INSERT INTO countries (code, name) VALUES ('SE', 'Sweden');
INSERT INTO countries (code, name) VALUES ('SG', 'Singapore');
INSERT INTO countries (code, name) VALUES ('SH', 'Saint Helena');
INSERT INTO countries (code, name) VALUES ('SI', 'Slovenia');
INSERT INTO countries (code, name) VALUES ('SJ', 'Svalbard and Jan Mayen');
INSERT INTO countries (code, name) VALUES ('SK', 'Slovakia');
INSERT INTO countries (code, name) VALUES ('SL', 'Sierra Leone');
INSERT INTO countries (code, name) VALUES ('SM', 'San Marino');
INSERT INTO countries (code, name) VALUES ('SN', 'Senegal');
INSERT INTO countries (code, name) VALUES ('SO', 'Somalia');
INSERT INTO countries (code, name) VALUES ('SR', 'Suriname');
INSERT INTO countries (code, name) VALUES ('SS', 'South Sudan');
INSERT INTO countries (code, name) VALUES ('ST', 'Sao Tome and Principe');
INSERT INTO countries (code, name) VALUES ('SV', 'El Salvador');
INSERT INTO countries (code, name) VALUES ('SX', 'Sint Maarten (Dutch)');
INSERT INTO countries (code, name) VALUES ('SY', 'Syrian Arab Republic');
INSERT INTO countries (code, name) VALUES ('SZ', 'Swaziland');
INSERT INTO countries (code, name) VALUES ('TC', 'Turks and Caicos Islands');
INSERT INTO countries (code, name) VALUES ('TD', 'Chad');
INSERT INTO countries (code, name) VALUES ('TG', 'Togo');
INSERT INTO countries (code, name) VALUES ('TH', 'Thailand');
INSERT INTO countries (code, name) VALUES ('TJ', 'Tajikistan');
INSERT INTO countries (code, name) VALUES ('TK', 'Tokelau');
INSERT INTO countries (code, name) VALUES ('TL', 'Timor-Leste');
INSERT INTO countries (code, name) VALUES ('TM', 'Turkmenistan');
INSERT INTO countries (code, name) VALUES ('TN', 'Tunisia');
INSERT INTO countries (code, name) VALUES ('TO', 'Tonga');
INSERT INTO countries (code, name) VALUES ('TR', 'Turkey');
INSERT INTO countries (code, name) VALUES ('TT', 'Trinidad and Tobago');
INSERT INTO countries (code, name) VALUES ('TV', 'Tuvalu');
INSERT INTO countries (code, name) VALUES ('TW', 'Taiwan');
INSERT INTO countries (code, name) VALUES ('TZ', 'Tanzania');
INSERT INTO countries (code, name) VALUES ('UA', 'Ukraine');
INSERT INTO countries (code, name) VALUES ('UG', 'Uganda');
INSERT INTO countries (code, name) VALUES ('US', 'United States');
INSERT INTO countries (code, name) VALUES ('UY', 'Uruguay');
INSERT INTO countries (code, name) VALUES ('UZ', 'Uzbekistan');
INSERT INTO countries (code, name) VALUES ('VC', 'Saint Vincent & Grenadines');
INSERT INTO countries (code, name) VALUES ('VE', 'Venezuela');
INSERT INTO countries (code, name) VALUES ('VG', 'Virgin Islands, British');
INSERT INTO countries (code, name) VALUES ('VI', 'Virgin Islands, U.S.');
INSERT INTO countries (code, name) VALUES ('VN', 'Vietnam');
INSERT INTO countries (code, name) VALUES ('VU', 'Vanuatu');
INSERT INTO countries (code, name) VALUES ('WF', 'Wallis and Futuna');
INSERT INTO countries (code, name) VALUES ('WS', 'Samoa');
INSERT INTO countries (code, name) VALUES ('YE', 'Yemen');
INSERT INTO countries (code, name) VALUES ('YT', 'Mayotte');
INSERT INTO countries (code, name) VALUES ('ZA', 'South Africa');
INSERT INTO countries (code, name) VALUES ('ZM', 'Zambia');
INSERT INTO countries (code, name) VALUES ('ZW', 'Zimbabwe');


ALTER TABLE countries ENABLE TRIGGER ALL;

--
-- Data for Name: people; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE people DISABLE TRIGGER ALL;

INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (1, 'derek@sivers.org', 'Derek Sivers', 'Derek', '$2a$08$0yI7Vpn3UNEf5q.muDgLL.y5GJRM5ak2awUOnd9z9ZCBFoCz0/Rfy', 'yTAy', 'Dyh15IHs', '50POP LLC', 'Singapore', NULL, '018980', 'SG', '+65 9763 3568', 'This is me.', 0, 'all', 'derek', '1994-11-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (2, 'willy@wonka.com', 'Willy Wonka', 'Mr. Wonka', '$2a$08$3UjNlK6PbXMXC7Rh.EVIFeRcvmij/b8bSfNZ.MwwmD8QtQ0sy2zje', 'R5Gf', 'NvaGAkHK', 'Wonka Chocolate Inc', 'Hershey', 'PA', '12354', 'US', '+1 215 555 1034', NULL, 2, 'some', NULL, '2000-01-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (3, 'veruca@salt.com', 'Veruca Salt', 'Veruca', '$2a$08$GcHJDheKQR7zu8qTr1anz.WpLoVPbZG6dA/9zaUkowcypCczUYozy', '8gcr', 'FJKApvpY', 'Daddy Empires Ltd', 'London', 'England', 'NW1ER1', 'GB', '+44 9273 7231', NULL, 4, NULL, NULL, '2010-01-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (4, 'charlie@bucket.org', 'Charlie Buckets', 'Charlie', '$2a$08$Nf7VymjLuGGUhMl9lGTPAO0GrNq0bE5yTVMyimlFR2f7SmTMNxN46', 'AgA2', 'fdkeWoID', NULL, 'Hershey', 'PA', '12354', 'US', NULL, NULL, 0, 'all', NULL, '2010-09-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (5, 'oompa@loompa.mm', 'Oompa Loompa', 'Oompa Loompa', '$2a$08$vr40BeQAbNFkKaes4WPPw.lCQKPsyzAsNPRVQ2bPgVVatyvtwSKSO', 'LYtp', 'a5JDIleE', NULL, 'Hershey', 'PA', '12354', 'US', NULL, NULL, 0, NULL, NULL, '2010-10-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (6, 'augustus@gloop.de', 'Augustus Gloop', 'Master Gloop', '$2a$08$JmphXF9YeW7Fi2IQVUnZtenBU2Ftacz454V1B1Ort4/VZhFgpMzWO', 'AKyv', '8LLRaMwm', NULL, 'Munich', NULL, 'E01515', 'DE', NULL, NULL, 0, 'some', NULL, '2010-11-01');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (7, 'gong@li.cn', '巩俐', '巩俐', '$2a$08$x/C0JU7r7Obp2Ar/1G0kz.t.mrW/r0Nan0sDggw3wjjBdr6jvcpge', 'FBvY', 'xPAJKaRm', 'Gong Li', 'Shanghai', NULL, '987654', 'CN', NULL, NULL, 2, NULL, 'translator', '2010-12-12');
INSERT INTO people (id, email, name, address, hashpass, lopass, newpass, company, city, state, postalcode, country, phone, notes, email_count, listype, categorize_as, created_at) VALUES (8, 'yoko@ono.com', 'Yoko Ono', 'Ono-San', '$2a$08$3yMZNGqUsUH3bQaCE7Rmbeay6FHW/Us2axycwUMDsvGKSDGlVfZPS', 'uUyS', 'ysIFMj3L', 'yoko@lennon.com', 'Tokyo', NULL, '22534', 'JP', NULL, NULL, 0, NULL, 'translator', '2010-12-12');


ALTER TABLE people ENABLE TRIGGER ALL;

--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE api_keys DISABLE TRIGGER ALL;

INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (1, 'aaaaaaaa', 'bbbbbbbb', '{Peep,SiversComments,MuckworkManager}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (2, 'cccccccc', 'dddddddd', '{MuckworkClient}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (3, 'eeeeeeee', 'ffffffff', '{MuckworkClient}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (4, 'gggggggg', 'hhhhhhhh', '{Peep,Muckworker}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (5, 'iiiiiiii', 'jjjjjjjj', '{Muckworker}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (6, 'kkkkkkkk', 'llllllll', '{SiversComments,Peep}');
INSERT INTO api_keys (person_id, akey, apass, apis) VALUES (7, 'mmmmmmmm', 'nnnnnnnn', '{Peep,Muckworker}');


ALTER TABLE api_keys ENABLE TRIGGER ALL;

--
-- Data for Name: emailers; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE emailers DISABLE TRIGGER ALL;

INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (1, 1, true, '{ALL}', '{ALL}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (2, 4, false, '{ALL}', '{ALL}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (3, 6, false, '{derek@sivers}', '{translator,not-derek}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (4, 7, true, '{we@woodegg}', '{ALL}');


ALTER TABLE emailers ENABLE TRIGGER ALL;

--
-- Data for Name: emails; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE emails DISABLE TRIGGER ALL;

INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (1, 2, 'derek@sivers', 'derek@sivers', '2013-07-18 15:55:03', 1, '2013-07-20 03:42:19', 1, '2013-07-20 03:44:01', 1, NULL, 3, 'willy@wonka.com', 'Will Wonka', 'you coming by?', 'To: Derek Sivers <derek@sivers.org>
From: Will Wonka <willya@wonka.com>
Message-ID: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>
Subject: you coming by?
Date: Wed, 17 Jul 2013 23:42:59 -0400', 'Dude -

Seriously. You coming by sometime soon?

- Will', '8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (2, 7, 'derek@sivers', 'translator', '2013-07-18 15:55:03', 3, '2013-07-20 03:45:19', 3, '2013-07-20 03:47:01', 3, NULL, 4, 'gong@li.cn', 'Gong Li', 'translations almost done', 'To: Derek Sivers <derek@sivers.org>
From: Gong Li <gong@li.cn>
Message-ID: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>
Subject: translations almost done
Date: Thu, 18 Jul 2013 10:42:59 -0400', 'Hello Mr. Sivers -

Busy raising these red lanterns, but I''m almost done with the translations.

巩俐', 'CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (3, 2, 'derek@sivers', 'derek@sivers', '2013-07-20 03:47:01', 1, '2013-07-20 03:47:01', 1, '2013-07-20 03:47:01', 1, 1, NULL, 'willy@wonka.com', 'Will Wonka', 're: you coming by?', 'References: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>
In-Reply-To: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>', 'Hi Will -

Yep. On my way ASAP.

--
Derek Sivers  derek@sivers.org  http://sivers.org

> Dude -
> Seriously. You coming by sometime soon?
> - Will', '20130719234701.2@sivers.org', true, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (4, 7, 'derek@sivers', 'translator', '2013-07-20 03:47:01', 3, '2013-07-20 03:47:01', 3, '2013-07-20 03:47:01', 3, 2, NULL, 'gong@li.cn', 'Gong Li', 're: translations almost done', 'References: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>
In-Reply-To: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>', 'Hi Gong -

Thank you for the update.

--
Derek Sivers  derek@sivers.org  http://sivers.org/

> Hello Mr. Sivers -
> Busy raising these red lanterns, but I''m almost done with the translations.
> 巩俐', '20130719235701.7@sivers.org', NULL, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (5, NULL, 'derek@sivers', 'fix-client', '2013-07-20 15:42:03', 2, NULL, NULL, NULL, NULL, NULL, NULL, 'new@stranger.com', 'New Stranger', 'random question', 'To: Derek Sivers <derek@sivers.org>
From: New Stranger <new@stranger.com>
Message-ID: <COL401-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl>
Subject: random question
Date: Fri, 20 Jul 2013 11:42:59 -0400', 'Derek -

I have a question

- Stranger', 'COL401-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (6, 3, 'we@woodegg', 'woodegg', '2014-05-20 15:55:03', 4, '2014-05-21 03:42:19', 4, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I want that Wood Egg book now', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7A@mail.gmail.com>
Subject: I want it now
Date: Tue, 20 May 2014 11:42:59 -0400', 'Hi Wood Egg -

Now!

- v', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7A@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (7, 3, 'we@woodegg', 'not-derek', '2014-05-29 15:55:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I said now!!!', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7B@mail.gmail.com>
Subject: I said now!!!
Date: Thurs, 29 May 2014 11:42:59 -0400', 'I said now!!! I changed my email from veruca@salt.com to veruca@salt.net. My new sites are salt.net and https://something.travel/salt  You already have www.salt.com', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7B@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (8, 3, 'we@woodegg', 'woodegg', '2014-05-29 15:56:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I refuse to wait', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7C@mail.gmail.com>
Subject: I refuse to wait
Date: Thurs, 29 May 2014 11:44:59 -0400', 'I refuse to wait', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7C@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (9, 3, 'derek@sivers', 'derek', '2014-05-29 15:57:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'getting personal', 'To: Derek Sivers <derek@sivers.org>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7D@mail.gmail.com>
Subject: getting personal
Date: Thurs, 29 May 2014 11:45:59 -0400', 'Wood Egg is not replying to my last three emails!', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7D@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (10, NULL, 'derek@sivers', 'fix-client', '2013-07-20 15:42:03', 2, NULL, NULL, NULL, NULL, NULL, NULL, 'oompaloompa@outlook.com', 'Oompa Loompa', 'remember me?', 'To: Derek Sivers <derek@sivers.org>
From: Oompa Loompa <oompaloompa@outlook.com>
Message-ID: <ABC123-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl>
Subject: remember me?
Date: Fri, 20 Jul 2013 11:42:59 -0400', 'Derek -

Remember me?

- Ooompa, from my new email address.', 'ABC123-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl', false, NULL);


ALTER TABLE emails ENABLE TRIGGER ALL;

--
-- Data for Name: email_attachments; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE email_attachments DISABLE TRIGGER ALL;

INSERT INTO email_attachments (id, email_id, mime_type, filename, bytes) VALUES (1, 9, 'image/jpeg', '20140529-abcd-angry.jpg', 54321);
INSERT INTO email_attachments (id, email_id, mime_type, filename, bytes) VALUES (2, 9, 'image/jpeg', '20140529-efgh-mad.jpg', 65432);


ALTER TABLE email_attachments ENABLE TRIGGER ALL;

--
-- Name: email_attachments_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('email_attachments_id_seq', 2, true);


--
-- Name: emailers_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('emailers_id_seq', 4, true);


--
-- Name: emails_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('emails_id_seq', 10, true);


--
-- Data for Name: formletters; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE formletters DISABLE TRIGGER ALL;

INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (1, 'one', 'use for one', 'Your email is {email}. Here is your URL: https://sivers.org/u/{id}/{newpass}', '2014-12-22');
INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (2, 'two', 'can not do fields outside of person object', 'Hi {address}. Thank you for buying something on somedate.', '2014-12-22');
INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (3, 'three', 'blah', 'meh', '2014-12-22');
INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (4, 'four', 'blah', 'meh', '2014-12-22');
INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (5, 'five', 'blah', 'meh', '2014-12-22');
INSERT INTO formletters (id, title, explanation, body, created_at) VALUES (6, 'six', 'blah', 'meh', '2014-12-22');


ALTER TABLE formletters ENABLE TRIGGER ALL;

--
-- Name: formletters_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('formletters_id_seq', 6, true);


--
-- Data for Name: logins; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE logins DISABLE TRIGGER ALL;

INSERT INTO logins (person_id, cookie_id, cookie_tok, cookie_exp, domain, last_login, ip) VALUES (1, '2a9c0226c871c711a5e944bec5f6df5d', '18e8b4f0a05db21eed590e96eb27be9c', 1597389543, '50pop.com', '2012-09-14', '121.232.43.34');
INSERT INTO logins (person_id, cookie_id, cookie_tok, cookie_exp, domain, last_login, ip) VALUES (1, 'c776d5b6249a9fb45eec8d2af2fd7954', '18e8b4f0a05db21eed590e96eb27be9f', 946659600, 'sivers.org', '1980-01-01', '121.232.43.34');
INSERT INTO logins (person_id, cookie_id, cookie_tok, cookie_exp, domain, last_login, ip) VALUES (1, '95fcacd3d2c6e3e006906cc4f4cdf908', '18e8b4f0a05db21eed590e96eb27be9c', 1357613544, '50pop.com', '2013-02-14', '121.232.43.34');
INSERT INTO logins (person_id, cookie_id, cookie_tok, cookie_exp, domain, last_login, ip) VALUES (1, '5bf15bb6301eb8882f2afabf0ac7c520', '9KaJNiweUPkGGkTByR2pVsCrZZee9CEM', 1406276166, 'example.org', '2013-07-25', '121.232.43.34');


ALTER TABLE logins ENABLE TRIGGER ALL;

--
-- Name: people_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('people_id_seq', 8, true);


--
-- Data for Name: stats; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE stats DISABLE TRIGGER ALL;

INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (1, 1, 'listype', 'all', '2008-01-01');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (2, 1, 'twitter', '987654321 = sivers', '2010-01-01');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (3, 2, 'listype', 'some', '2011-03-15');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (4, 2, 'musicthoughts', 'clicked', '2011-03-16');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (5, 1, 'ayw', 'a', '2013-07-25');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (6, 6, 'woodegg-mn', 'interview', '2013-09-09');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (7, 6, 'woodegg-bio', 'Augustus has done a lot of business in Mongolia, importing chocolate.', '2013-09-09');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (8, 5, 'media', 'interview', '2014-12-23');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (9, 1, 'now-liner', 'I make useful things', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (10, 1, 'now-read', 'Wisdom of No Escape', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (11, 1, 'now-thought', 'You can change how you feel', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (12, 1, 'now-title', 'Writer, programmer, entrepreneur', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (13, 1, 'now-why', 'Learning for the sake of creating for the sake of learning for the sake of creating.', '2015-11-10');


ALTER TABLE stats ENABLE TRIGGER ALL;

--
-- Name: stats_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('stats_id_seq', 13, true);


--
-- Data for Name: urls; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE urls DISABLE TRIGGER ALL;

INSERT INTO urls (id, person_id, url, main) VALUES (1, 1, 'https://twitter.com/sivers', false);
INSERT INTO urls (id, person_id, url, main) VALUES (2, 1, 'http://sivers.org/', true);
INSERT INTO urls (id, person_id, url, main) VALUES (3, 2, 'http://www.wonka.com/', true);
INSERT INTO urls (id, person_id, url, main) VALUES (4, 2, 'http://cdbaby.com/cd/wonka', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (5, 2, 'https://twitter.com/wonka', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (6, 3, 'http://salt.com/', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (7, 3, 'http://facebook.com/salt', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (8, 5, 'http://oompa.loompa', NULL);


ALTER TABLE urls ENABLE TRIGGER ALL;

--
-- Name: urls_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('urls_id_seq', 8, true);


--
-- PostgreSQL database dump complete
--

