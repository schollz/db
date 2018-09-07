#!/usr/local/bin/ruby

unless ARGV[0] && File.exist?(ARGV[0])
	raise 'needs filename after'
end

message_id = %r{.([0-9]+)@sivers.org}
list_url = %r{/([0-9]+)/}
sql_id = "SELECT * FROM peeps.dead_email(%d);"
sql_em = "SELECT * FROM peeps.dead_email('%s');"

File.readlines(ARGV[0]).each do |line|
	line.strip!
	next if line == ''
	if message_id === line
		puts sql_id % $1
	elsif list_url === line
		puts sql_id % $1
	elsif line.include?('@')
		puts sql_em % line.downcase
	else
		raise line
	end
end
