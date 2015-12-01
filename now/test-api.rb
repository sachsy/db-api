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

	def test_knowns
		qry('now.knowns()')
		assert_equal(@j, [
			{id: 1, person_id: 1, short: 'sivers.org/now'},
			{id: 2, person_id: 2, short: 'wonka.com/now'}])
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
			short: 'salt.com/now',
			long: 'http://salt.com/now/'})
	end

	def test_urls_for_person
		qry('now.urls_for_person(1)')
		assert_equal(@j, [{id: 1,
			person_id: 1,
			created_at: '2015-11-10',
			updated_at: '2015-11-10',
			short: 'sivers.org/now',
			long: 'http://sivers.org/now'}])
	end

	def test_stats_for_person
		qry('now.stats_for_person(1)')
		assert_equal(@j, [
			{id: 9, name: 'now-liner', value: 'I make useful things', created_at: '2015-11-10'},
			{id:10, name: 'now-read', value: 'Wisdom of No Escape', created_at: '2015-11-10'},
			{id:11, name: 'now-thought', value: 'You can change how you feel', created_at: '2015-11-10'},
			{id:12, name: 'now-title', value: 'Writer, programmer, entrepreneur', created_at: '2015-11-10'},
			{id:13, name: 'now-why', value: 'Learning for the sake of creating for the sake of learning for the sake of creating.', created_at: '2015-11-10'}
		])
		qry('now.stats_for_person(2)')
		assert_equal([], @j)
	end

	def test_add_url
		qry("now.add_url(1, '50.io/now')")
		assert_equal 6, @j[:id]
		assert_equal '50.io/now', @j[:short]
		assert_equal nil, @j[:long]
		assert_equal nil, @j[:updated_at]
		refute_equal nil, @j[:created_at]
		qry("now.add_url(1, '50.io/now')")
		assert @j[:title].include? 'duplicate'
	end

	def test_delete_url
		qry("now.delete_url(3)")
		assert_equal 3, @j[:id]
		assert_equal 'salt.com/now', @j[:short]
		qry("now.delete_url(3)")
		assert_equal '404', @res[0]['status']
	end

	def test_update_url
		qry('now.update_url(5, $1)', [{person_id: 7}.to_json])
		assert_equal 7, @j[:person_id]
		assert_equal nil, @j[:long]
		long = 'http://gongli.cn/now/'
		qry('now.update_url(5, $1)', [{long: long, ignore: 'this'}.to_json])
		assert_equal 7, @j[:person_id]
		assert_equal long, @j[:long]
	end
end
