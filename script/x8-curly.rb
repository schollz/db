#!/usr/bin/env ruby
require 'pg'
DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

def curlquotes(str)
	newstr = ''
	inside = false
	str.each_char do |c|
		if c == '"'
			newstr << (inside ? '”' : '“')
			inside = !inside
		else
			newstr << c
		end
	end
	newstr
end

bothcurl = %r(“.+”)

def ncurl(str)
	str.scan(/[“”]/).size
end

def nstraight(str)
	str.scan('"').size
end

def update(id, newtr)
	DB.exec_params("UPDATE words.translations SET translation = $1 WHERE id = $2", [newtr, id])
end

res = DB.exec(%q(SELECT id, sentence_code, sentence, translation FROM words.translations t JOIN words.sentences s ON t.sentence_code=s.code WHERE id > 4400 AND translation LIKE '%"%' ORDER BY lang, id))
res.each do |row|
	# if match, just do it.
	if (nstraight(row['translation']) == ncurl(row['sentence'])) && (bothcurl === row['sentence'])
		update(row['id'], curlquotes(row['translation']))
	else
		puts row['sentence']
		puts row['translation']
		puts '== %d quotes' % nstraight(row['translation'])
		puts 'https://inbox.sivers.org/translation/%d' % row['id']
		puts '1. curl them'
		puts '2. make closing'
		puts '3. make opening'
		puts '4. nothing'
		print "CHOICE? "
		choice = STDIN.gets.to_i
		case choice
		when 1
			nu = curlquotes(row['translation'])
		when 2
			nu = row['translation'].gsub('"', '”')
		when 3
			nu = row['translation'].gsub('"', '“')
		else
			nu = nil
		end
		if nu
			puts "-------------\n%s\n-------------" % nu
			print "YEAH? (y/n) "
			if STDIN.gets.strip == 'y'
				update(row['id'], nu)
			end
		end
	end
end

# some have only closing quote!
# look at original sentence to figure out what to replace them with
# if has 2 or 4, just replace
# if not match, leave it and look later by hand

