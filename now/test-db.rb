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

end
