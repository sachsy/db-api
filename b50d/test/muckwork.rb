SCHEMA = File.read('../../muckwork/schema.sql')
FIXTURES = File.read('../../muckwork/fixtures.sql')
P_SCHEMA = File.read('../../peeps/schema.sql')
P_FIXTURES = File.read('../../peeps/fixtures.sql')
require '../../test_tools.rb'

require '../lib/b50d/muckwork.rb'

class TestMuckwork < Minitest::Test

	def setup
		super
		@mw = B50D::Muckwork.new('test')
		# EXAMPLES OF VIEWS
		@project_view_1 = {id: 1,
			title: 'Finished project',
			description: 'by Wonka for Charlie',
			created_at: '2015-07-02T00:34:56+12:00',
			quoted_at: '2015-07-03T00:34:56+12:00',
			approved_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:34:56+12:00',
			finished_at: '2015-07-05T03:34:56+12:00',
			status: 'finished',
			client: {id: 1,
				person_id: 2,
				currency: 'USD',
				cents_balance:  463,
				name: 'Willy Wonka',
				email: 'willy@wonka.com'},
			quoted_ratetype: 'time',
			quoted_money: {currency: 'USD', cents: 5000},
			final_money: {currency: 'USD', cents: 4536}}
		@project_detail_view_1 = {id: 1,
			title: 'Finished project',
			description: 'by Wonka for Charlie',
			created_at: '2015-07-02T00:34:56+12:00',
			quoted_at: '2015-07-03T00:34:56+12:00',
			approved_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:34:56+12:00',
			finished_at: '2015-07-05T03:34:56+12:00',
			status: 'finished',
			client: {id: 1,
				person_id: 2,
				currency: 'USD',
				cents_balance:  463,
				name: 'Willy Wonka',
				email: 'willy@wonka.com'},
			quoted_ratetype: 'time',
			quoted_money: {currency: 'USD', cents: 5000},
			final_money: {currency: 'USD', cents: 4536},
			tasks: [
				{id: 2,
				project_id: 1,
				worker_id: 1,
				sortid: 1,
				title: 'first task',
				description: 'clean hands',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:34:56+12:00',
				finished_at: '2015-07-05T00:35:56+12:00',
				status: 'finished',
				worker: {id: 1,
					person_id: 4,
					currency: 'USD',
					millicents_per_second: 42,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}},
				{id: 1,
				project_id: 1,
				worker_id: 1,
				sortid: 2,
				title: 'second task',
				description: 'get bucket',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:35:56+12:00',
				finished_at: '2015-07-05T00:36:56+12:00',
				status: 'finished',
				worker: {id: 1,
					person_id: 4,
					currency: 'USD',
					millicents_per_second: 42,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}},
				{id: 3,
				project_id: 1,
				worker_id: 1,
				sortid: 3,
				title: 'third task',
				description: 'clean tank',
				created_at: '2015-07-03T00:34:56+12:00',
				claimed_at: '2015-07-04T00:34:56+12:00',
				started_at: '2015-07-05T00:36:56+12:00',
				finished_at: '2015-07-05T03:34:56+12:00',
				status: 'finished',
				worker: {id: 1,
					person_id: 4,
					currency: 'USD',
					millicents_per_second: 42,
					name: 'Charlie Buckets',
					email: 'charlie@bucket.org'}}
			]}
		@task_view_1 = {id: 1,
			project_id: 1,
			worker_id: 1,
			sortid: 2,
			title: 'second task',
			description: 'get bucket',
			created_at: '2015-07-03T00:34:56+12:00',
			claimed_at: '2015-07-04T00:34:56+12:00',
			started_at: '2015-07-05T00:35:56+12:00',
			finished_at: '2015-07-05T00:36:56+12:00',
			status: 'finished',
			project: {id: 1,
				title: 'Finished project',
				description: 'by Wonka for Charlie'},
			worker: {id: 1,
				person_id: 4,
				currency: 'USD',
				millicents_per_second: 42,
				name: 'Charlie Buckets',
				email: 'charlie@bucket.org'}}
	end

	def test_get_clients
		x = @mw.get_clients
		r = [
			{id:2, person_id:3, currency:'GBP', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'},
			{id:1, person_id:2, currency:'USD', cents_balance:463, name:'Willy Wonka', email:'willy@wonka.com'}]
		assert_equal r, x
	end

	def test_get_client
		x = @mw.get_client(2)
		r = {id:2, person_id:3, currency:'GBP', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'}
		assert_equal r, x
		x = @mw.get_client(99)
		assert_equal false, x
	end

	def test_create_client
		x = @mw.create_client(8)
		r = {id:3, person_id:8, currency:'USD', cents_balance:0, name:'Yoko Ono', email:'yoko@ono.com'}
		assert_equal r, x
		x = @mw.create_client(99)
		assert_equal false, x
	end

	def test_update_client
		x = @mw.update_client(2, 'EUR')
		r = {id:2, person_id:3, currency:'EUR', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'}
		assert_equal r, x
		x = @mw.update_client(99, 'EUR')
		assert_equal false, x
	end

	def test_get_workers
		x = @mw.get_workers
		r = [
			{id:2, person_id:5, currency:'THB', millicents_per_second:1000, name:'Oompa Loompa', email:'oompa@loompa.mm'},
			{id:1, person_id:4, currency:'USD', millicents_per_second:42, name:'Charlie Buckets', email:'charlie@bucket.org'}]
		assert_equal r, x
	end

	def test_get_worker
		x = @mw.get_worker(2)
		r = {id:2, person_id:5, currency:'THB', millicents_per_second:1000, name:'Oompa Loompa', email:'oompa@loompa.mm'}
		assert_equal r, x
		x = @mw.get_worker(99)
		assert_equal false, x
	end

	def test_create_worker
		x = @mw.create_worker(8)
		r = {id:3, person_id:8, currency:'USD', millicents_per_second:nil, name:'Yoko Ono', email:'yoko@ono.com'}
		assert_equal r, x
		x = @mw.create_worker(99)
		assert_equal false, x
	end

	def test_update_worker
		x = @mw.update_worker(2, 'INR', 1234)
		r = {id:2, person_id:5, currency:'INR', millicents_per_second:1234, name:'Oompa Loompa', email:'oompa@loompa.mm'}
		assert_equal r, x
		x = @mw.update_worker(99, 'INR', 1234)
		assert_equal false, x
	end

	def test_get_projects
		x = @mw.get_projects
		assert_equal 5, x.size
		assert_equal [5,4,3,2,1], x.map {|p| p[:id]}
	end

	def test_get_projects_with_status
		x = @mw.get_projects_with_status('finished')
		assert_equal 1, x.size
		assert_equal @project_view_1, x[0]
	end

	def test_get_project
		x = @mw.get_project(1)
		assert_equal @project_detail_view_1, x
	end

	def test_create_project
		x = @mw.create_project(2, 'a title', 'a description')
		assert_equal 6, x[:id]
		assert_equal 'a title', x[:title]
		assert_equal 'a description', x[:description]
		assert_equal 'Veruca Salt', x[:client][:name]
		assert_equal 'created', x[:status]
	end

	def test_update_project
		x = @mw.update_project(5, 'new title', 'new description')
		assert_equal 'new title', x[:title]
		assert_equal 'new description', x[:description]
	end

	def test_quote_project
		x = @mw.quote_project(5, 'time', 'USD', 1000)
		assert_equal 'quoted', x[:status]
		assert_equal 'time', x[:quoted_ratetype]
		assert_equal 'USD', x[:quoted_money][:currency]
		assert_equal 1000, x[:quoted_money][:cents]
	end

	def test_approve_quote
		x = @mw.approve_quote(4)
		assert_equal 'approved', x[:status]
		assert_match /^20[0-9][0-9]-/, x[:approved_at]
	end

	def test_refuse_quote
		#TODO
		#x = @mw.refuse_quote(integer, text)
		#assert_equal x, x
	end

	def test_get_task
		x = @mw.get_task(1)
		assert_equal @task_view_1, x
	end

	def test_create_task
		x = @mw.create_task(5, '1 title', 'a description')
		assert_equal 1, x[:sortid]
		assert_equal 'Unquoted project', x[:project][:title]
		x = @mw.create_task(5, '3 title', 'c description', 3)
		assert_equal 3, x[:sortid]
		assert_equal 'c description', x[:description]
		x = @mw.create_task(5, '2 title', 'b description', 2)
		assert_equal 2, x[:sortid]
		x = @mw.create_task(5, '4 title', 'd description')
		assert_equal 4, x[:sortid]
	end

	def test_update_task
		x = @mw.update_task(12, 'nu title', 'nu description', 1)
		assert_equal 1, x[:sortid]
		assert_equal 'nu title', x[:title]
		assert_equal 'nu description', x[:description]
	end

	def test_claim_task
		x = @mw.claim_task(9, 1)
		assert_equal 'Charlie Buckets', x[:worker][:name]
		assert_equal 'approved', x[:status]  # 'claimed' is not a status
		assert_match /^20[0-9][0-9]-/, x[:claimed_at]
	end

	def test_unclaim_task
		x = @mw.unclaim_task(8)
		assert_equal nil, x[:worker]
		assert_equal nil, x[:claimed_at]
		assert_equal 'approved', x[:status]
	end

	def test_start_task
		x = @mw.start_task(7)
		assert_equal 'started', x[:status]
		assert_match /^20[0-9][0-9]-/, x[:started_at]
	end

	def test_finish_task
		@mw.start_task(7)
		x = @mw.finish_task(7)
		assert_equal 'finished', x[:status]
		assert_match /^20[0-9][0-9]-/, x[:finished_at]
	end

	def test_get_tasks_with_status
		x = @mw.get_tasks_with_status('started')
		assert_equal 1, x.size
		assert_equal 5, x[0][:id]
		assert_equal 'started', x[0][:status]
		assert_equal 'Oompa Loompa', x[0][:worker][:name]
	end

end
