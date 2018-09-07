require '../test_tools.rb'

class WordsTest < Minitest::Test
	include JDB

	def setup
		@raw = "<!-- This is a title -->\r\n<p>\r\n\tAnd this?\r\n\tThis is a translation.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a translation.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

#########################################
########################## TEST TRIGGERS:
#########################################

	def test_clean_raw
		res = DB.exec_params("INSERT INTO words.articles(filename, raw) VALUES ('x', $1) RETURNING *", [@raw])
		assert_equal @raw.gsub("\r", ''), res[0]['raw']
	end

	def test_sentences_code_gen
		res = DB.exec("INSERT INTO words.sentences(sentence) VALUES ('hello') RETURNING code")
		hellocode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hellocode
		res = DB.exec("INSERT INTO words.sentences(sentence) VALUES ('hi') RETURNING code")
		hicode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hicode
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hellocode)
		assert_equal 'hello', res[0]['sentence']
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hicode)
		assert_equal 'hi', res[0]['sentence']
	end

	def test_make_replacements
		res = DB.exec("INSERT INTO words.sentences(sentence) VALUES ('a <strong>b</strong> c') RETURNING *")
		assert_equal 'a <b> c', res[0]['sentence']
		assert_equal '{<strong>,</strong>}', res[0]['replacements']
	end

	def test_clean_xion
		res = DB.exec("UPDATE words.translations SET translation = $1 WHERE id = 17 RETURNING *",
			["\t \r \nhi \t \r \n "])
		assert_equal 'hi', res[0]['translation']
	end


#########################################
######################### TEST FUNCTIONS:
#########################################

	def test_parse_article
		res = DB.exec_params("INSERT INTO words.articles(filename, raw) VALUES ($1, $2) RETURNING id",
			['this.txt', @raw])
		id = res[0]['id'].to_i
		DB.exec("SELECT * FROM words.parse_article(#{id})")
		res = DB.exec("SELECT * FROM words.sentences WHERE article_id = #{id}")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal '1', res[0]['sortid']
		assert_equal @lines[0], res[0]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal '2', res[1]['sortid']
		assert_equal @lines[1], res[1]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal '3', res[2]['sortid']
		assert_equal @lines[2], res[2]['sentence']
		res = DB.exec("SELECT template FROM words.articles WHERE id = #{id}")
		assert_match /<!-- \{[A-Za-z0-9]{8}\} -->\n<p>\n\{[A-Za-z0-9]{8}\}\n\{[A-Za-z0-9]{8}\}\n<\/p>/, res[0]['template']
	end

	def test_tags_match_replacements
		DB.exec("INSERT INTO words.sentences(sentence) VALUES('should make empty replacements array')")
		few = DB.exec("SELECT code, words.tags_match_replacements(sentence, replacements) AS ok FROM words.sentences ORDER BY code")
		few.each do |row|
			assert_equal 't', row['ok']
		end
		DB.exec("UPDATE words.sentences SET sentence='<' WHERE code='aaaaaaaa'")
		res = DB.exec("SELECT words.tags_match_replacements(sentence, replacements) AS ok FROM words.sentences WHERE code='aaaaaaaa'")
		assert_equal 'f', res[0]['ok']
		DB.exec("UPDATE words.sentences SET sentence='<' WHERE code='aaaaaaab'")
		res = DB.exec("SELECT words.tags_match_replacements(sentence, replacements) AS ok FROM words.sentences WHERE code='aaaaaaab'")
		assert_equal 'f', res[0]['ok']
		DB.exec("UPDATE words.sentences SET sentence='<>' WHERE code='aaaaaaab'")
		res = DB.exec("SELECT words.tags_match_replacements(sentence, replacements) AS ok FROM words.sentences WHERE code='aaaaaaab'")
		assert_equal 't', res[0]['ok']
	end

	def test_merge_replacements
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', ARRAY['<b>','</b>'])")
		assert_equal 'oh, <b>ok</b>!', res[0]['merged']
		# if more tags than replacements, replaces with empty:
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', '{}')")
		assert_equal 'oh, ok!', res[0]['merged']
		# if more replacements than tags, adds them to end! (should never happen)
		res = DB.exec("SELECT merged FROM words.merge_replacements('oh, <ok>!', ARRAY['<b>','</b>','<i>','</i>'])")
		assert_equal 'oh, <b>ok</b>!<i></i>', res[0]['merged']
	end

	def test_merge_article
		res = DB.exec("SELECT merged FROM words.merge_article(1, 'fr')")
		assert_equal res[0]['merged'], '<!-- titre ici -->
