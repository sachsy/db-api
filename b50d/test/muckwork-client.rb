SCHEMA = File.read('../../muckwork/schema.sql')
FIXTURES = File.read('../../muckwork/fixtures.sql')
P_SCHEMA = File.read('../../peeps/schema.sql')
P_FIXTURES = File.read('../../peeps/fixtures.sql')
require '../../test_tools.rb'

require '../lib/b50d/muckwork.rb'

class TestMuckworkClient < Minitest::Test

	def setup
		super
		@mc1 = B50D::MuckworkClient.new('c' * 8, 'd' * 8, 'test')
		@mc2 = B50D::MuckworkClient.new('e' * 8, 'f' * 8, 'test')
	end

	def test_set_password
		email = 'willy@wonka.com'
		newpass = '1q2w3e4r5t'
		x = @mc1.set_password(newpass)
		assert_equal email, x[:email]
		db = DbAPI.new('test')
		x = db.js('peeps.get_person_password($1, $2)', [email, newpass])
		assert_equal email, x[:email]
	end

	def test_get_client
		x = @mc1.get_client
		assert_equal 'Willy Wonka', x[:name]
		x = @mc2.get_client
		assert_equal 'Veruca Salt', x[:name]
	end

	def test_update
		params = {currency: 'SGD', city: 'New City', ignore: 'this'}
		@mc2.update(params)
		x = @mc2.get_client
		assert_equal params[:currency], x[:currency]
		assert_equal params[:city], x[:city]
	end

	def test_get_projects
		x = @mc1.get_projects
		assert_equal [5, 3, 1], x.map {|p| p[:id]}
	end

	def test_get_project
		x = @mc1.get_project(1)
		assert_equal 'Finished project', x[:title]
		refute @mc1.get_project(2)
		assert @mc2.get_project(2)
		assert @mc1.get_project(3)
		refute @mc2.get_project(3)
		refute @mc1.get_project(4)
		assert @mc2.get_project(4)
		assert @mc1.get_project(5)
		refute @mc2.get_project(5)
		refute @mc1.get_project(6)
	end

	def test_create_project
		title = 'some new title'
		description = 'some new description'
		x = @mc1.create_project(title, description)
		assert_equal 6, x[:id]
		assert_equal 1, x[:client][:id]
		assert_equal title, x[:title]
		assert_equal description, x[:description]
		x = @mc2.create_project(title, description)
		assert_equal 7, x[:id]
		assert_equal 2, x[:client][:id]
	end

	def test_update_project
		title = 'some newer title'
		description = 'some newer description'
		refute @mc1.update_project(4, title, description)
		x = @mc1.update_project(5, title, description)
		assert_equal title, x[:title]
		assert_equal description, x[:description]
	end

	def test_approve_quote
		x = @mc2.approve_quote(4)
		assert_equal 'approved', x[:status]
	end

	def test_refuse_quote
		x = @mc2.refuse_quote(4, 'a reason')
		assert_equal 'a reason', x[:note]
	end

	def test_get_project_task
		assert @mc1.get_project_task(3, 8)
		refute @mc2.get_project_task(3, 8)
		assert @mc2.get_project_task(2, 4)
		refute @mc2.get_project_task(4, 4)
	end

end
