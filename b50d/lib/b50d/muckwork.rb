require_relative 'dbapi.rb'

module B50D
	class Muckwork
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(server='live')
			@db = DbAPI.new(server)
		end

		def get_clients
			@db.js('muckwork.get_clients()')
		end

		def get_client(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.get_client($1)', [id])
		end

		def create_client(person_id)
			return false unless /\A[0-9]+\Z/ === String(person_id)
			@db.js('muckwork.create_client($1)', [person_id])
		end

		def update_client(id, currency)
			return false unless /\A[0-9]+\Z/ === String(id)
			return false unless /\A[A-Z]{3}\Z/ === String(currency)
			@db.js('muckwork.update_client($1, $2)', [id, currency])
		end

		def get_workers
			@db.js('muckwork.get_workers()')
		end

		def get_worker(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.get_worker($1)', [id])
		end

		def create_worker(person_id)
			return false unless /\A[0-9]+\Z/ === String(person_id)
			@db.js('muckwork.create_worker($1)', [person_id])
		end

		def update_worker(id, currency, millicents_per_second)
			return false unless /\A[0-9]+\Z/ === String(id)
			return false unless /\A[A-Z]{3}\Z/ === String(currency)
			return false unless /\A[0-9]+\Z/ === String(millicents_per_second)
			@db.js('muckwork.update_worker($1, $2, $3)', [id, currency, millicents_per_second])
		end

		def get_projects
			@db.js('muckwork.get_projects()')
		end

		def get_projects_with_status(status)
			return false unless %w(created quoted approved refused started finished).include? status
			@db.js('muckwork.get_projects_with_status($1)', [status])
		end

		def get_project(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.get_project($1)', [id])
		end

		def create_project(client_id, title, description)
			return false unless /\A[0-9]+\Z/ === String(client_id)
			@db.js('muckwork.create_project($1, $2, $3)', [client_id, title, description])
		end

		def update_project(id, title, description)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.update_project($1, $2, $3)', [id, title, description])
		end

		def quote_project(id, ratetype, currency, cents)
			return false unless /\A[0-9]+\Z/ === String(id)
			return false unless %w(fix time).include? ratetype
			return false unless /\A[A-Z]{3}\Z/ === String(currency)
			return false unless /\A[0-9]+\Z/ === String(cents)
			@db.js('muckwork.quote_project($1, $2, $3, $4)', [id, ratetype, currency, cents])
		end

		def approve_quote(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.approve_quote($1)', [id])
		end

		def refuse_quote(project_id, description)
			return false unless /\A[0-9]+\Z/ === String(project_id)
			return false unless String(description).strip.size > 0
			@db.js('muckwork.refuse_quote($1, $2)', [project_id, description])
		end

		def get_task(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.get_task($1)', [id])
		end

		def create_task(project_id, title, description, sortid=nil)
			return false unless /\A[0-9]+\Z/ === String(project_id)
			@db.js('muckwork.create_task($1, $2, $3, $4)', [project_id, title, description, sortid])
		end

		def update_task(id, title, description, sortid=nil)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.update_task($1, $2, $3, $4)', [id, title, description, sortid])
		end

		def claim_task(id, worker_id)
			return false unless /\A[0-9]+\Z/ === String(id)
			return false unless /\A[0-9]+\Z/ === String(worker_id)
			@db.js('muckwork.claim_task($1, $2)', [id, worker_id])
		end

		def unclaim_task(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.unclaim_task($1)', [id])
		end

		def start_task(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.start_task($1)', [id])
		end

		def finish_task(id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.finish_task($1)', [id])
		end

		def get_tasks_with_status(status)
			return false unless %w(created quoted approved refused started finished).include? status
			@db.js('muckwork.get_tasks_with_status($1)', [status])
		end

	end
end

