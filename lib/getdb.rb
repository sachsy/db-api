# USAGE
# require 'getdb'
# db = getdb('peeps')
# ok, res = db.call('get_stats', 'programmer', 'elm')
# ok, res = db.call('update_person', 1, {email: 'boo'}.to_json)
# if ok
# 	puts "worked! #{res.inspect}"
# else
# 	puts "failed: #{res.inspect}"
# end
require 'pg'
require 'json'

# ONLY USE THIS: Curry calldb with a DB connection & schema
def getdb(schema, server='live')
	Proc.new do |func, *params|
		okres(calldb(PGPool.get(server), schema, func, params))
	end
end

# ALTERNATE: when I don't want to auto-prefix a schema
def getdb_noschema(server='live')
	Proc.new do |fullfunc, *params|
		okres(calldb_noschema(PGPool.get(server), fullfunc, params))
	end
end

# INPUT: result of pg.exec_params
# OUTPUT: [boolean, hash] where hash is JSON of response or problem
def okres(res)
	js = JSON.parse(res[0]['js'], symbolize_names: true)
	ok = (res[0]['status'] == '200')
	# previous transform of js if not ok: {error: js[:title], message: js[:detail]}
	# TODO: if not 200 then return status in JSON?
	[ok, js]
end

# return params string for PostgreSQL exec_params
# INPUT: [list, of, things]
# OUTPUT "($1,$2,$3)"
def paramstring(params)
	'(%s)' % (1..params.size).map {|i| "$#{i}"}.join(',')
end

# The real functional function we're going to curry, below
# INPUT: PostgreSQL connection, schema string, function string, params array
def calldb(pg, schema, func, params)
	pg.exec_params('SELECT status, js FROM %s.%s%s' %
		[schema, func, paramstring(params)], params)
end

def calldb_noschema(pg, fullfunc, params)
	pg.exec_params('SELECT status, js FROM %s%s' %
		[fullfunc, paramstring(params)], params)
end

# was a pool, but getting "too many connection" errors, so now just use one:
class PGPool
	class << self
		def get(live_or_test='live')
			dbname = ('test' == live_or_test) ? 'd50b_test' : 'd50b'
			@@conn ||= PG::Connection.new(dbname: dbname, user: 'd50b')
			@@conn
		end
	end
end

