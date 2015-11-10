P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class TestNow < Minitest::Test
	include JDB

	def test_find_person
		res = DB.exec("SELECT * FROM now.find_person(2)")
		assert_equal '2', res[0]['find_person']
		res = DB.exec("SELECT * FROM now.find_person(3)")
		assert_equal '3', res[0]['find_person']
		res = DB.exec("SELECT * FROM now.find_person(4)")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM now.find_person(99)")
		assert_equal 0, res.ntuples
	end

	def test_find_person_needs_to_match_domain
		DB.exec("INSERT INTO peeps.urls(person_id, url) VALUES (5, 'http://www.loompa.net')")
		res = DB.exec("SELECT * FROM now.find_person(4)")
		assert_equal 0, res.ntuples
		DB.exec("INSERT INTO peeps.urls(person_id, url) VALUES (5, 'http://www.oompa.net')")
		res = DB.exec("SELECT * FROM now.find_person(4)")
		assert_equal '5', res[0]['find_person']
	end

	def test_unknowns
		qry('now.unknowns()')
		assert_equal(@j, [
			{id: 3, short: 'salt.com/now', long: 'http://salt.com/now/'},
			{id: 4, short: 'oompa.net/now.html', long: 'http://oompa.net/now.html'},
			{id: 5, short: 'gongli.cn/now', long: nil}])
	end

	def test_url
		qry('now.url(2)')
		assert_equal(@j, {id: 2,
			person_id: 2,
			created_at: '2015-11-10',
			updated_at: '2015-11-10',
			tiny: 'wonka',
			short: 'wonka.com/now',
			long: 'http://www.wonka.com/now/'})
	end

	def test_unknown_find
		qry('now.unknown_find(4)')
		assert_equal([], @j)
		qry('now.unknown_find(3)')
		assert_equal([{id:3, name:'Veruca Salt', email:'veruca@salt.com', email_count:4}], @j)
	end

	def test_unknown_assign
		qry('now.unknown_assign(3, 3)')
		assert_equal(@j, {id: 3,
			person_id: 3,
			created_at: '2015-11-10',
			updated_at: '2015-11-10',
			tiny: 'salt',
			short: 'salt.com/now',
			long: 'http://salt.com/now/'})
	end
end
