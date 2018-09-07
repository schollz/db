require 'pg'
DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

res = DB.exec("SELECT DISTINCT(person_id) FROM words.candidates ORDER BY person_id")
ids = res.map {|r| r['person_id']}
sql = "SELECT DISTINCT(person_id) FROM peeps.emails WHERE outgoing IS FALSE AND created_at >= '2018-06-14' AND person_id IN (%s)" % ids.join(',')
res = DB.exec(sql)
res.each do |r|
	DB.exec("UPDATE words.candidates SET has_emailed = TRUE WHERE person_id = %d" % r['person_id'])
end
