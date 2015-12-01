P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class TestNowDB < Minitest::Test

	def test_ensure_public_id_existing
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=3")
		assert_equal 'ijkl', res[0]['public_id']
		DB.exec("INSERT INTO now.urls(person_id, short, long) VALUES (3, 'a.b', 'http://a.b/now')")
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=3")
		assert_equal 'ijkl', res[0]['public_id']
	end

	def test_ensure_public_id_new
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=8")
		assert_equal nil, res[0]['public_id']
		DB.exec("INSERT INTO now.urls(person_id, short, long) VALUES (8, 'a.b', 'http://a.b/now')")
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=8")
		assert_match /[a-zA-Z0-9]{4}/, res[0]['public_id']
	end

	def test_ensure_public_id_update
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=7")
		assert_equal nil, res[0]['public_id']
		DB.exec("UPDATE now.urls SET person_id=7 WHERE id=5")
		res = DB.exec("SELECT public_id FROM peeps.people WHERE id=7")
		assert_match /[a-zA-Z0-9]{4}/, res[0]['public_id']
	end

	def test_clean_short
		res = DB.exec_params("INSERT INTO now.urls(person_id, short) VALUES (5, $1) RETURNING short",
			["\t\n https://www.this.is/now/ \r"])
		assert_equal 'this.is/now', res[0]['short']
		res = DB.exec_params("UPDATE now.urls SET short=$1 WHERE id=5 RETURNING short",
			["\t\n https://www.thus.us/now/ \r"])
		assert_equal 'thus.us/now', res[0]['short']
	end

	def test_clean_long
		res = DB.exec_params("INSERT INTO now.urls(person_id, short, long) VALUES (5, $1, $2) RETURNING long",
			['this.is/now', "\t\n www.this.is/now/ \r"])
		assert_equal 'http://www.this.is/now/', res[0]['long']
		res = DB.exec_params("UPDATE now.urls SET long=$1 WHERE id=5 RETURNING long",
			["\t\n https://www.thus.us/now/ \r"])
		assert_equal 'https://www.thus.us/now/', res[0]['long']
	end
end

