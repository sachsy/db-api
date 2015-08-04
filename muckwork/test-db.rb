require '../test_tools.rb'

class TestMuckworkDB < Minitest::Test

	def test_project_status_update
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'created', res[0]['status']
		res = DB.exec("UPDATE projects SET quoted_at=NOW() WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE projects SET approved_at=NOW() WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE projects SET started_at=NOW() WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE projects SET finished_at=NOW() WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE projects SET finished_at=NULL WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE projects SET started_at=NULL WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE projects SET approved_at=NULL WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE projects SET quoted_at=NULL WHERE id=5")
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'created', res[0]['status']
	end

end