<p>
	quelques <strong>mots en gras</strong>
	maintenant <a href="/">liés et mots <em>italiques</em></a>
	voir <a href="/about">à ce</a> <a href="/">sujet</a>
</p>'
		# English merged should be same as raw
		res = DB.exec("SELECT raw FROM words.articles WHERE id=1")
		raw = res[0]['raw']
		res = DB.exec("SELECT merged FROM words.merge_article(1, 'en')")
		merged = res[0]['merged']
		assert_equal raw, merged
	end

	def test_init_collection_lang
		res = DB.exec("SELECT * FROM words.init_collection_lang(1, 'zu') x")
		assert_equal %w(40 41 42 43 44 45), res.map {|x| x['x']}
		res = DB.exec("SELECT sentence_code FROM words.translations WHERE lang='zu' ORDER BY id")
		assert_equal %w(aaaaaaaa aaaaaaab aaaaaaac aaaaaaad bbbbbbbb bbbbbbbc), res.map {|x| x['sentence_code']}
		res = DB.exec("SELECT * FROM words.init_collection_lang(1, 'zu') x")
		assert_equal %w(40 41 42 43 44 45), res.map {|x| x['x']}
	end

	def test_xor_collection_role
		res = DB.exec("SELECT * FROM words.xor_collection_role(1, 1)")
		assert_equal '1', res[0]['xor_collection_role']
		res = DB.exec("SELECT * FROM words.xor_collection_role(2, 1)")
		assert_equal '2', res[0]['xor_collection_role']
		res = DB.exec("SELECT * FROM words.xor_collection_role(1, 2)")
		assert_nil res[0]['xor_collection_role']
	end

	def test_xor_article_role
		res = DB.exec("SELECT * FROM words.xor_article_role(1, 1)")
		assert_equal '1', res[0]['xor_article_role']
		res = DB.exec("SELECT * FROM words.xor_article_role(2, 1)")
		assert_equal '2', res[0]['xor_article_role']
		res = DB.exec("SELECT * FROM words.xor_article_role(1, 3)")
		assert_nil res[0]['xor_article_role']
	end

	def test_xor_xion_role
		res = DB.exec("SELECT * FROM words.xor_xion_role(1, 1)")
		assert_nil res[0]['xor_xion_role']
		res = DB.exec("SELECT * FROM words.xor_xion_role(5, 1)")
		assert_equal '1', res[0]['xor_xion_role']
		res = DB.exec("SELECT * FROM words.xor_xion_role(2, 4)")
		assert_equal '2', res[0]['xor_xion_role']
	end

	def test_xor_do
		res = DB.exec("SELECT * FROM words.xor_do(1)")
		assert_equal ['21'], res.map {|x| x['xor_do']}
		res = DB.exec("SELECT * FROM words.xor_do(2)")
		assert_equal ['16'], res.map {|x| x['xor_do']}
	end

	def test_xor_claim
		res = DB.exec("SELECT * FROM words.xor_claim(1)")
		assert_equal [], res.map {|x| x['xor_claim']}
		res = DB.exec("SELECT * FROM words.xor_claim(2)")
		assert_equal ['20'], res.map {|x| x['xor_claim']}
	end

	def test_xor_wait
		res = DB.exec("SELECT * FROM words.xor_wait(1)")
		assert_equal [], res.map {|x| x['xor_wait']}
		res = DB.exec("SELECT * FROM words.xor_wait(6)")
		assert_equal ['15'], res.map {|x| x['xor_wait']}
	end

	def test_xor_done
		res = DB.exec("SELECT * FROM words.xor_done(1)")
		assert_equal %w(4 8 12 16 20), res.map {|x| x['xor_done']}
		res = DB.exec("SELECT * FROM words.xor_done(2)")
		assert_equal %w(4 8 12), res.map {|x| x['xor_done']}
	end

	def test_articles_xor_state
		res = DB.exec("SELECT * FROM words.articles_xor_state(1, 'done')")
		assert_equal %w(1), res.map {|x| x['articles_xor_state']}
		res = DB.exec("SELECT * FROM words.articles_xor_state(1, 'do')")
		assert_equal %w(2), res.map {|x| x['articles_xor_state']}
		res = DB.exec("SELECT * FROM words.articles_xor_state(1, 'claim')")
		assert_equal [], res.map {|x| x['articles_xor_state']}
		res = DB.exec("SELECT * FROM words.articles_xor_state(4, 'done')")
		assert_equal %w(1), res.map {|x| x['articles_xor_state']}
		res = DB.exec("SELECT * FROM words.articles_xor_state(4, 'do')")
		assert_equal [], res.map {|x| x['articles_xor_state']}
		res = DB.exec("SELECT * FROM words.articles_xor_state(4, 'claim')")
		assert_equal %w(2), res.map {|x| x['articles_xor_state']}
	end

	def test_tids_for_article_xor
		res = DB.exec("SELECT x FROM words.tids_for_article_xor(1, 1) x")
		assert_equal %w(4 8 12 16), res.map {|x| x['x']}
		res = DB.exec("SELECT x FROM words.tids_for_article_xor(1, 7) x")
		assert_equal %w(25 26 27 28), res.map {|x| x['x']}
	end

	def test_article_for_xion
		(1..24).each do |i|
			res = DB.exec("SELECT words.article_for_xion(#{i})")
			if i < 17
				assert_equal 1, res[0]['article_for_xion'].to_i
			else
				assert_equal 2, res[0]['article_for_xion'].to_i
			end
		end
	end

	def test_xor_article_state
		res = DB.exec("SELECT * FROM words.xor_article_state(1, 1) s")
		assert_equal 'done', res[0]['s']
		res = DB.exec("SELECT * FROM words.xor_article_state(1, 2) s")
		assert_equal 'some', res[0]['s']
		res = DB.exec("SELECT * FROM words.xor_article_state(2, 2) s")
		assert_equal 'none', res[0]['s']
		res = DB.exec("SELECT * FROM words.xor_article_state(2, 3) s")
		assert_nil res[0]['s']
		res = DB.exec("SELECT * FROM words.xor_article_state(99, 1) s")
		assert_nil res[0]['s']
		DB.exec("SELECT * FROM words.xor_claim_article(7, 1) s")
		res = DB.exec("SELECT * FROM words.xor_article_state(7, 1) s")
		assert_equal 'gogo', res[0]['s']
		DB.exec("UPDATE words.translations SET review1_by=1 WHERE lang='zh' AND review1_by IS NULL")
		res = DB.exec("SELECT * FROM words.xor_article_state(2, 2) s")
		assert_equal 'gone', res[0]['s']
	end

	# asking a question about an article should put it in a "wait" status
	# they should be able to claim a new article despite one being in "wait"
	def test_question_status
		# ja translator can claim article 1 or 2
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'claim') x")
		assert_equal [1,2], res.map {|x| x['x'].to_i}
		# ja translator claims article 1
		DB.exec("SELECT * FROM words.xor_claim_article(7, 1)")
		# now only article 1 in do state
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'do') x")
		assert_equal [1], res.map {|x| x['x'].to_i}
		# now only article 2 in claim state
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'claim') x")
		assert_equal [2], res.map {|x| x['x'].to_i}
		# but she can not claim 2 because 1 is "do"
		res = DB.exec("SELECT * FROM words.xor_claim_article(7, 2)")
		assert_equal '500', res[0]['status']
		# now she asks a question about tr.25 in art.1
		res = DB.exec("SELECT * FROM words.ask_question(7, 25, 'yes?')")
		# that puts article 1 into "wait" status
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'wait') x")
		assert_equal [1], res.map {|x| x['x'].to_i}
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'do') x")
		assert_equal [], res.map {|x| x['x']}
		# which means now she can claim article 2
		res = DB.exec("SELECT * FROM words.xor_claim_article(7, 2)")
		assert_equal '200', res[0]['status']
		# but once I answer it, article 1 is back in "do" status, along with 2
		res = DB.exec("SELECT * FROM words.answer_question(2, 'yep')")
		assert_equal '200', res[0]['status']
		res = DB.exec("SELECT * FROM words.articles_xor_state(7, 'do') x")
		assert_equal [1,2], res.map {|x| x['x'].to_i}
	end

end

