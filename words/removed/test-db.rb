require '../test_tools.rb'

class WordsTest < Minitest::Test
	include JDB

	def setup
		@raw = "<!-- This is a title -->\r\n<p>\r\n\tAnd this?\r\n\tThis is a translation.\r\n</p>"
		@lines = ['This is a title', 'And this?', 'This is a translation.']
		@fr = ['Ceci est un titre', 'Et ça?', 'Ceci est une phrase.']
		super
	end

	def test_clean_translation
		DB.exec("UPDATE words.translations SET translation = $1 WHERE id = 17", ["\t \r \nhi \t \r \n "])
		res = DB.exec("SELECT translation FROM words.translations WHERE id = 17")
		assert_equal 'hi', res[0]['translation']
	end

	def test_code
		res = DB.exec("INSERT INTO words.sentences (sentence) VALUES ('hello') RETURNING code")
		hellocode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hellocode
		res = DB.exec("INSERT INTO words.sentences (sentence) VALUES ('hi') RETURNING code")
		hicode = res[0]['code']
		assert_match /[A-Za-z0-9]{8}/, hicode
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hellocode)
		assert_equal 'hello', res[0]['sentence']
		res = DB.exec("SELECT sentence FROM words.sentences WHERE code = '%s'" % hicode)
		assert_equal 'hi', res[0]['sentence']
	end

	def test_make_replacements
		res = DB.exec("INSERT INTO words.sentences (sentence) VALUES ('a <strong>b</strong> c') RETURNING code")
		code = res[0]['code']
		res = DB.exec("SELECT sentence, replacements FROM words.sentences WHERE code = '#{code}'")
		assert_equal 'a <b> c', res[0]['sentence']
		assert_equal '{<strong>,</strong>}', res[0]['replacements']
	end

	def test_parse_article
		DB.exec_params("INSERT INTO words.articles(filename, raw) VALUES ($1, $2)", ['this.txt', @raw])
		DB.exec("SELECT * FROM words.parse_article(3)")
		res = DB.exec("SELECT * FROM words.sentences WHERE article_id = 3")
		assert_match /[A-Za-z0-9]{8}/, res[0]['code']
		assert_equal '1', res[0]['sortid']
		assert_equal @lines[0], res[0]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[1]['code']
		assert_equal '2', res[1]['sortid']
		assert_equal @lines[1], res[1]['sentence']
		assert_match /[A-Za-z0-9]{8}/, res[2]['code']
		assert_equal '3', res[2]['sortid']
		assert_equal @lines[2], res[2]['sentence']
		res = DB.exec("SELECT template FROM words.articles WHERE id = 3")
		assert_match /<!-- \{[A-Za-z0-9]{8}\} -->\n<p>\n\{[A-Za-z0-9]{8}\}\n\{[A-Za-z0-9]{8}\}\n<\/p>/, res[0]['template']
	end

	def test_tags_match_replacements
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

	def test_article_array_state
		res = DB.exec("SELECT * FROM words.article_array_state('{new}')")
		assert_equal res[0]['stat'], 'new'
		res = DB.exec("SELECT * FROM words.article_array_state('{new,wait}')")
		assert_equal res[0]['stat'], 'wait'
		res = DB.exec("SELECT * FROM words.article_array_state('{new,review}')")
		assert_equal res[0]['stat'], 'started'
		res = DB.exec("SELECT * FROM words.article_array_state('{review}')")
		assert_equal res[0]['stat'], 'review'
		res = DB.exec("SELECT * FROM words.article_array_state('{done}')")
		assert_equal res[0]['stat'], 'done'
		res = DB.exec("SELECT * FROM words.article_array_state('{done,wait}')")
		assert_equal res[0]['stat'], 'wait'
		res = DB.exec("SELECT * FROM words.article_array_state('{done,review}')")
		assert_equal res[0]['stat'], 'reviewing'
		res = DB.exec("SELECT * FROM words.article_array_state('{review,wait}')")
		assert_equal res[0]['stat'], 'wait'
	end

	def test_article_state
		res = DB.exec("SELECT stat FROM words.article_state(1, 'es')")
		assert_equal res[0]['stat'], 'review'
		res = DB.exec("SELECT stat FROM words.article_state(1, 'fr')")
		assert_equal res[0]['stat'], 'done'
		res = DB.exec("SELECT stat FROM words.article_state(1, 'pt')")
		assert_equal res[0]['stat'], 'wait'
		res = DB.exec("SELECT stat FROM words.article_state(1, 'zh')")
		assert_equal res[0]['stat'], 'reviewing'
	end

	def test_translator_art_state
		res = DB.exec("SELECT article_id, stat FROM words.translator_art_state(1)")
		assert_equal res[0]['article_id'].to_i, 1
		assert_equal res[0]['stat'], 'done'
		assert_equal res[1]['article_id'].to_i, 2
		assert_equal res[1]['stat'], 'do'
		res = DB.exec("SELECT article_id, stat FROM words.translator_art_state(3)")
		assert_equal res[0]['article_id'].to_i, 1
		assert_equal res[0]['stat'], 'done'
		assert_equal res[1]['article_id'].to_i, 2
		assert_equal res[1]['stat'], 'doing'
	end

	def test_role_state
		assert_equal 'wait', DB.exec("SELECT * FROM words.role_state('1st', 'wait')")[0]['role_state']
		assert_equal 'do', DB.exec("SELECT * FROM words.role_state('1st', 'new')")[0]['role_state']
		assert_equal 'doing', DB.exec("SELECT * FROM words.role_state('1st', 'started')")[0]['role_state']
		assert_equal 'done', DB.exec("SELECT * FROM words.role_state('1st', 'review')")[0]['role_state']
		assert_equal 'done', DB.exec("SELECT * FROM words.role_state('1st', 'reviewing')")[0]['role_state']
		assert_equal 'done', DB.exec("SELECT * FROM words.role_state('1st', 'done')")[0]['role_state']
		assert_equal 'wait', DB.exec("SELECT * FROM words.role_state('2nd', 'wait')")[0]['role_state']
		assert_equal 'wait', DB.exec("SELECT * FROM words.role_state('2nd', 'new')")[0]['role_state']
		assert_equal 'wait', DB.exec("SELECT * FROM words.role_state('2nd', 'started')")[0]['role_state']
		assert_equal 'do', DB.exec("SELECT * FROM words.role_state('2nd', 'review')")[0]['role_state']
		assert_equal 'doing', DB.exec("SELECT * FROM words.role_state('2nd', 'reviewing')")[0]['role_state']
		assert_equal 'done', DB.exec("SELECT * FROM words.role_state('2nd', 'done')")[0]['role_state']
	end

	def test_article_lang_done
		res = DB.exec("SELECT * FROM words.article_lang_done(1, 'es')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(1, 'fr')")
		assert_equal res[0]['article_lang_done'], 't' # only one done
		res = DB.exec("SELECT * FROM words.article_lang_done(1, 'pt')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(1, 'zh')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(2, 'es')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(2, 'fr')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(2, 'pt')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(2, 'zh')")
		assert_equal res[0]['article_lang_done'], 'f'
		res = DB.exec("SELECT * FROM words.article_lang_done(1, 'ja')")
		assert_equal res[0]['article_lang_done'], 'f' # lang not exists = not done
		res = DB.exec("SELECT * FROM words.article_lang_done(99, 'zh')")
		assert_equal res[0]['article_lang_done'], 't' # article not exists = done
	end

	def test_translator_translation_ok
		# translator 1 = 1st zh : can do 20 + 21
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(1, 20) AS x")[0]['x']
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(1, 21) AS x")[0]['x']
		# translator 2 = 2nd zh : can do 16
		assert_equal 'done', DB.exec("SELECT x FROM words.translator_translation_ok(2, 16) AS x")[0]['x']
		# translator 3 = 1st fr : can do 23
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(3, 23) AS x")[0]['x']
		# translator 4 = 2nd fr : hasn't been assigned anything yet
		# translator 5 = 1st es : can do 17 & 22
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(5, 17) AS x")[0]['x']
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(5, 22) AS x")[0]['x']
		# translator 6 = 1st pt : can do 15, 19, 24
		assert_equal 'wait', DB.exec("SELECT x FROM words.translator_translation_ok(6, 15) AS x")[0]['x']
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(6, 19) AS x")[0]['x']
		assert_equal 'review', DB.exec("SELECT x FROM words.translator_translation_ok(6, 24) AS x")[0]['x']
		# all others not allowed
		[[1,1], [2,1], [3,1], [4,1], [5,1], [6,1], [1,2], [2,2], [3,2], [4,2], [5,2], [6,2], [1,3], [2,3], [3,3], [4,3], [5,3], [6,3], [1,4], [2,4], [3,4], [4,4], [5,4], [6,4], [1,5], [2,5], [3,5], [4,5], [5,5], [6,5], [1,6], [2,6], [3,6], [4,6], [5,6], [6,6], [1,7], [2,7], [3,7], [4,7], [5,7], [6,7], [1,8], [2,8], [3,8], [4,8], [5,8], [6,8], [1,9], [2,9], [3,9], [4,9], [5,9], [6,9], [1,10], [2,10], [3,10], [4,10], [5,10], [6,10], [1,11], [2,11], [3,11], [4,11], [5,11], [6,11], [1,12], [2,12], [3,12], [4,12], [5,12], [6,12], [1,13], [2,13], [3,13], [4,13], [5,13], [6,13], [1,14], [2,14], [3,14], [4,14], [5,14], [6,14], [1,15], [2,15], [3,15], [4,15], [5,15], [1,16], [3,16], [4,16], [5,16], [6,16], [1,17], [2,17], [3,17], [4,17], [6,17], [1,18], [2,18], [3,18], [4,18], [5,18], [6,18], [1,19], [2,19], [3,19], [4,19], [5,19], [2,20], [3,20], [4,20], [5,20], [6,20], [2,21], [3,21], [4,21], [5,21], [6,21], [1,22], [2,22], [3,22], [4,22], [6,22], [1,23], [2,23], [4,23], [5,23], [6,23], [1,24], [2,24], [3,24], [4,24], [5,24]].each do |p|
			assert_nil DB.exec("SELECT x FROM words.translator_translation_ok(#{p[0]}, #{p[1]}) AS x")[0]['x']
		end
	end

	def test_article_for_translation
		(1..24).each do |i|
			res = DB.exec("SELECT words.article_for_translation(#{i})")
			if i < 17
				assert_equal 1, res[0]['article_for_translation'].to_i
			else
				assert_equal 2, res[0]['article_for_translation'].to_i
			end
		end
	end

	def test_next_translation
		[[1,5], [2,6], [3,7], [4,8], [5,9], [6,10], [7,11], [8,12], [9,13], [10,14], [11,15], [12,16], [13,nil], [14,nil], [15,nil], [16,nil], [17,22], [18,23], [19,24], [20,21], [21,nil], [22,nil], [23,nil], [24,nil]].each do |p|
			res = DB.exec("SELECT * FROM words.next_translation(#{p[0]})")
			if p[1].nil?
				assert_nil res[0]['translation_id']
			else
				assert_equal p[1], res[0]['translation_id'].to_i
			end
		end
	end

	def test_next_if_good
		[[1,1,5], [2,1,6], [3,1,7], [4,1,8], [5,1,9], [6,1,10], [7,1,11], [8,1,12], [9,1,13], [10,1,14], [11,1,15], [12,1,16], [13,1,nil], [14,1,nil], [15,1,nil], [16,1,nil], [17,2,22], [18,2,23], [19,2,24], [20,2,21], [21,2,nil], [22,2,nil], [23,2,nil], [24,2,nil]].each do |p|
			res = DB.exec("SELECT * FROM words.next_if_good(#{p[0]})")
			assert_equal p[1], res[0]['article_id'].to_i
			if p[2].nil?
				assert_nil res[0]['translation_id']
			else
				assert_equal p[2], res[0]['translation_id'].to_i
			end
		end
	end

	def test_translation_belongs_to
		DB.exec("SELECT * FROM words.translation_belongs_to(18, 4)")
		res = DB.exec("SELECT * FROM words.translations WHERE id = 18")
		assert_equal '4', res[0]['reviewed_by']
		assert_equal '3', res[0]['translated_by']
		DB.exec("SELECT * FROM words.translation_belongs_to(22, 5)")
		res = DB.exec("SELECT * FROM words.translations WHERE id = 22")
		assert_equal '5', res[0]['translated_by']
		assert_nil res[0]['reviewed_by']
	end
end
