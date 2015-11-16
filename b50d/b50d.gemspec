Gem::Specification.new do |s|
  s.platform	= Gem::Platform::RUBY
  s.name        = 'b50d'
  s.version     = '5.3.1'
  s.date        = '2015-11-16'
  s.author      = 'Derek Sivers'
  s.email       = 'derek@sivers.org'
  s.license     = 'CC BY-NC'
  s.homepage    = 'https://github.com/50pop/db-api'
  s.summary     = 'Ruby scripts and libs to access the PostgreSQL APIs.'
  s.description = 'Ruby scripts and libs to access the PostgreSQL APIs in db-api.'
  s.files       =  Dir['lib/b50d/*'] + Dir['bin/*'] + ['b50d.gemspec','b50d-config.rb.sample']
  s.executables = ['eeps', 'impeema', 'send_queue', 'woodegg-proofs', 'lat', 'twitter-follow', 'currency-update', 'gengo-get', 'gengo-post', 'nownownow-tweet']
end

