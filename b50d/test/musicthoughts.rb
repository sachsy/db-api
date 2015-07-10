SCHEMA = File.read('../../musicthoughts/schema.sql')
FIXTURES = File.read('../../musicthoughts/fixtures.sql')
P_SCHEMA = File.read('../../peeps/schema.sql')
P_FIXTURES = File.read('../../peeps/fixtures.sql')
require '../../test_tools.rb'

require '../lib/b50d/musicthoughts.rb'

class TestMusicThoughts < Minitest::Test

	def setup
		super
		@mt = B50D::MusicThoughts.new('test')
		@authornames = ['Maya Angelou', 'Miles Davis', '老崔']
		@nu = {author_name: 'Oscar', contributor_name: 'Kid', contributor_email: 'kid@kid.net', lang: 'fr', thought: 'Ça va'}
	end

	def test_languages
		assert_equal ['ar', 'de', 'en', 'es', 'fr', 'it', 'ja', 'pt', 'ru', 'zh'], @mt.languages.sort
	end

	def test_categories
		cc = @mt.categories('en')
		assert_instance_of Array, cc
		assert_equal 12, cc.size
		c = cc.pop
		assert c[:id] > 0
		assert c[:category].length > 2
	end

	def test_category
		c = @mt.category('en', 2)
		assert_equal 'writing lyrics', c[:category]
		c = @mt.category('fr', 2)
		assert_equal 'écrire des paroles', c[:category]
		assert_equal [4,5], c[:thoughts].map {|t| t[:id]}.sort
	end

	def test_authors
		aa = @mt.authors
		assert_equal @authornames, aa.map {|a| a[:name]}.sort
	end

	def test_authors_top
		aa = @mt.authors_top
		assert_equal @authornames, aa.map {|a| a[:name]}.sort
		a = aa.pop
		assert a[:howmany] > 0
	end

	def test_author
		a = @mt.author('zh', 1)
		assert_equal 'Miles Davis', a[:name]
		assert_equal [1,4], a[:thoughts].map {|x| x[:id]}.sort
		a = @mt.author('es', 3)
		assert_equal 1, a[:thoughts].count
	end

	def test_author_bad
		refute @mt.author('en', 9876)
	end

	def test_contributors
		cc = @mt.contributors
		assert_equal ['Derek Sivers', 'Veruca Salt'], cc.map {|c| c[:name]}.sort
	end

	def test_contributors_top
		cc = @mt.contributors_top
		assert_equal ['Derek Sivers', 'Veruca Salt'], cc.map {|c| c[:name]}.sort
		c = cc.pop
		assert c[:howmany] > 0
	end

	def test_contributor
		c = @mt.contributor('es', 1)
		assert_equal 'Derek Sivers', c[:name]
		assert_equal [1,3,4], c[:thoughts].map {|x| x[:id]}.sort
		c = @mt.contributor('ru', 3)
		assert_equal 'Veruca Salt', c[:name]
		assert_equal 5, c[:thoughts][0][:id]
	end

	def test_contributor_bad
		refute @mt.contributor('en', 9876)
	end

	def test_all_thoughts
		tt = @mt.thoughts_all('en')
		assert_equal [1, 3, 4, 5], tt.map {|t| t[:id]}.sort
		t1 = tt.find {|x| x[:id] == 1}
		assert_equal "Play what you don't know.", t1[:thought]
	end

	def test_new_thoughts
		tt = @mt.thoughts_new('de')
		assert_equal [5, 4, 3, 1], tt.map {|t| t[:id]}
	end

	def test_random_thought
		t = @mt.thought_random('de')
		assert [1, 4].include? t[:id]
		t = @mt.thought_random('ru')
		assert [1, 4].include? t[:id]
	end

	def test_one_thought
		t = @mt.thought('ru', 1)
		assert_equal 'http://www.milesdavis.com/', t[:source_url]
		assert_equal [4, 6, 7], t[:categories].map {|c| c[:id]}.sort
	end

	def test_bad_thought
		refute @mt.thought('es', 98765)
		refute @mt.thought('fr', '')
		refute @mt.thought('de', '"')
	end

	def test_search
		r = @mt.search('en', 'experiment')
		assert_nil r[:contributors]
		assert_nil r[:authors]
		assert_nil r[:thoughts]
		assert_equal 1, r[:categories].size
		assert_equal 4, r[:categories].pop[:id]
		r = @mt.search('fr', 'miles')
		assert_nil r[:contributors]
		assert_nil r[:categories]
		assert_nil r[:thoughts]
		assert_equal 1, r[:authors].size
		assert_equal 'Miles Davis', r[:authors].pop[:name]
		r = @mt.search('zh', 'veruca')
		assert_nil r[:authors]
		assert_nil r[:categories]
		assert_nil r[:thoughts]
		assert_equal 1, r[:contributors].size
		assert_equal 'Veruca Salt', r[:contributors].pop[:name]
		r = @mt.search('en', 'you')
		assert_nil r[:authors]
		assert_nil r[:categories]
		assert_nil r[:contributors]
		assert_equal 2, r[:thoughts].size
		assert_equal [1, 5], r[:thoughts].map {|x| x[:id]}.sort
	end

	def test_lang_category
		c = @mt.category('ru', 1)
		assert_equal 'сочинение музыки', c[:category]
		c = @mt.category('ar', 1)
		assert_equal 'التأليف الموسيقي', c[:category]
	end

	def test_lang_thought
		t = @mt.thought('ja', 1)
		assert_equal '知らないものを弾け。', t[:thought]
		t = @mt.thought('ar', 5)
		assert_equal 'الناس سينسون ما قلته وما فعلته لكنهم لن ينسوا أبداً الشعور الذي جعلتهم يشعرون به.', t[:thought]
	end

	def test_lang_thought_categories
		t = @mt.thought('zh', 3)
		assert_equal '演出中', t[:categories].pop[:category]
	end

	def test_lang_authors
		a = @mt.author('pt', 1)
		assert_equal 'Miles Davis', a[:name]
		tt = a[:thoughts]
		assert_equal 2, tt.size
		pt1 = 'Toca aquilo que não sabes.'
		pt2 = 'Não temas os erros. Eles não existem.'
		assert [pt1, pt2].include? tt.pop[:thought]
		assert [pt1, pt2].include? tt.pop[:thought]
	end

	# for now, searches all languages, no matter which one is shown
	def test_lang_search
		r = @mt.search('en', 'know')
		assert_equal "Play what you don't know.", r[:thoughts][0][:thought]
		r = @mt.search('en', 'lyrics') 
		assert_equal 'writing lyrics', r[:categories][0][:category]
	end

	def test_add
		assert @mt.add('fr', @nu)
	end

	# TODO: test add errors better

end

