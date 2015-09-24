require '../test_tools.rb'

class MuckworkAPITest < Minitest::Test
	include JDB
	
	def setup
		super
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
			],
			notes: [{id: 1,
				created_at: '2015-07-07T12:34:56+12:00',
				task_id: 1,
				manager_id: nil,
				client_id: 1,
				worker_id: nil,
				note: 'great job, Charlie!'}]}
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
				email: 'charlie@bucket.org'},
			notes: [{id: 1,
				created_at: '2015-07-07T12:34:56+12:00',
				manager_id: nil,
				client_id: 1,
				worker_id: nil,
				note: 'great job, Charlie!'}]}
	end

	def test_get_clients
		qry("muckwork.get_clients()")
		r = [
			{id:2, person_id:3, currency:'GBP', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'},
			{id:1, person_id:2, currency:'USD', cents_balance:463, name:'Willy Wonka', email:'willy@wonka.com'}]
		assert_equal r, @j
	end

	def test_get_client
		qry("muckwork.get_client(2)")
		r = {id:2, person_id:3, currency:'GBP', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'}
		assert_equal r, @j
		qry("muckwork.get_client(99)")
		assert_equal 'Not Found', @j[:title]
	end

	def test_create_client
		qry("muckwork.create_client(8)")
		r = {id:3, person_id:8, currency:'USD', cents_balance:0, name:'Yoko Ono', email:'yoko@ono.com'}
		assert_equal r, @j
		qry("muckwork.create_client(99)")
		assert @j[:title].include? 'violates foreign key'
	end

	def test_update_client
		qry("muckwork.update_client(2, 'EUR')")
		r = {id:2, person_id:3, currency:'EUR', cents_balance:10000, name:'Veruca Salt', email:'veruca@salt.com'}
		assert_equal r, @j
		qry("muckwork.update_client(99, 'EUR')")
		assert_equal 'Not Found', @j[:title]
	end

	def test_get_workers
		qry("muckwork.get_workers()")
		r = [
			{id:2, person_id:5, currency:'THB', millicents_per_second:1000, name:'Oompa Loompa', email:'oompa@loompa.mm'},
			{id:1, person_id:4, currency:'USD', millicents_per_second:42, name:'Charlie Buckets', email:'charlie@bucket.org'}]
		assert_equal r, @j
	end

	def test_get_worker
		qry("muckwork.get_worker(2)")
		r = {id:2, person_id:5, currency:'THB', millicents_per_second:1000, name:'Oompa Loompa', email:'oompa@loompa.mm'}
		assert_equal r, @j
		qry("muckwork.get_worker(99)")
		assert_equal 'Not Found', @j[:title]
	end

	def test_create_worker
		qry("muckwork.create_worker(8)")
		r = {id:3, person_id:8, currency:'USD', millicents_per_second:nil, name:'Yoko Ono', email:'yoko@ono.com'}
		assert_equal r, @j
		qry("muckwork.create_worker(99)")
		assert @j[:title].include? 'violates foreign key'
	end

	def test_update_worker
		qry("muckwork.update_worker(2, 'INR', 1234)")
		r = {id:2, person_id:5, currency:'INR', millicents_per_second:1234, name:'Oompa Loompa', email:'oompa@loompa.mm'}
		assert_equal r, @j
		qry("muckwork.update_worker(99, 'INR', 1234)")
		assert_equal 'Not Found', @j[:title]
	end

	def test_get_projects
		qry("muckwork.get_projects()")
		assert_equal 5, @j.size
		assert_equal [5,4,3,2,1], @j.map {|p| p[:id]}
	end

	def test_get_projects_with_status
		qry("muckwork.get_projects_with_status('finished')")
		assert_equal 1, @j.size
		assert_equal @project_view_1, @j[0]
	end

	def test_get_project
		qry("muckwork.get_project(1)")
		assert_equal @project_detail_view_1, @j
	end

	def test_create_project
		qry("muckwork.create_project(2, 'a title', 'a description')")
		assert_equal 6, @j[:id]
		assert_equal 'a title', @j[:title]
		assert_equal 'a description', @j[:description]
		assert_equal 'Veruca Salt', @j[:client][:name]
		assert_equal 'created', @j[:status]
	end

	def test_update_project
		qry("muckwork.update_project(5, 'new title', 'new description')")
		assert_equal 'new title', @j[:title]
		assert_equal 'new description', @j[:description]
	end

	def test_quote_project
		qry("muckwork.quote_project(5, 'time', 'USD', 1000)")
		assert_equal 'quoted', @j[:status]
		assert_equal 'time', @j[:quoted_ratetype]
		assert_equal 'USD', @j[:quoted_money][:currency]
		assert_equal 1000, @j[:quoted_money][:cents]
	end

	def test_approve_quote
		qry("muckwork.approve_quote(4)")
		assert_equal 'approved', @j[:status]
		assert_match /^20[0-9][0-9]-/, @j[:approved_at]
	end

	def test_refuse_quote
		qry("muckwork.refuse_quote(1, 'nah')")
		assert_equal 'Not Found', @j[:title]
		qry("muckwork.refuse_quote(9, 'nah')")
		assert_equal 'Not Found', @j[:title]
		qry("muckwork.refuse_quote(4, 'nah')")
		assert_equal 2, @j[:id]
		assert_equal 'nah', @j[:note]
		assert_match /\A20[0-9]{2}-[0-9]{2}/, @j[:created_at]
		assert_equal 4, @j[:project_id]
		assert_equal 2, @j[:client_id]
		qry("muckwork.get_project(4)")
		assert_equal 'refused', @j[:status]
	end

	def test_get_task
		qry("muckwork.get_task(1)")
		assert_equal @task_view_1, @j
	end

	def test_create_task
		qry("muckwork.create_task(5, '1 title', 'a description', NULL)")
		assert_equal 1, @j[:sortid]
		assert_equal 'Unquoted project', @j[:project][:title]
		qry("muckwork.create_task(5, '3 title', 'c description', 3)")
		assert_equal 3, @j[:sortid]
		assert_equal 'c description', @j[:description]
		qry("muckwork.create_task(5, '2 title', 'b description', 2)")
		assert_equal 2, @j[:sortid]
		qry("muckwork.create_task(5, '4 title', 'd description', NULL)")
		assert_equal 4, @j[:sortid]
	end

	def test_update_task
		qry("muckwork.update_task(12, 'nu title', 'nu description', 1)")
		assert_equal 1, @j[:sortid]
		assert_equal 'nu title', @j[:title]
		assert_equal 'nu description', @j[:description]
	end

	def test_claim_task
		qry("muckwork.claim_task(9, 1)")
		assert_equal 'Charlie Buckets', @j[:worker][:name]
		assert_equal 'approved', @j[:status]  # 'claimed' is not a status
		assert_match /^20[0-9][0-9]-/, @j[:claimed_at]
	end

	def test_unclaim_task
		qry("muckwork.unclaim_task(8)")
		assert_equal nil, @j[:worker]
		assert_equal nil, @j[:claimed_at]
		assert_equal 'approved', @j[:status]
	end

	def test_start_task
		qry("muckwork.start_task(7)")
		assert_equal 'started', @j[:status]
		assert_match /^20[0-9][0-9]-/, @j[:started_at]
	end

	def test_finish_task
		qry("muckwork.start_task(7)")
		qry("muckwork.finish_task(7)")
		assert_equal 'finished', @j[:status]
		assert_match /^20[0-9][0-9]-/, @j[:finished_at]
	end

	def test_get_tasks_with_status
		qry("muckwork.get_tasks_with_status('started')")
		assert_equal 1, @j.size
		assert_equal 5, @j[0][:id]
		assert_equal 'started', @j[0][:status]
		assert_equal 'Oompa Loompa', @j[0][:worker][:name]
	end

end
