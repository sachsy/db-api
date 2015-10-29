#!/usr/bin/env ruby
require 'pg'
require 'net/http'

DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

res = DB.exec("SELECT id, short FROM now.urls WHERE updated_at IS NULL")

res.each do |r|
	id = r['id'].to_i
	u = r['short']
	puts u
	url = 'http://' + u
	res = Net::HTTP.get_response(URI(url))
	if res.code == '200'
		DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
	elsif %w(301 302).include? res.code
		if res['location'].start_with? 'http'
			url = res['location'].gsub('blogspot.co.nz', 'blogspot.com')
		else
			url = 'http://' + URI(url).host + res['location']
		end
		DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
	elsif res.code == '404'
		print "404....\t"
		url = 'http://www.' + u
		res = Net::HTTP.get_response(URI(url))
		if res.code == '200'
			DB.exec_params("UPDATE now.urls SET long=$1, updated_at=NOW() WHERE id=$2", [url, id])
		else
			puts res.inspect
		end
	else
		puts res.inspect
	end
end

