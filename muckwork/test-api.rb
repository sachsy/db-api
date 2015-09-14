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

end

