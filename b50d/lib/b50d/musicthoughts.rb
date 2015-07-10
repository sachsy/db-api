require_relative 'dbapi.rb'

module B50D
	class MusicThoughts
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(server='live')
			@db = DbAPI.new(server)
		end

		def languages
			return ['ar', 'de', 'en', 'es', 'fr', 'it', 'ja', 'pt', 'ru', 'zh']
		end

		# hash keys: id, category, howmany
		def categories(lang)
			@db.js('musicthoughts.all_categories($1)', [lang])
		end

		# hash keys: id, category, thoughts:[{id, thought, author:{id, name}}]
		def category(lang, id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('musicthoughts.category($1, $2)', [lang, id])
		end

		# hash keys: id, name, howmany
		def authors
			@db.js('musicthoughts.top_authors(NULL)')
		end

		# hash keys: id, name, howmany
		def authors_top
			@db.js('musicthoughts.top_authors($1)', [20])
		end

		# hash keys: id, name, thoughts:[{id, thought, author:{id, name}}]
		def author(lang, id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('musicthoughts.get_author($1, $2)', [lang, id])
		end

		# hash keys: id, name, howmany
		def contributors
			@db.js('musicthoughts.top_contributors(NULL)')
		end

		# hash keys: id, name, howmany
		def contributors_top
			@db.js('musicthoughts.top_contributors($1)', [20])
		end

		# hash keys: id, name, thoughts:[{id, thought, author:{id, name}}]
		def contributor(lang, id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('musicthoughts.get_contributor($1, $2)', [lang, id])
		end

		# Format for all thought methods, below:
		# hash keys: id, source_url, thought,
		#   author:{id, name}, contributor:{id, name}, categories:[{id, category}]
		def thoughts_all(lang)
			@db.js('musicthoughts.new_thoughts($1, NULL)', [lang])
		end

		def thoughts_new(lang)
			@db.js('musicthoughts.new_thoughts($1, $2)', [lang, 20])
		end

		def thought(lang, id)
			return false unless /\A[0-9]+\Z/ === String(id)
			@db.js('musicthoughts.get_thought($1, $2)', [lang, id])
		end

		def thought_random(lang)
			@db.js('musicthoughts.random_thought($1)', [lang])
		end

		# hash keys:
		#  categories: nil || [{id, category]
		#  authors: nil || [{id, name, howmany}]
		#  contributors: nil || [{id, name, howmany}]
		#  thoughts: nil || [{id, source_url, thought,
		#   author:{id, name}, contributor:{id, name}, categories:[{id, category}]}]
		def search(lang, q)
			@db.js('musicthoughts.search($1, $2)', [lang, q.strip])
		end 


		def add(lang, params)
			%i(thought contributor_name contributor_email author_name).each do |i|
				raise "#{i} required" unless String(params[i]).size > 0
			end
			params[:lang_code] ||= lang
			params[:contributor_url] ||= ''
			params[:contributor_place] ||= ''
			params[:source_url] ||= ''
			params[:category_ids] ||= '{}' # format: {1,3,5}
			@db.js('musicthoughts.add_thought($1, $2, $3, $4, $5, $6, $7, $8, $9)', [
				params[:lang_code],
				params[:thought],
				params[:contributor_name],
				params[:contributor_email],
				params[:contributor_url],
				params[:contributor_place],
				params[:author_name],
				params[:source_url],
				params[:category_ids]])
		end
	end
end

