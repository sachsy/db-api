require_relative 'dbapi.rb'

# @mt = B50D::MusicThoughts.new  (default English)
# t = @mt.thought(123)
# puts t[:thought]   # "Hi this is English"
# @mt.set_lang('fr')
# t = @mt.thought(123)
# puts t[:thought]   # "Bonjour, c'est français"

module B50D
	class MusicThoughts
		def error ; @db.error ; end
		def message ; @db.message ; end

		def initialize(server='live', lang='en')
			@db = DbAPI.new(server)
			set_lang(lang)
		end

		def languages
			return ['ar', 'de', 'en', 'es', 'fr', 'it', 'ja', 'pt', 'ru', 'zh']
		end

		# restricts responses to this language
		def set_lang(lang)
			lang = 'en' unless languages.include? lang
			@lang = lang
		end

		# hash keys: id, category, howmany
		def categories
			@db.js('musicthoughts.all_categories($1)', [@lang])
		end

		# hash keys: id, category, thoughts:[{id, thought, author:{id, name}}]
		def category(id)
			return false unless id.instance_of? Fixnum || /\A[0-9]+\Z/ === id
			@db.js('musicthoughts.category($1, $2)', [@lang, id])
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
		def author(id)
			return false unless id.instance_of? Fixnum || /\A[0-9]+\Z/ === id
			@db.js('musicthoughts.get_author($1, $2)', [@lang, id])
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
		def contributor(id)
			return false unless id.instance_of? Fixnum || /\A[0-9]+\Z/ === id
			@db.js('musicthoughts.get_contributor($1, $2)', [@lang, id])
		end

		# Format for all thought methods, below:
		# hash keys: id, source_url, thought,
		#   author:{id, name}, contributor:{id, name}, categories:[{id, category}]
		def thoughts_all
			@db.js('musicthoughts.new_thoughts($1, NULL)', [@lang])
		end

		def thoughts_new
			@db.js('musicthoughts.new_thoughts($1, $2)', [@lang, 20])
		end

		def thought(id)
			return false unless id.instance_of? Fixnum || /\A[0-9]+\Z/ === id
			@db.js('musicthoughts.get_thought($1, $2)', [@lang, id])
		end

		def thought_random
			@db.js('musicthoughts.random_thought($1)', [@lang])
		end

		# hash keys:
		#  categories: nil || [{id, category]
		#  authors: nil || [{id, name, howmany}]
		#  contributors: nil || [{id, name, howmany}]
		#  thoughts: nil || [{id, source_url, thought,
		#   author:{id, name}, contributor:{id, name}, categories:[{id, category}]}]
		def search(q)
			@db.js('musicthoughts.search($1, $2)', [@lang, q.strip])
		end 


		def add(params)
			%i(thought contributor_name contributor_email author_name).each do |i|
				raise "#{i} required" unless String(params[i]).size > 0
			end
			params[:lang_code] ||= @lang
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

