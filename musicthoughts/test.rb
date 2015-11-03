P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class TestMusicthoughtsClient < Minitest::Test
	include JDB

	def test_languages
		qry("languages()")
		assert_equal %w(en es fr de it pt ja zh ar ru), @j
	end

	def test_categories
		qry("all_categories('fr')")
		assert_equal 12, @j.size
		assert_equal 2, @j[1][:id]
		assert_equal 2, @j[1][:howmany]
		assert_equal 'écrire des paroles', @j[1][:category]
		refute @j[1][:en]
		refute @j[1][:fr]
	end

	def test_category
		qry("category('ru', 5)")
		assert_equal 'колонка авторов', @j[:category]
		qry("category('zh', 7)")
		assert_equal [3, 1], @j[:thoughts].map {|x| x[:id]}
		assert_equal '如果音乐可以被翻译成人类的言语，那音乐就再也没有存在的必要了。', @j[:thoughts][0][:thought]
		qry("category('es', 55)")
		assert_equal({}, @j)
	end

	def test_top_authors
		qry("top_authors(2)")
		assert_equal 2, @j.size
		assert_equal 'Miles Davis', @j[0][:name]
		assert_equal 2, @j[0][:howmany]
		assert_equal 'Maya Angelou', @j[1][:name]
		assert_equal 1, @j[1][:howmany]
		qry("top_authors(NULL)")
		assert_equal 3, @j.size
	end

	def test_get_author
		qry("get_author('it', 1)")
		assert_equal 'Miles Davis', @j[:name]
		assert_instance_of Array, @j[:thoughts]
		assert_equal 'Non aver paura degli errori. Non ce ne sono.', @j[:thoughts][0][:thought]
		assert_equal 'Suona quello che non conosci.', @j[:thoughts][1][:thought]
		assert_equal({id: 1, name: 'Miles Davis'} , @j[:thoughts][1][:author])
		qry("get_author('en', 55)")
		assert_equal({}, @j)
	end

	def test_top_contributors
		qry("top_contributors(1)")
		assert_equal 1, @j.size
		assert_equal 'Derek Sivers', @j[0][:name]
		assert_equal 3, @j[0][:howmany]
		qry("top_contributors(NULL)")
		assert_equal 2, @j.size
	end

	def test_get_contributor
		qry("get_contributor('ru', 1)")
		assert_equal 'Derek Sivers', @j[:name]
		assert_instance_of Array, @j[:thoughts]
		assert_equal [4, 3, 1], @j[:thoughts].map {|x| x[:id]}
		assert_equal 'Не бойся совершать ошибки. Их не существует.', @j[:thoughts][0][:thought]
		qry("get_contributor('en', 2)")
		assert_nil @j[:thoughts]
		qry("get_contributor('en', 55)")
		assert_equal({}, @j)
	end

	def test_random_thought
		qry("random_thought('fr')")
		assert [1, 4].include? @j[:id]
		assert @j[:thought].include? ' pas'
		qry("random_thought('zh')")
		assert [1, 4].include? @j[:id]
		assert @j[:thought].include? '不'
	end

	def test_get_thought
		qry("get_thought('ja', 1)")
		assert_equal 'http://www.milesdavis.com/', @j[:source_url]
		assert_equal '知らないものを弾け。', @j[:thought]
		assert_equal 'Miles Davis', @j[:author][:name]
		assert_equal 'Derek Sivers', @j[:contributor][:name]
		assert_equal ['パフォーマンス', '実験', '練習'], @j[:categories].map {|x| x[:category]}.sort
		qry("get_thought('en', 99)")
		assert_equal({}, @j)
	end

	def test_new_thoughts
		qry("new_thoughts('zh', 1)")
		assert_instance_of Array, @j
		assert_equal 1, @j.size
		assert_equal 5, @j[0][:id]
		assert_equal '人们会忘记你所说的话，人们会忘记你做了什么事情，但人们永远不会忘记你给他们的感受。', @j[0][:thought]
		qry("new_thoughts('ar', NULL)")
		assert_equal [5, 4, 3, 1], @j.map {|x| x[:id]}
		assert_equal 'اعرف ما لا تعرفه.', @j[3][:thought]
	end

	def test_search
		qry("search('zh', '中')")
		assert_equal 'search term too short', @j[:title]
		qry("search('zh', '出中')")
		assert_equal %i(authors categories contributors thoughts), @j.keys.sort
		assert_nil @j[:authors]
		assert_nil @j[:contributors]
		assert_nil @j[:thoughts]
		assert_equal '演出中', @j[:categories][0][:category]
		qry("search('ar', 'Miles')")
		assert_nil @j[:contributors]
		assert_nil @j[:categories]
		assert_nil @j[:thoughts]
		assert_equal 'Miles Davis', @j[:authors][0][:name]
		qry("search('ru', 'Salt')")
		assert_nil @j[:authors]
		assert_nil @j[:categories]
		assert_nil @j[:thoughts]
		assert_equal 'Veruca Salt', @j[:contributors][0][:name]
		qry("search('it', 'dimenticherá')")
		assert_nil @j[:authors]
		assert_nil @j[:categories]
		assert_nil @j[:contributors]
		assert_equal 5, @j[:thoughts][0][:id]
		qry("search('zh', 'dimenticherá')")
		assert_nil @j[:thoughts]
	end

	def test_add
		qry("add_thought('de', 'wow', 'me', 'me@me.nz', 'http://me.nz/', 'NZ', 'god', 'http://god.com/', ARRAY[1, 3, 5])")
		assert_equal({thought: 7, contributor: 4, author: 5}, @j)
	end
end

