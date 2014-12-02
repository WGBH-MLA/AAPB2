require 'curb'

puts '*** Issues GET and then POST? ***'
Curl::Easy.http_post('http://example.com') do |c|
  c.verbose = true
  c.perform
end

puts '*** Issues GET and then PUT? ***'
Curl::Easy.http_put('http://example.com', 'some data to PUT') do |c|
  c.verbose = true
  c.perform
end