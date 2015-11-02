#!/usr/bin/env ruby
exit unless 'sivers.org' == %x{hostname}.strip
require 'pstore'
require 'pg'
require 'nownownow-config.rb'
require 'twitter'

DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

logfile = '/var/www/tiny/nowtweets.pstore'
ps = PStore.new(logfile)

unless File.exist?(logfile)
	ps.transaction do
		ps[:log] = []
		ps[:log] << {id: 155, url: 'http://sivers.org/now', when: '2015-11-01 18:56:57 -0800'}
	end
end

def get_url
	res = DB.exec('SELECT id, long FROM now.urls WHERE long IS NOT NULL ORDER BY RANDOM() LIMIT 1')
	[res[0]['id'].to_i, res[0]['long']]
end

ps.transaction do
	begin
		id, url = get_url
	end while (ps[:log].map {|x| x[:id]}.include? id)
	tw = Twitter::REST::Client.new do |config|
		config.consumer_key = TWITTER_CONSUMER_KEY
		config.consumer_secret = TWITTER_CONSUMER_SECRET
		config.access_token = TWITTER_ACCESS_TOKEN
		config.access_token_secret = TWITTER_ACCESS_SECRET
	end
	tw.update url
	ps[:log] << {id: id, url: url, when: Time.now()}
end

__END__
ps.transaction(true) do
	puts "HISTORY:"
	ps[:log].each do |x|
		puts "%d\t%s\t%s" % [x[:id], x[:when], x[:url]]
	end
end
