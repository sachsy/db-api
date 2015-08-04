require '../test_tools.rb'

class TestMuckworkDB < Minitest::Test

	def test_project_status_update
		res = DB.exec("SELECT status FROM projects WHERE id=5")
		assert_equal 'created', res[0]['status']
		res = DB.exec("UPDATE projects SET quoted_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE projects SET approved_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE projects SET started_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE projects SET finished_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE projects SET finished_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE projects SET started_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE projects SET approved_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE projects SET quoted_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'created', res[0]['status']
	end

	def test_project_dates
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET quoted_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET approved_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET started_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET finished_at=NOW() WHERE id=4")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET started_at=NOW() WHERE id=5")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE projects SET created_at=NOW() WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE projects SET quoted_at=NOW() WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE projects SET approved_at=NOW() WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE projects SET started_at=NOW() WHERE id=1")
		end
	end

	def test_task_status_update
		res = DB.exec("SELECT status FROM tasks WHERE id=8")
		assert_equal 'approved', res[0]['status']  # might change
		res = DB.exec("UPDATE tasks SET started_at=NOW() WHERE id=8 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE tasks SET finished_at=NOW() WHERE id=8 RETURNING status")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE tasks SET finished_at=NULL WHERE id=8 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE tasks SET started_at=NULL WHERE id=8 RETURNING status")
		assert_equal 'created', res[0]['status']
	end

	def test_task_dates
		assert_raises PG::RaiseException do
			DB.exec("UPDATE tasks SET started_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE tasks SET finished_at=NOW() WHERE id=8")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE tasks SET created_at=NOW() WHERE id=1")
		end
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE tasks SET started_at=NOW() WHERE id=1")
		end
	end

	def test_no_cents_without_currency
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET final_cents=100 WHERE id=4")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE projects SET quoted_cents=100 WHERE id=5")
		end
		DB.exec("UPDATE projects SET quoted_currency='EUR', quoted_cents=100 WHERE id=5")
	end

	def test_ratetype
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE projects SET quoted_ratetype='yeah' WHERE id=5")
		end
	end
end

