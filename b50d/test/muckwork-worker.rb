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

	def test_set_password
		email = 'charlie@bucket.org'
		newpass = '1q2w3e4r5t'
		x = @mc1.set_password(newpass)
		assert_equal email, x[:email]
		db = DbAPI.new('test')
		x = db.js('peeps.get_person_password($1, $2)', [email, newpass])
		assert_equal email, x[:email]
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

	def test_grouped_tasks
		gt = @mc1.grouped_tasks
		assert_equal ['finished'], gt.keys
		assert_equal [3, 2, 1], gt['finished'].map {|t| t[:id]}
		gt = @mc2.grouped_tasks
		assert_equal ['started', 'finished'], gt.keys
		assert_equal [4], gt['finished'].map {|t| t[:id]}
		assert_equal [5], gt['started'].map {|t| t[:id]}
	end

	def test_next_available_tasks
		tasks = @mc1.next_available_tasks
		assert_equal [7], tasks.map {|t| t[:id]}
		assert_equal 'Unstarted project', tasks[0][:project][:title]
		db = DbAPI.new('test')
		db.js('muckwork.approve_quote(4)')
		tasks = @mc1.next_available_tasks
		assert_equal [7,12], tasks.map {|t| t[:id]}
		assert_equal 'by Veruca', tasks[1][:project][:description]
	end
end
