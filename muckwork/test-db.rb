P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
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
		res = DB.exec("SELECT status FROM muckwork.tasks WHERE id=6")
		assert_equal 'approved', res[0]['status']  # might change
		res = DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=6 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET finished_at=NOW() WHERE id=6 RETURNING status")
		assert_equal 'finished', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET finished_at=NULL WHERE id=6 RETURNING status")
		assert_equal 'started', res[0]['status']
		res = DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=6 RETURNING status")
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
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET worker_id=1 WHERE id=8")
		end
	end

	def test_only_claim_approved_task
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=1 WHERE id=12")
		end
	end

	def test_only_claim_when_done
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=2 WHERE id=7")
		end
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=3 WHERE id=7")
		end
		DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=1 WHERE id=7")
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
		DB.exec("UPDATE muckwork.tasks SET finished_at='2015-07-09 00:44:56+12' WHERE id=4")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=5")
		end
		DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=5")
		DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=5")
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW() WHERE id=6")
		end
		DB.exec("UPDATE muckwork.tasks SET claimed_at=NULL, worker_id=NULL WHERE id=6")
		DB.exec("UPDATE muckwork.tasks SET claimed_at=NOW(), worker_id=3 WHERE id=6")
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

	def test_task_starts_unstarts_project
		res = DB.exec("SELECT started_at, status FROM muckwork.projects WHERE id=3")
		assert_equal nil, res[0]['started_at']
		assert_equal 'approved', res[0]['status']
		DB.exec("UPDATE muckwork.tasks SET worker_id=1, claimed_at=NOW() WHERE id=7")
		DB.exec("UPDATE muckwork.tasks SET started_at=NOW() WHERE id=7")
		res = DB.exec("SELECT started_at, status FROM muckwork.projects WHERE id=3")
		assert_equal Time.now.to_s[0,7], res[0]['started_at'][0,7]
		assert_equal 'started', res[0]['status']
		DB.exec("UPDATE muckwork.tasks SET started_at=NULL WHERE id=7")
		res = DB.exec("SELECT started_at, status FROM muckwork.projects WHERE id=3")
		assert_equal nil, res[0]['started_at']
		assert_equal 'approved', res[0]['status']
	end

	def test_task_finishes_unfinishes_project
		res = DB.exec("SELECT finished_at, status FROM muckwork.projects WHERE id=2")
		assert_equal nil, res[0]['finished_at']
		assert_equal 'started', res[0]['status']
		DB.exec("UPDATE muckwork.tasks SET finished_at='2015-07-09 05:00:00+12' WHERE id=5")
		res = DB.exec("SELECT finished_at, status FROM muckwork.projects WHERE id=2")
		assert_equal nil, res[0]['finished_at']
		assert_equal 'started', res[0]['status']
		DB.exec("UPDATE muckwork.tasks SET started_at='2015-07-09 05:00:00+12' WHERE id=6")
		DB.exec("UPDATE muckwork.tasks SET finished_at='2015-07-09 06:00:00+12' WHERE id=6")
		res = DB.exec("SELECT finished_at, status FROM muckwork.projects WHERE id=2")
		assert_equal '2015-07-09 06:00:00+12', res[0]['finished_at']
		assert_equal 'finished', res[0]['status']
		DB.exec("UPDATE muckwork.tasks SET finished_at=NULL WHERE id=6")
		res = DB.exec("SELECT finished_at, status FROM muckwork.projects WHERE id=2")
		assert_equal nil, res[0]['finished_at']
		assert_equal 'started', res[0]['status']
	end

	def test_seconds_per_task
		res = DB.exec("SELECT seconds FROM muckwork.seconds_per_task(2)")
		assert_equal '60', res[0]['seconds']
		res = DB.exec("SELECT seconds FROM muckwork.seconds_per_task(3)")
		assert_equal '10680', res[0]['seconds']
		res = DB.exec("SELECT seconds FROM muckwork.seconds_per_task(9)")
		assert_equal nil, res[0]['seconds']
	end

	def test_worker_charge_for_task
		res = DB.exec("SELECT * FROM muckwork.worker_charge_for_task(1)")
		assert_equal 'USD', res[0]['currency']
		assert_equal '25', res[0]['cents']
		res = DB.exec("SELECT * FROM muckwork.worker_charge_for_task(4)")
		assert_equal 'THB', res[0]['currency']
		assert_equal '108000', res[0]['cents']
		res = DB.exec("SELECT * FROM muckwork.worker_charge_for_task(99)")
		assert_equal 1, res.ntuples # returns result, regardless
		assert_equal nil, res[0]['currency']
		assert_equal nil, res[0]['cents']
	end

	def test_task_creates_charge
		res = DB.exec("SELECT * FROM muckwork.worker_charges WHERE task_id = 5")
		assert_equal 0, res.ntuples
		res = DB.exec("UPDATE muckwork.tasks SET finished_at='2015-07-09 04:35:00+12' WHERE id = 5")
		res = DB.exec("SELECT * FROM muckwork.worker_charges WHERE task_id = 5")
		assert_equal 'THB', res[0]['currency']
		assert_equal '21000', res[0]['cents']
	end

	def tesk_task_uncreates_charge
		res = DB.exec("SELECT * FROM muckwork.worker_charges WHERE task_id = 4")
		assert_equal 'THB', res[0]['currency']
		assert_equal '108000', res[0]['cents']
		res = DB.exec("UPDATE muckwork.tasks SET finished_at=NULL WHERE id = 4")
		res = DB.exec("SELECT * FROM muckwork.worker_charges WHERE task_id = 4")
		assert_equal 0, res.ntuples
	end

	def test_approve_project_approves_tasks
		DB.exec("UPDATE muckwork.projects SET approved_at=NOW() WHERE id=4")
		res = DB.exec("SELECT 1 FROM muckwork.tasks WHERE project_id=4 AND status='approved'")
		assert_equal 3, res.ntuples
	end

	def test_unapprove_project_unapproves_tasks
		DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=3")
		res = DB.exec("SELECT 1 FROM muckwork.tasks WHERE project_id=3 AND status='quoted'")
		assert_equal 3, res.ntuples
		# make sure it doesn't change task status for illegal un-approve
		assert_raises PG::RaiseException do
			DB.exec("UPDATE muckwork.projects SET approved_at=NULL WHERE id=1")
		end
		res = DB.exec("SELECT 1 FROM muckwork.tasks WHERE project_id=1 AND status='finished'")
		assert_equal 3, res.ntuples
	end

	def test_final_project_charges
		res = DB.exec("SELECT * FROM muckwork.final_project_charges(1)")
		assert_equal 'USD', res[0]['currency']
		assert_equal '4536', res[0]['cents']
		DB.exec("UPDATE muckwork.tasks SET finished_at = '2015-07-09 05:00:00+12' WHERE id = 5")
		DB.exec("UPDATE muckwork.tasks SET started_at = '2015-07-09 05:00:00+12' WHERE id = 6")
		DB.exec("UPDATE muckwork.tasks SET finished_at = '2015-07-09 07:00:00+12' WHERE id = 6")
		res = DB.exec("SELECT * FROM muckwork.final_project_charges(2)")
		assert_equal 'GBP', res[0]['currency']
		assert_equal '4051', res[0]['cents']
	end

	def test_project_creates_and_uncreates_charge
		DB.exec("UPDATE muckwork.tasks SET finished_at = '2015-07-09 05:00:00+12' WHERE id = 5")
		DB.exec("UPDATE muckwork.tasks SET started_at = '2015-07-09 05:00:00+12' WHERE id = 6")
		DB.exec("UPDATE muckwork.tasks SET finished_at = '2015-07-09 07:00:00+12' WHERE id = 6")
		res = DB.exec("SELECT * FROM muckwork.projects WHERE id = 2")
		assert_equal 'GBP', res[0]['final_currency']
		assert_equal '4051', res[0]['final_cents']
		res = DB.exec("SELECT * FROM muckwork.charges WHERE project_id = 2")
		assert_equal 1, res.ntuples
		assert_equal 'GBP', res[0]['currency']
		assert_equal '4051', res[0]['cents']
		# now uncreate it
		DB.exec("UPDATE muckwork.tasks SET finished_at = NULL WHERE id = 6")
		res = DB.exec("SELECT * FROM muckwork.projects WHERE id = 2")
		assert_equal nil, res[0]['final_currency']
		assert_equal nil, res[0]['final_cents']
		res = DB.exec("SELECT * FROM muckwork.charges WHERE project_id = 2")
		assert_equal 0, res.ntuples
	end

	def test_auto_sortid
		res = DB.exec("INSERT INTO muckwork.tasks(project_id, title, description) VALUES (4, 'a', 'a') RETURNING *");
		assert_equal '13', res[0]['id']
		assert_equal '4', res[0]['sortid']
		res = DB.exec("INSERT INTO muckwork.tasks(project_id, title, description) VALUES (5, 'a', 'a') RETURNING *");
		assert_equal '14', res[0]['id']
		assert_equal '1', res[0]['sortid']
		res = DB.exec("INSERT INTO muckwork.tasks(project_id, title, description) VALUES (4, 'a', 'a') RETURNING *");
		assert_equal '15', res[0]['id']
		assert_equal '5', res[0]['sortid']
	end

	def test_notes_empty
		assert_raises PG::CheckViolation do
			DB.exec("INSERT INTO muckwork.notes(project_id, note) VALUES (1, '')")
		end
		DB.exec("INSERT INTO muckwork.notes(project_id, note) VALUES (1, 'ok')")
	end

	def test_is_worker_available
		res = DB.exec("SELECT * FROM is_worker_available(1)")
		assert_equal 't', res[0]['is_worker_available']
		res = DB.exec("SELECT * FROM is_worker_available(2)")
		assert_equal 'f', res[0]['is_worker_available']
		res = DB.exec("SELECT * FROM is_worker_available(3)")
		assert_equal 'f', res[0]['is_worker_available']
		res = DB.exec("SELECT * FROM is_worker_available(99)")
		assert_equal 't', res[0]['is_worker_available']
	end
end

