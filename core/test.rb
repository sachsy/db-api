require '../test_tools.rb'

class CoreTest < Minitest::Test
	include JDB

	def test_strip_tags
		res = DB.exec_params("SELECT core.strip_tags($1)", ['þ <script>alert("poop")</script> <a href="http://something.net">yuck</a>'])
		assert_equal 'þ alert("poop") yuck', res[0]['strip_tags']
	end

	def test_escape_html
		res = DB.exec_params("SELECT core.escape_html($1)", [%q{I'd "like" <&>}])
		assert_equal 'I&#39;d &quot;like&quot; &lt;&amp;&gt;', res[0]['escape_html']
	end

	def test_currency_from_to
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'USD', 'EUR')")
		assert (881..882).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'EUR', 'USD')")
		assert (1135..1136).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'JPY', 'EUR')")
		assert (7..8).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(1000, 'EUR', 'BTC')")
		assert (4..5).cover? res[0]['amount'].to_f 
		res = DB.exec("SELECT * FROM core.currency_from_to(9, 'BTC', 'JPY')")
		assert (248635..248636).cover? res[0]['amount'].to_f 
	end
	
	def test_all_currencies
		qry("core.all_currencies()")
		assert_equal 34, @j.size
		assert_equal({code: 'AUD', name: 'Australian Dollar'}, @j[0])
		assert_equal({code: 'ZAR', name: 'South African Rand'}, @j[33])
	end

	def test_currency_names
		qry("core.currency_names()")
		assert_equal 34, @j.size
		assert_equal 'Singapore Dollar', @j[:SGD]
		assert_equal 'Euro', @j[:EUR]
	end

end
