require '../test_tools.rb'

class MuckworkAPITest < Minitest::Test
	include JDB

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
		qry("muckwork.get_projects_with_status('approved')")
		assert_equal 1, @j.size
		assert_equal 3, @j[0][:id]
		assert_equal 'Unstarted project', @j[0][:title]
	end

	def test_get_project
		qry("muckwork.get_project(1)")
		r = {id: 1,
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
		assert_equal r, @j
	end
end

