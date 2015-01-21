# test peeps schema
require 'pg'
require 'minitest/autorun'

DB = PG::Connection.new(dbname: 'd50b_test', user: 'd50b')
SCHEMA = File.read('schema.sql')
FIXTURES = File.read('fixtures.sql')

class Minitest::Test
	def setup
		DB.exec(SCHEMA)
		DB.exec(FIXTURES)
	end
end

Minitest.after_run do
	DB.exec(SCHEMA)
	DB.exec(FIXTURES)
end

class TestPeeps < Minitest::Test

	# peeps.people.country must be 2 uppercase letters existing in peeps.countries.code, or NULL
	def test_country
		DB.exec("UPDATE people SET country='BE' WHERE id=1");
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("UPDATE people SET country='XX' WHERE id=1");
		end
		assert err.message.include? 'people_country_fkey'
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("UPDATE people SET country='be' WHERE id=1");
		end
		DB.exec("UPDATE people SET country=NULL WHERE id=1");
	end

	# peeps.people.email must be vaguely valid ("string@string.string") or NULL.
	# constraint name: 'valid_email'. UPDATE and INSERT trim and lowercase email first
	def test_people_email
		res = DB.exec("UPDATE people SET email='	BEE@cee.DEE	' WHERE id=1 RETURNING email");
		assert_equal 'bee@cee.dee', res[0]['email']
		DB.exec("UPDATE people SET email=NULL WHERE id=1");
		err = assert_raises PG::CheckViolation do
			DB.exec("UPDATE people SET email='missing@tld' WHERE id=1");
		end
		assert err.message.include? 'valid_email'
		# if given empty string, converts to NULL first
		DB.exec("UPDATE people SET email='' WHERE id=1");
		res = DB.exec("SELECT email FROM people WHERE id=1");
		assert_nil res[0]['email']
	end

	# peeps.people.name can't be null or empty. UPDATE and INSERT trim first.
	def test_people_name_empty
		err = assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO people (name) VALUES ('')")
		end
		assert err.message.include? 'no_name'
		err = assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO people (name) VALUES ('\r\n	\r\n ')")
		end
		err = assert_raises PG::CheckViolation do
			DB.exec("SELECT * FROM person_create('', 'dog@dog.com')")
		end
		assert err.message.include? 'no_name'
		err = assert_raises PG::NotNullViolation do
			DB.exec("INSERT INTO people (name) VALUES (NULL)")
		end
		assert err.message.include? 'column "name"'
		err = assert_raises PG::NotNullViolation do
			DB.exec("SELECT * FROM person_create(NULL, 'dog@dog.com')")
		end
		assert err.message.include? 'column "name"'
	end

	# peeps.people.name has linebreaks removed, spaces trimmed by INSERT and UPDATE
	def test_people_name_clean
		DB.exec("UPDATE people SET name='\n\r	Spaced Out \r\n' WHERE id=2");
		res = DB.exec("SELECT name, address FROM people WHERE id=2");
		assert_equal 'Spaced Out', res[0]['name']
		# updating name does not update address
		assert_equal 'Mr. Wonka', res[0]['address']
	end

	# peeps.emailers.profiles is array of values in peeps.emails.profile that this person is allowed to access
	# peeps.emailers.categories is array of values in peeps.emails.category that this person is allowed to access
	# if either one is '{ALL}', then all approved.	empty array means none approved.
	def test_emailers
		res = DB.exec("SELECT * FROM emailers WHERE id=3")
		assert_equal '{derek@sivers}', res[0]['profiles']
		assert_equal '{translator,not-derek}', res[0]['categories']
		# here's one way of converting these into arrays. safe because '{}' chars will never be used.
		assert_equal ['derek@sivers'], res[0]['profiles'].delete('{}').split(',')
		assert_equal ['translator', 'not-derek'], res[0]['categories'].delete('{}').split(',')
	end

	# can't delete a person if they were ever an emailer with emails
	def test_emailers_restrict_delete
		err = assert_raises PG::ForeignKeyViolation do
			DB.exec("DELETE FROM people WHERE id=7")
		end
		assert err.message.include? 'emailers_person_id_fkey'
	end

	# statkey stripped of all whitespace, even internal, upon INSERT or UPDATE
	# statvalue trimmed but keeps inner whitespace
	def test_userstats_clean
		res = DB.exec("INSERT INTO userstats (person_id, statkey, statvalue) VALUES (5, ' \nd O G\r ', ' ro\n vER ') RETURNING userstats.*")
		assert_equal 'dog', res[0]['statkey']
		assert_equal "ro\n vER", res[0]['statvalue']
		res = DB.exec("UPDATE userstats SET statkey=' \nH i\r\r', statvalue='\n o H \r' WHERE id=1 RETURNING userstats.*")
		assert_equal 'hi', res[0]['statkey']
		assert_equal 'o H', res[0]['statvalue']
	end

	# deleting a person deletes their userstats
	def test_userstats_cascade_delete
		res = DB.exec("SELECT person_id FROM userstats WHERE id=8")
		assert_equal '5', res[0]['person_id']
		DB.exec("DELETE FROM people WHERE id=5")
		res = DB.exec("SELECT person_id FROM userstats WHERE id=8")
		assert_equal 0, res.ntuples
	end

	# urls.url whitespace removed, and 'http://' added if not there, on UPDATE and INSERT
	def test_urls_clean
		res = DB.exec("UPDATE urls SET url='twitter.com/wonka' WHERE id=5 RETURNING url")
		assert_equal 'http://twitter.com/wonka', res[0]['url']
		res = DB.exec("INSERT INTO urls(person_id, url) VALUES (5, '	https:// mybank.com\r\n') RETURNING url")
		assert_equal 'https://mybank.com', res[0]['url']
	end

	# deleting a person deletes their urls
	def test_urls_cascade_delete
		res = DB.exec("SELECT person_id FROM urls WHERE id=8")
		assert_equal '5', res[0]['person_id']
		DB.exec("DELETE FROM people WHERE id=5")
		res = DB.exec("SELECT person_id FROM urls WHERE id=8")
		assert_equal 0, res.ntuples
	end

	# person_create(name, email) cleans then returns one peeps.people row
	# USE THIS for adding/inserting a new person into the database.
	def test_person_create
		res = DB.exec("SELECT * FROM person_create('	Miles Davis	', ' MILES@aol.COM')")
		x = res[0]
		assert_equal '9', x['id']
		assert_equal 'Miles Davis', x['name']
		# address auto-created from first word of name
		assert_equal 'Miles', x['address']
		assert_equal 'miles@aol.com', x['email']
		assert_nil x['hashpass']
		# INSERT creates default values
		assert_equal 4, x['lopass'].size
		assert_equal 8, x['newpass'].size
		assert_equal '0', x['email_count']
		assert_equal Time.now.to_s[0,10], x['created_at']
		# if cleaned email exists in db already, returns that row
		res = DB.exec("SELECT * FROM person_create(' Miles Davis III', ' MILES@AOL.com')")
		assert_equal '9', res[0]['id']
		res = DB.exec("SELECT * FROM person_create('Name Ignored if Email Matches', 'derek@SIVERS.org')")
		assert_equal '1', res[0]['id']
		assert_equal 'Derek Sivers', res[0]['name']
		# can't create new person with NULL email, empty or invalid email
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT * FROM person_create('Valid Name', NULL)")
		end
		assert err.message.include? 'missing_email'
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT * FROM person_create('Valid Name', '	')")
		end
		assert err.message.include? 'missing_email'
		err = assert_raises PG::CheckViolation do
			DB.exec("SELECT * FROM person_create('Valid Name', 'bad@email')")
		end
		assert err.message.include? 'valid_email'
	end

	# people.email_count is a cache of howmany emails with this person_id, used for sorting search results.
	def test_update_email_count
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '4', res[0]['email_count']
		DB.exec("UPDATE emails SET person_id=3 WHERE id IN (5, 10)")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '6', res[0]['email_count']
		DB.exec("DELETE FROM emails WHERE id=9")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '5', res[0]['email_count']
		DB.exec("UPDATE emails SET person_id=NULL WHERE id IN (5, 10)")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '3', res[0]['email_count']
		DB.exec("INSERT INTO emails(person_id, profile) VALUES (3, 'derek@sivers')")
		res = DB.exec("SELECT email_count FROM people WHERE id=3")
		assert_equal '4', res[0]['email_count']
	end

	# emailer is a person with permission to access emails with certain profiles or categories
	# first param is emailer.id (logged-in user). second param is email.id
	# Returns emails.* for that email.id, or nothing if not allowed
	def test_emailer_get_email
		res = DB.exec("SELECT * FROM emailer_get_email(1, 1)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 1)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 2)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(3, 7)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(4, 7)")
		assert_equal 1, res.ntuples
		res = DB.exec("SELECT * FROM emailer_get_email(4, 2)")
		assert_equal 0, res.ntuples
	end

	# Returns unopened emails.* that this emailer is authorized to see
	def test_emailer_get_unopened
		res = DB.exec("SELECT id FROM emailer_get_unopened(1)")
		assert_equal %w(7 8 9), res.map {|x| x['id']}
		res = DB.exec("SELECT id FROM emailer_get_unopened(3)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT id FROM emailer_get_unopened(4)")
		assert_equal %w(7 8), res.map {|x| x['id']}
	end

	# Returns string to be set as cookie, then used in get_person_from_cookie
	def test_login_person_domain
		res = DB.exec("SELECT login_person_domain(5, 'muckwork.com')")
		assert_equal 65, res.getvalue(0, 0).size
		assert_match /^[a-zA-Z0-9]{32}:[a-zA-Z0-9]{32}$/, res.getvalue(0, 0)
		c_id, c_tok = res.getvalue(0,0).split(':')
		res = DB.exec("SELECT * FROM logins WHERE person_id=5")
		assert_equal 1, res.ntuples
		assert_equal c_id, res[0]['cookie_id']
		assert_equal c_tok, res[0]['cookie_tok']
		assert_equal 'muckwork.com', res[0]['domain']
	end

	# Give cookie, get people.* or nothing
	def test_get_person_from_cookie
		res = DB.exec("SELECT login_person_domain(5, 'muckwork.com')")
		cookie = res.getvalue(0, 0)
		res = DB.exec("SELECT * FROM get_person_from_cookie('%s')" % cookie)
		assert_equal 1, res.ntuples
		assert_equal 'oompa@loompa.mm', res[0]['email']
		cookie[0, 1] = 'Z'
		res = DB.exec("SELECT * FROM get_person_from_cookie('%s')" % cookie)
		assert_equal 0, res.ntuples
	end

	# Setting urls.main=true makes others for this person urls.main=false
	def test_url_main
		res = DB.exec("SELECT main FROM urls WHERE id=3")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=5")
		assert_nil res[0]['main']
		DB.exec("UPDATE urls SET main=TRUE WHERE id=5")
		res = DB.exec("SELECT main FROM urls WHERE id=5")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=3")
		assert_equal 'f', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_nil res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=7")
		assert_nil res[0]['main']
		DB.exec("UPDATE urls SET main='t' WHERE id=6")
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_equal 't', res[0]['main']
		res = DB.exec("SELECT main FROM urls WHERE id=7")
		assert_equal 'f', res[0]['main']
		DB.exec("INSERT INTO urls (person_id, url, main) VALUES (3, 'salt.biz', 't')")
		res = DB.exec("SELECT main FROM urls WHERE id=6")
		assert_equal 'f', res[0]['main']
	end

	# emails.profile and emails.category can not be null or empty
	# both cleaned to lowercase, strip all but a-z0-9_@-
	# for new emails, empty category set to match profile
	def test_emails_checks
		assert_raises PG::NotNullViolation do
			DB.exec("UPDATE emails SET profile=NULL WHERE id=1")
		end
		assert_raises PG::NotNullViolation do
			DB.exec("UPDATE emails SET category=NULL WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE emails SET profile='' WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE emails SET category='	!\r/ |\n~ & ^ ' WHERE id=1")	# <-- cleaned to ''
		end
		res = DB.exec("INSERT INTO emails (person_id, profile) VALUES (3, 'we@woodegg') RETURNING *")
		assert_equal 'we@woodegg', res[0]['category']
		res = DB.exec("INSERT INTO emails (person_id, profile, category) VALUES (3, 'derek@sivers', '  ') RETURNING *")
		assert_equal 'derek@sivers', res[0]['category']
		res = DB.exec("INSERT INTO emails (person_id, profile, category) VALUES (3, ' DEREK@sivers\r\n', ' !TH*&is-/tH_At	') RETURNING *")
		assert_equal 'derek@sivers', res[0]['profile']
		assert_equal 'this-th_at', res[0]['category']
		res = DB.exec("UPDATE emails SET profile='!D@_s-!', category='\r\n\t%T\t\r\n ' WHERE id=8 RETURNING *")
		assert_equal 'd@_s-', res[0]['profile']
		assert_equal 't', res[0]['category']
	end

	# INSERT api_keys and it'll generate the random strings.	Note query to fetch.
	def test_create_api_keys
		DB.exec("DELETE FROM api_keys")	# because filled with fixtures
		res = DB.exec("INSERT INTO api_keys (person_id, apis) VALUES (5, '{MuckworkClient}') RETURNING api_keys.*")
		akey = res[0]['akey']
		apass = res[0]['apass']
		assert_match /[a-zA-Z0-9]{8}/, akey
		assert_match /[a-zA-Z0-9]{8}/, apass
		res = DB.exec("SELECT person_id FROM api_keys WHERE akey='#{akey}' AND apass='#{apass}' AND 'MuckworkClient' = ANY(apis)")
		assert_equal '5', res.getvalue(0,0)
		res = DB.exec("SELECT person_id FROM api_keys WHERE akey='#{akey}' AND apass='#{apass}' AND 'MuckworkManager' = ANY(apis)")
		assert_equal 0, res.ntuples
		assert_raises PG::UniqueViolation do	# only one entry per person!
			DB.exec("INSERT INTO api_keys (person_id, apis) VALUES (5, '{Peep}')")
		end
	end

	# because of hashing crypting stuff, use this to set someone's password
	def test_set_password
		res = DB.exec("SELECT hashpass FROM people WHERE id=1")
		old_hashpass = res[0]['hashpass']
		assert old_hashpass.size > 20
		DB.exec_params("SELECT set_password($1, $2)", [1, 'bl00p€r'])
		res = DB.exec("SELECT hashpass FROM people WHERE id=1")
		refute_equal old_hashpass, res[0]['hashpass']
		assert res[0]['hashpass'].size > 20
		# password must be > 3 characters
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT set_password($1, $2)", [1, 'x¥z'])
		end
		assert err.message.include? 'short_password'
	end

	# needs valid email and password 4+ chars.	use exec_params
	def test_person_email_pass
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['derek@sivers.org', 'derek'])
		assert_equal 'Derek Sivers', res[0]['name']
		nu_pass = 'bl00p€r'
		DB.exec_params("SELECT set_password($1, $2)", [2, nu_pass])
		res = DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka.com', nu_pass])
		assert_equal 'Willy Wonka', res[0]['name']
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka', nu_pass])
		end
		assert err.message.include? 'bad_email'
		err = assert_raises PG::RaiseException do
			DB.exec_params("SELECT * FROM person_email_pass($1, $2)", ['willy@wonka.com', 'x1x'])
		end
		assert err.message.include?	'short_password'
	end

	# search term at least 2 chars
	def test_people_search
		res = DB.exec_params("SELECT * FROM people_search($1)", ['nk'])
		assert_equal 'Willy Wonka', res[0]['name']
		err = assert_raises PG::RaiseException do
			DB.exec("SELECT * FROM people_search('x')")
		end
		assert err.message.include? 'short_search_term'
	end

end
