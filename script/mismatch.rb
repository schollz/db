require 'pg'
require 'json'

# for translators that messed up the <> tags in their translation
# go through each
# get article_id from sentences.code
# make https://tr.sivers.org/article/#{article_id} URL
# get person_id from translator_id
# save it in array by translator, with sentence and translation
# create the body of an email I'll send them
# WHEN DONE: null the translated_at and review1_at for these translations.id

db = PG::Connection.new(host: 'localhost', port: 5433, dbname: 'd50b', user: 'd50b')
res = db.exec("SELECT js FROM words.mismatched_tags()")
js = JSON.parse(res[0]['js'], symbolize_names: true)
puts "%d FOUND" % js.size
peeps = {}
trids = []
js.each do |j|
	puts j[:code]
	trids << j[:id].to_s
	# id, code, sentence, translation, lang, translated_by, review1_by
	res = db.exec("SELECT article_id FROM words.sentences WHERE code='#{j[:code]}'")
	article_id = res[0]['article_id']
	res = db.exec("SELECT person_id FROM words.translators WHERE id=#{j[:translated_by]}")
	person_id = res[0]['person_id']
	peeps[person_id] ||= []
	peeps[person_id] << {
		url: ('https://tr.sivers.org/article/%d' % article_id),
		sentence: j[:sentence],
		xion: j[:translation]}
end

peeps.each_pair do |person_id, stuffs|
	body = "So sorry, but I need your help to fix these translations that are missing the < and > tags. I wish I could do it myself, but I can't.\n\nHere are the exact links to click to get to the article, then look for these sentences in the article and click the little 'edit' link that should be to the right of each sentence on the page.\n\nPlease just try to add the < and > brackets around your words that have the similar meaning as what they wrap in my original.\n\n"
	stuffs.each do |stuff|
		body << "%s\n%s\n%s\n\n" % [stuff[:url], stuff[:sentence], stuff[:xion]]
	end
	# "emailer_id", "person_id", "profile", "subject", "body"
	puts "https://inbox.sivers.org/person/#{person_id}"
	db.exec_params("SELECT * FROM peeps.new_email(1, $1, 'sivers', 'fixing < and > in translation', $2)", [person_id, body])
end

outfile = '/tmp/e.sql'
File.open(outfile, 'w') do |f|
	f.puts "UPDATE words.translations SET translated_at = NULL, review1_at = NULL WHERE id IN ("
	f.puts trids.join(',')
	f.puts ");"
end
puts "see #{outfile}"

