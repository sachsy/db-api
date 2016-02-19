#!/usr/bin/env ruby
# USAGE ./parse.rb peeps.txt
# CREATES peeps.ngx + peeps.exs

infile = ARGV[0] || raise('needs filename after')

methods = %w(GET PUT POST DELETE)

routes = []

lines = File.readlines(infile).map(&:strip)
startline = 0
endline = lines.size

while startline < endline
	route = {}
	bits = lines[startline].split("\t")
	route[:method] = bits.shift
	raise 'done' unless methods.include? route[:method]
	route[:regex] = bits.shift
	if p = bits.shift
		route[:params] = p[1...-1].split(',')
	end
	bits = lines[startline + 1]
	route[:args] = bits.split(', ') unless bits == '_'
	route[:function] = lines[startline + 2]
	routes << route
	startline = startline + 4
end

puts routes
