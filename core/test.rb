require '../test_tools.rb'

class CoreTest < Minitest::Test
	include JDB

	def setup
		@raw = "<h1>\r\n\tThis is a title\r\n</h1><p>\r\n\tAnd this?\r\n\tThis is a translation.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a translation.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

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

	def test_code
		res = DB.exec("INSERT INTO core.translations (en) VALUES ('hello') RETURNING code")
		hellocode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hellocode
		res = DB.exec("INSERT INTO core.translations (en) VALUES ('hi') RETURNING code")
		hicode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hicode
		res = DB.exec("SELECT en FROM core.translations WHERE code = '%s'" % hellocode)
		assert_equal 'hello', res[0]['en']
		res = DB.exec("SELECT en FROM core.translations WHERE code = '%s'" % hicode)
		assert_equal 'hi', res[0]['en']
	end

	def test_parse_translation_file
		DB.exec_params("INSERT INTO core.translation_files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM core.parse_translation_file(1)")
		res = DB.exec("SELECT * FROM core.translations WHERE file_id = 1")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal '1', res[0]['sortid']
		assert_equal @lines[0], res[0]['en']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal '2', res[1]['sortid']
		assert_equal @lines[1], res[1]['en']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal '3', res[2]['sortid']
		assert_equal @lines[2], res[2]['en']
		res = DB.exec("SELECT template FROM core.translation_files WHERE id = 1")
		assert_match /<h1>\n\{[A-Za-z0-9]{8}\}\n<\/h1><p>\n\{[A-Za-z0-9]{8}\}\n\{[A-Za-z0-9]{8}\}\n<\/p>/, res[0]['template']
	end

	def test_text_for_translator
		DB.exec_params("INSERT INTO core.translation_files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM core.parse_translation_file(1)")
		res = DB.exec("SELECT * FROM core.text_for_translator(1)")
		assert_equal @lines.join("\r\n"), res[0]['text']
	end

	def test_txn_compare
		DB.exec_params("INSERT INTO core.translation_files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM core.parse_translation_file(1)")
		res = DB.exec_params("SELECT * FROM core.txn_compare(1, $1)", [@fr.join("\r\n")])
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal @lines[0], res[0]['en']
		assert_equal @fr[0], res[0]['theirs']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal @lines[1], res[1]['en']
		assert_equal @fr[1], res[1]['theirs']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal @lines[2], res[2]['en']
		assert_equal @fr[2], res[2]['theirs']
	end

	def test_txn_update
		DB.exec_params("INSERT INTO core.translation_files(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM core.parse_translation_file(1)")
		DB.exec_params("SELECT * FROM core.txn_update(1, 'fr', $1)", [@fr.join("\r\n")])
		res = DB.exec("SELECT * FROM core.translations WHERE file_id=1 ORDER BY sortid")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal @lines[0], res[0]['en']
		assert_equal @fr[0], res[0]['fr']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal @lines[1], res[1]['en']
		assert_equal @fr[1], res[1]['fr']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal @lines[2], res[2]['en']
		assert_equal @fr[2], res[2]['fr']
	end
end
