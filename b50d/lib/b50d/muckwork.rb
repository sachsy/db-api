require_relative 'dbapi.rb'

module B50D
	class Muckwork
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(server='live')
			@db = DbAPI.new(server)
		end

		def client_owns_project(client_id, project_id)
			x = @db.js('muckwork.client_owns_project($1, $2)', [client_id, project_id])
			{ok: true} == x
		end

		def worker_owns_task(worker_id, task_id)
			x = @db.js('muckwork.worker_owns_task($1, $2)', [worker_id, task_id])
			{ok: true} == x
		end

		def project_has_status(project_id, status)
			x = @db.js('muckwork.project_has_status($1, $2)', [project_id, status])
			{ok: true} == x
		end

		def task_has_status(task_id, status)
			x = @db.js('muckwork.task_has_status($1, $2)', [task_id, status])
			{ok: true} == x
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

		def update_client(id, params)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.update_client($1, $2)', [id, params.to_json])
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

		def update_worker(id, params)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('muckwork.update_worker($1, $2)', [id, params.to_json])
		end

		def get_projects
			@db.js('muckwork.get_projects()')
		end

		def client_get_projects(client_id)
			@db.js('muckwork.client_get_projects($1)', [client_id])
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

		def get_project_task(project_id, task_id)
			return false unless /\A[0-9]+\Z/ === String(project_id)
			return false unless /\A[0-9]+\Z/ === String(task_id)
			@db.js('muckwork.get_project_task($1, $2)', [project_id, task_id])
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

		def worker_get_tasks(worker_id)
			return false unless /\A[0-9]+\Z/ === String(worker_id)
			@db.js('muckwork.worker_get_tasks($1)', [worker_id])
		end

		def get_tasks_with_status(status)
			return false unless %w(created quoted approved refused started finished).include? status
			@db.js('muckwork.get_tasks_with_status($1)', [status])
		end
	end


	class MuckworkClient
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(api_key, api_pass, server='live')
			@db = DbAPI.new(server)
			x = @db.js('muckwork.auth_client($1, $2)', [api_key, api_pass])
			raise 'bad API auth' unless x.key? :client_id
			@client_id = x[:client_id]
			@person_id = x[:person_id]
			@mw = B50D::Muckwork.new(server)
		end

		def locations
			@db.js('peeps.all_countries()')
		end

		def currencies
			@db.js('peeps.all_currencies()')
		end

		def set_password(newpass)
			@db.js('peeps.set_password($1, $2)', [@person_id, newpass])
		end

		def get_client
			@mw.get_client(@client_id)
		end

		def update(params)
			params.delete :person_id
			@mw.update_client(@client_id, params)
		end

		def get_projects
			@mw.client_get_projects(@client_id)
		end

		def get_project(project_id)
			return false unless @mw.client_owns_project(@client_id, project_id)
			@mw.get_project(project_id)
		end

		def create_project(title, description)
			@mw.create_project(@client_id, title, description)
		end

		def update_project(project_id, title, description)
			return false unless @mw.client_owns_project(@client_id, project_id)
			@mw.update_project(project_id, title, description)
		end

		def approve_quote(project_id)
			return false unless @mw.client_owns_project(@client_id, project_id)
			@mw.approve_quote(project_id)
		end

		def refuse_quote(project_id, reason)
			return false unless @mw.client_owns_project(@client_id, project_id)
			@mw.refuse_quote(project_id, reason)
		end

		def get_project_task(project_id, task_id)
			return false unless @mw.client_owns_project(@client_id, project_id)
			@mw.get_project_task(project_id, task_id)
		end
	end


	class Muckworker
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(api_key, api_pass, server='live')
			@db = DbAPI.new(server)
			x = @db.js('muckwork.auth_worker($1, $2)', [api_key, api_pass])
			raise 'bad API auth' unless x.key? :worker_id
			@worker_id = x[:worker_id]
			@person_id = x[:person_id]
			@mw = B50D::Muckwork.new(server)
		end

		def locations
			@db.js('peeps.all_countries()')
		end

		def currencies
			@db.js('peeps.all_currencies()')
		end

		def set_password(newpass)
			@db.js('peeps.set_password($1, $2)', [@person_id, newpass])
		end

		def get_worker
			@mw.get_worker(@worker_id)
		end

		def update(params)
			params.delete :person_id
			@mw.update_worker(@worker_id, params)
		end

		def get_tasks
			@mw.worker_get_tasks(@worker_id)
		end

		def grouped_tasks
			group = {}
			@mw.worker_get_tasks(@worker_id).each do |t|
				group[t[:status]] ||= []
				group[t[:status]] << t
			end
			group
		end

		def get_task(task_id)
			return false unless @mw.worker_owns_task(@worker_id, task_id)
			@mw.get_task(task_id)
		end

		def claim_task(task_id)
			@mw.claim_task(task_id, @worker_id)
		end

		def unclaim_task(task_id)
			return false unless @mw.worker_owns_task(@worker_id, task_id)
			@mw.unclaim_task(task_id)
		end

		def start_task(task_id)
			return false unless @mw.worker_owns_task(@worker_id, task_id)
			@mw.start_task(task_id)
		end

		def finish_task(task_id)
			return false unless @mw.worker_owns_task(@worker_id, task_id)
			@mw.finish_task(task_id)
		end

		def next_available_tasks
			@db.js('muckwork.next_available_tasks()')
		end
	end
end

