require '../test_tools.rb'

class CoreTest < Minitest::Test
	include JDB

	def test_currency_from_to
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'USD', 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'EUR', 'USD')")
		assert (1135..1136).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'JPY', 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(1000, 'EUR', 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM currency_from_to(9, 'BTC', 'JPY')")
		assert (248635..248636).cover? res[0]['amount'].to_f 
	end
	
	def test_all_currencies
		qry("all_currencies()")
		assert_equal 34, @j.size
		assert_equal({code: 'AUD', name: 'Australian Dollar'}, @j[0])
		assert_equal({code: 'ZAR', name: 'South African Rand'}, @j[33])
	end

	def test_currency_names
		qry("currency_names()")
		assert_equal 34, @j.size
		assert_equal 'Singapore Dollar', @j[:SGD]
		assert_equal 'Euro', @j[:EUR]
	end

end
