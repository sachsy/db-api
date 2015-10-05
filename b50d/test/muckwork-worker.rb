SCHEMA = File.read('../../muckwork/schema.sql')
FIXTURES = File.read('../../muckwork/fixtures.sql')
P_SCHEMA = File.read('../../peeps/schema.sql')
P_FIXTURES = File.read('../../peeps/fixtures.sql')
require '../../test_tools.rb'

require '../lib/b50d/muckwork.rb'

class TestMuckworker < Minitest::Test

	def setup
		super
		@mc1 = B50D::Muckworker.new('g' * 8, 'h' * 8, 'test')
		@mc2 = B50D::Muckworker.new('i' * 8, 'j' * 8, 'test')
	end

	def test_get_worker
		x = @mc1.get_worker
		assert_equal 'Charlie Buckets', x[:name]
		x = @mc2.get_worker
		assert_equal 'Oompa Loompa', x[:name]
	end

	def test_update
		params = {currency: 'SGD', millicents_per_second: 3232, city: 'New City', ignore: 'this'}
		x = @mc2.update(params)
		assert_equal params[:currency], x[:currency]
		assert_equal params[:millicents_per_second], x[:millicents_per_second]
		assert_equal params[:city], x[:city]
		assert_equal 'Oompa Loompa', x[:name]
	end


end
