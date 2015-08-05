require '../test_tools.rb'

class TestMuckworkDB < Minitest::Test

	def test_project_status_update
		res = DB.exec("SELECT status FROM muckwork.projects WHERE id=5")
		assert_equal 'created', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET quoted_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET approved_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET started_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET finished_at=NOW() WHERE id=5 RETURNING status")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET finished_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET started_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'approved', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'quoted', res[0]['status']
		res = DB.exec("UPDATE muckwork.projects SET quoted_at=NULL WHERE id=5 RETURNING status")
		assert_equal 'created', res[0]['status']
	end

	def test_project_dates
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET quoted_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET started_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET finished_at=NOW() WHERE id=4")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET started_at=NOW() WHERE id=5")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET quoted_at=NULL WHERE id=1")
			DB.exec("UPDATE muckwork.projects SET quoted_at=NOW() WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=1")
			DB.exec("UPDATE muckwork.projects SET approved_at=NOW() WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET started_at=NULL WHERE id=1")
			DB.exec("UPDATE muckwork.projects SET started_at=NOW() WHERE id=1")
		end
	end

	def test_task_status_update
		res = DB.exec("SELECT status FROM muckwork.tasks WHERE id=8")
		assert_equal 'approved', res[0]['status']  # might change
		res = DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=8 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET finished_at=NOW() WHERE id=8 RETURNING status")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET finished_at=NULL WHERE id=8 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=8 RETURNING status")
		assert_equal 'created', res[0]['status']
	end

	def test_task_dates
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NULL WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET finished_at=NOW() WHERE id=8")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NULL WHERE id=1")
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW() WHERE id=1")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=1")
			DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=1")
		end
	end

	def test_no_cents_without_currency
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET final_cents=100 WHERE id=4")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET quoted_cents=100 WHERE id=5")
		end
		DB.exec("UPDATE muckwork.projects SET quoted_currency='EUR', quoted_cents=100 WHERE id=5")
	end

	def test_ratetype
		assert_raises PG::CheckViolation do
			DB.exec("UPDATE muckwork.projects SET quoted_ratetype='yeah' WHERE id=5")
		end
	end

	def test_tasks_claimed_pair
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW() WHERE id=9")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET worker_id=1 WHERE id=9")
		end
		DB.exec("UPDATE muckwork.tasks SET worker_id=1, claimed_at=NOW() WHERE id=9")
		DB.exec("UPDATE muckwork.tasks SET worker_id=NULL, claimed_at=NULL WHERE id=9")
	end

	def test_dates_cant_change
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET finished_at=NOW() WHERE id=1")
		end
		DB.exec("UPDATE muckwork.projects SET finished_at=NULL WHERE id=1")
		DB.exec("UPDATE muckwork.projects SET finished_at=NOW() WHERE id=1")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET started_at=NOW() WHERE id=2")
		end
		DB.exec("UPDATE muckwork.projects SET started_at=NULL WHERE id=2")
		DB.exec("UPDATE muckwork.projects SET started_at=NOW() WHERE id=2")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET approved_at=NOW() WHERE id=3")
		end
		DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=3")
		DB.exec("UPDATE muckwork.projects SET approved_at=NOW() WHERE id=3")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET quoted_at=NOW() WHERE id=4")
		end
		DB.exec("UPDATE muckwork.projects SET quoted_at=NULL WHERE id=4")
		DB.exec("UPDATE muckwork.projects SET quoted_at=NOW() WHERE id=4")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET created_at=NOW() WHERE id=5")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET finished_at=NOW() WHERE id=4")
		end
		DB.exec("UPDATE muckwork.tasks SET finished_at=NULL WHERE id=4")
		DB.exec("UPDATE muckwork.tasks SET finished_at=NOW() WHERE id=4")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=5")
		end
		DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=5")
		DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=5")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW() WHERE id=6")
		end
		DB.exec("UPDATE muckwork.tasks SET claimed_at=NULL, worker_id=NULL WHERE id=6")
		DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=2 WHERE id=6")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET created_at=NOW() WHERE id=9")
		end
	end

	def test_no_delete_started
		assert_raises PG::RaiseException do
			DB.exec("DELETE FROM muckwork.projects WHERE id=2")
		end
		assert_raises PG::RaiseException do
			DB.exec("DELETE FROM muckwork.tasks WHERE id=5")
		end
		DB.exec("DELETE FROM muckwork.tasks WHERE id=10")
		DB.exec("DELETE FROM muckwork.projects WHERE id=4")
	end

	def test_delete_project_deletes_tasks
		DB.exec("DELETE FROM muckwork.projects WHERE id=4")
		res = DB.exec("SELECT * FROM muckwork.tasks WHERE project_id=4")
		assert_equal 0, res.ntuples
		res = DB.exec("SELECT * FROM muckwork.tasks WHERE id=10")
		assert_equal 0, res.ntuples
	end

	def test_no_update_quoted_project
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET title='yeah', description='right' WHERE id=4")
		end
		DB.exec("UPDATE muckwork.projects SET title='yeah', description='right' WHERE id=5")
	end

	def test_no_update_started_task
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET title='yeah', description='right' WHERE id=5")
		end
		DB.exec("UPDATE muckwork.tasks SET title='yeah', description='right' WHERE id=6")
	end
end

