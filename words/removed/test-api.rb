require '../test_tools.rb'

class WordsAPITest < Minitest::Test
	include JDB

	def test_get_translators
		qry('words.get_translators()')
		assert_equal @j, [
		{id:5, person_id:3, lang:'es', role:'1st', name:'Veruca Salt', email:'veruca@salt.com'}, 
		{id:3, person_id:6, lang:'fr', role:'1st', name:'Augustus Gloop', email:'augustus@gloop.de'}, 
		{id:4, person_id:4, lang:'fr', role:'2nd', name:'Charlie Buckets', email:'charlie@bucket.org'}, 
		{id:6, person_id:2, lang:'pt', role:'1st', name:'Willy Wonka', email:'willy@wonka.com'}, 
		{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐', email:'gong@li.cn'}, 
		{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa', email:'oompa@loompa.mm'}]
	end

	def test_get_translator
		qry('words.get_translator(1)')
		assert_equal(@j, {id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐', email:'gong@li.cn'})
		qry('words.get_translator(99)')
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_update_translator
		qry('words.update_translator(1, $1)', ['2nd'])
		assert_equal(@j, {id:1, person_id:7, lang:'zh', role:'2nd', name:'巩俐', email:'gong@li.cn'})
		qry('words.update_translator(99, $1)', ['1st'])
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_add_translator
		qry('words.add_translator($1, $2, $3)', [1, 'eo' ,'1st'])
		assert_equal(@j, {id:7, person_id:1, lang:'eo', role:'1st', name:'Derek Sivers', email:'derek@sivers.org'})
	end

	def test_get_article
		qry('words.get_article(1)')
		assert_equal(@j, {id:1,
		filename:'finished',
		collection:{id:1, name:'collection1'},
		raw:"<!-- headline here -->\n<p>\n\tSome <strong>bold words</strong>.\n\tNow <a href=\"/\">linked and <em>italic</em> words</a>.\n\tSee <a href=\"/about\">about</a> <a href=\"/\">this</a>?\n</p>",
		template:"<!-- {aaaaaaaa} -->\n<p>\n\t{aaaaaaab}\n\t{aaaaaaac}\n\t{aaaaaaad}\n</p>",
		sentences:[
			{code:'aaaaaaaa', sortid:1, sentence:'headline here', replacements:[], comment:nil},
			{code:'aaaaaaab', sortid:2, sentence:'Some <bold words>.', replacements:['<strong>', '</strong>'], comment:nil},
			{code:'aaaaaaac', sortid:3, sentence:'Now <linked and <italic> words>.', replacements:['<a href="/">', '<em>', '</em>', '</a>'], comment:nil},
			{code:'aaaaaaad', sortid:4, sentence:'See <about> <this>?', replacements:['<a href="/about">', '</a>', '<a href="/">', '</a>'], comment:nil}]
		})
	end

	def test_get_article_lang
		qry('words.get_article_lang($1, $2)', [1, 'fr'])
		# response comes back as one big hash, but testing individual keys here:
		assert_equal 1, @j[:id]
		assert_equal 'finished', @j[:filename]
		assert_equal '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>', @j[:template]
		assert_equal '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>', @j[:raw]
		assert_equal '<!-- titre ici -->
<p>
	quelques <strong>mots en gras</strong>
	maintenant <a href="/">liés et mots <em>italiques</em></a>
	voir <a href="/about">à ce</a> <a href="/">sujet</a>
</p>', @j[:merged]
		assert_equal({sortid:1,
			code: 'aaaaaaaa',
			replacements: [],
			raw: 'titre ici',
			merged: 'titre ici'},
			@j[:sentences][0])
		assert_equal({sortid:2,
			code: 'aaaaaaab',
			replacements: ['<strong>','</strong>'],
			raw: 'quelques <mots en gras>',
			merged: 'quelques <strong>mots en gras</strong>'},
			@j[:sentences][1])
		assert_equal({sortid:3,
			code: 'aaaaaaac',
			replacements: ['<a href="/">', '<em>', '</em>', '</a>'],
			raw: 'maintenant <liés et mots <italiques>>',
			merged: 'maintenant <a href="/">liés et mots <em>italiques</em></a>'},
			@j[:sentences][2])
		assert_equal({sortid:4,
			code: 'aaaaaaad',
			replacements: ['<a href="/about">', '</a>', '<a href="/">', '</a>'],
			raw: 'voir <à ce> <sujet>',
			merged: 'voir <a href="/about">à ce</a> <a href="/">sujet</a>'},
			@j[:sentences][3])
	end

	def test_get_sentence
		qry('words.get_sentence($1)', ['bbbbbbbb'])
		assert_equal(@j, {code:'bbbbbbbb',
			article_id:2,
			filename:'unfinished',
			sortid:1,
			sentence:'hello',
			replacements:[],
			comment:'to friends',
			translations:[
				{id:17,
				article_id:2,
				filename:'unfinished',
				sentence_code:'bbbbbbbb',
				state:'new',
				lang:'es',
				sentence:'hello', s2:'hello', translation:'hola', t2:'hola',
				question:nil,
				translator:{id:5, person_id:3, lang:'es', role:'1st', name:'Veruca Salt'},
				reviewer:nil},
				{id:18,
				article_id:2,
				filename:'unfinished',
				sentence_code:'bbbbbbbb',
				state:'review',
				lang:'fr',
				sentence:'hello', s2:'hello', translation:'bonjour', t2:'bonjour',
				question:nil,
				translator:{id:3, person_id:6, lang:'fr', role:'1st', name:'Augustus Gloop'},
				reviewer:nil},
				{id:19,
				article_id:2,
				filename:'unfinished',
				sentence_code:'bbbbbbbb',
				state:'new',
				lang:'pt',
				sentence:'hello', s2:'hello', translation:'olá', t2:'olá',
				question:nil,
				translator:{id:6, person_id:2, lang:'pt', role:'1st', name:'Willy Wonka'},
				reviewer:nil},
				{id:20,
				article_id:2,
				filename:'unfinished',
				sentence_code:'bbbbbbbb',
				state:'new',
				lang:'zh',
				sentence:'hello', s2:'hello', translation:'你好', t2:'你好',
				question:nil,
				translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
				reviewer:nil}
			]})
	end

	def test_update_sentence_comment
		code = 'aaaaaaab'
		comment = 'watch out'
		qry('words.update_sentence_comment($1, $2)', [code, comment])
		assert_equal(@j, {})
		qry('words.get_sentence($1)', [code])
		assert_equal comment, @j[:comment]
	end

	def test_get_sentence_lang
		qry('words.get_sentence_lang($1, $2)', ['aaaaaaab', 'zh'])
		assert_equal(@j, {id:8,
article_id:1,
filename:'finished',
sentence_code:'aaaaaaab',
state:'done',
lang:'zh',
sentence:'Some <bold words>.',
s2:'Some <strong>bold words</strong>.',
translation:'一些大<胆的话>',
t2:'一些大<strong>胆的话</strong>',
question:nil,
translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
reviewer:{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa'}})
	end

	def test_next_sentence_for_article_lang
		qry('words.next_sentence_for_article_lang($1, $2)', [2, 'es'])
		assert_equal 22, @j[:id]
		assert_equal 'not done yet', @j[:sentence]
		qry('words.next_sentence_for_article_lang($1, $2)', [2, 'zh'])
		assert_equal({}, @j)  # none = done
	end

	def test_get_translation
		qry('words.get_translation(8)')
		assert_equal(@j, {id:8,
article_id:1,
filename:'finished',
sentence_code:'aaaaaaab',
state:'done',
lang:'zh',
sentence:'Some <bold words>.',
s2:'Some <strong>bold words</strong>.',
translation:'一些大<胆的话>',
t2:'一些大<strong>胆的话</strong>',
question:nil,
translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
reviewer:{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa'}})
	end

	def test_update_translation
		qry('words.update_translation($1, $2, $3)', [1, 20, '话'])
		assert_equal(@j, {article_id:2})
	end

	def test_replace_translation
		ol = '<到><这个>'
		nu = '<这个><到>'
		qry('words.replace_translation(2, 16, $1)', [nu])
		assert_equal(@j, {id:16,
										article_id:1,
										filename:'finished',
sentence_code:'aaaaaaad',
state:'review',
lang:'zh',
sentence:'See <about> <this>?',
s2:'See <a href="/about">about</a> <a href="/">this</a>?',
translation:'<这个><到>',
t2:'<a href="/about">这个</a><a href="/">到</a>',
question:nil,
translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
reviewer:{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa'}})
	end

	def test_finish_translation
		qry('words.finish_translation(1, 4)')
		assert_equal '400', @res[0]['status']
		assert_equal({article_id:1,translation_id:4}, @j)
		qry('words.finish_translation(5, 17)')
		assert_equal({article_id:2,translation_id:22}, @j)
		qry('words.finish_translation(2, 16)')
		assert_equal({article_id:1,translation_id:nil}, @j)
	end

	def test_article_state_count_for
		qry('words.article_state_count_for(1)')
		assert_equal [{stat:'do',howmany:1},{stat:'done',howmany:1}], @j
		qry('words.article_state_count_for(6)')
		assert_equal [{stat:'do',howmany:1},{stat:'wait',howmany:1}], @j
	end

	def test_translator_art_stat
		qry('words.translator_art_stat(1)')
		assert_equal @j, [{article_id:1,stat:'done'},{article_id:2,stat:'do'}]
		qry('words.finish_translation(1, 20)')
		qry('words.finish_translation(1, 21)')
		qry('words.translator_art_stat(1)')
		assert_equal @j, [{article_id:1,stat:'done'},{article_id:2,stat:'done'}]
	end

	def test_translator_art_stat_count
		qry('words.translator_art_stat_count(1)')
		assert_equal @j, [{stat:'done',howmany:1},{stat:'do',howmany:1}]
		qry('words.finish_translation(1, 20)')
		qry('words.finish_translation(1, 21)')
		qry('words.translator_art_stat_count(1)')
		assert_equal @j, [{stat:'done',howmany:2}]
	end

	def test_translator_art_stat_with_stat
		qry("words.translator_art_with_stat(5, 'done')")
		assert_equal @j, [{article_id:1,filename:'finished'}]
		qry("words.translator_art_with_stat(5, 'do')")
		assert_equal @j, [{article_id:2,filename:'unfinished'}]
		qry("words.translator_art_with_stat(5, 'doing')")
		assert_equal @j, []
	end
	
	def test_translator_ons_stat_with_stat
		qry("words.translator_ons_with_stat(1, 'new')")
		assert_equal [20,21], @j.map{|x| x[:id]}
		qry("words.translator_ons_with_stat(1, 'review')")
		assert_equal [16], @j.map{|x| x[:id]}
		qry("words.translator_ons_with_stat(1, 'done')")
		assert_equal [4,8,12], @j.map{|x| x[:id]}
		qry("words.translator_ons_with_stat(1, 'wait')")
		assert_equal [], @j.map{|x| x[:id]}
	end
	
	def test_article_paired_lang
		qry("words.article_paired_lang(1, 'fr')")
		assert_equal(@j, [
			{:id=>2,
			 :state=>'done',
			 :code=>'aaaaaaaa',
			 :sentence=>'headline here',
			 :s2=>'headline here',
			 :translation=>'titre ici',
			 :t2=>'titre ici',
			 :comment=>nil,
			 :question=>nil},
			{:id=>6,
			 :state=>'done',
			 :code=>'aaaaaaab',
			 :sentence=>'Some <bold words>.',
			 :s2=>'Some <strong>bold words</strong>.',
			 :translation=>'quelques <mots en gras>',
			 :t2=>'quelques <strong>mots en gras</strong>',
			 :comment=>nil,
			 :question=>nil},
			{:id=>10,
			 :state=>'done',
			 :code=>'aaaaaaac',
			 :sentence=>'Now <linked and <italic> words>.',
			 :s2=>'Now <a href="/">linked and <em>italic</em> words</a>.',
			 :translation=>'maintenant <liés et mots <italiques>>',
			 :t2=>'maintenant <a href="/">liés et mots <em>italiques</em></a>',
			 :comment=>nil,
			 :question=>nil},
			{:id=>14,
			 :state=>'done',
			 :code=>'aaaaaaad',
			 :sentence=>'See <about> <this>?',
			 :s2=>'See <a href="/about">about</a> <a href="/">this</a>?',
			 :translation=>'voir <à ce> <sujet>',
			 :t2=>'voir <a href="/about">à ce</a> <a href="/">sujet</a>',
			 :comment=>nil,
			 :question=>nil}])
	end

	def test_translator_article_paired
		qry('words.translator_article_paired(4, 1)')
		assert_equal '403', @res[0]['status']
		assert_equal(@j, {not:'yours'})
		qry('words.translator_article_paired(3, 1)')
		assert_equal(@j, [
			{:id=>2,
			 :state=>'done',
			 :code=>'aaaaaaaa',
			 :sentence=>'headline here',
			 :s2=>'headline here',
			 :translation=>'titre ici',
			 :t2=>'titre ici',
			 :comment=>nil,
			 :question=>nil},
			{:id=>6,
			 :state=>'done',
			 :code=>'aaaaaaab',
			 :sentence=>'Some <bold words>.',
			 :s2=>'Some <strong>bold words</strong>.',
			 :translation=>'quelques <mots en gras>',
			 :t2=>'quelques <strong>mots en gras</strong>',
			 :comment=>nil,
			 :question=>nil},
			{:id=>10,
			 :state=>'done',
			 :code=>'aaaaaaac',
			 :sentence=>'Now <linked and <italic> words>.',
			 :s2=>'Now <a href="/">linked and <em>italic</em> words</a>.',
			 :translation=>'maintenant <liés et mots <italiques>>',
			 :t2=>'maintenant <a href="/">liés et mots <em>italiques</em></a>',
			 :comment=>nil,
			 :question=>nil},
			{:id=>14,
			 :state=>'done',
			 :code=>'aaaaaaad',
			 :sentence=>'See <about> <this>?',
			 :s2=>'See <a href="/about">about</a> <a href="/">this</a>?',
			 :translation=>'voir <à ce> <sujet>',
			 :t2=>'voir <a href="/about">à ce</a> <a href="/">sujet</a>',
			 :comment=>nil,
			 :question=>nil}])
	end

	def test_ask_question
		qry('words.ask_question(2, 4, $1)', ['why?'])
		assert_equal '403', @res[0]['status']
		assert_equal(@j, {no:'questions'})
		qry('words.ask_question(2, 19, $1)', ['why?'])
		assert_equal '403', @res[0]['status']
		assert_equal(@j, {no:'questions'})
		qry('words.ask_question(2, 16, $1)', ['why?'])
		assert_equal(@j, {id:16,
sentence_code:'aaaaaaad',
article_id:1,
filename:'finished',
state:'wait',
lang:'zh',
sentence:'See <about> <this>?',
s2:'See <a href="/about">about</a> <a href="/">this</a>?',
translation:'<到><这个>',
t2:'<a href="/about">到</a><a href="/">这个</a>',
question:'why?',
translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
reviewer:{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa'}})
		qry('words.ask_question(2, 16, $1)', ['WHY!?'])
		assert_equal(@j, {id:16,
article_id:1,
filename:'finished',
sentence_code:'aaaaaaad',
state:'wait',
lang:'zh',
sentence:'See <about> <this>?',
s2:'See <a href="/about">about</a> <a href="/">this</a>?',
translation:'<到><这个>',
t2:'<a href="/about">到</a><a href="/">这个</a>',
question:'why? WHY!?',
translator:{id:1, person_id:7, lang:'zh', role:'1st', name:'巩俐'},
reviewer:{id:2, person_id:5, lang:'zh', role:'2nd', name:'Oompa Loompa'}})
	end

	def test_replaced_for
		qry('words.replaced_for(2)')
		assert_equal [{id:1,sentence_code:'aaaaaaaa',lang:'fr',translated_by:3,replaced_by:4,translation:'tête ici'}], @j
		qry('words.replaced_for(3)')
		assert_equal [], @j
		qry('words.replaced_for(99)')
		assert_equal [], @j
		qry('words.replace_translation(2, 16, $1)', ['one'])
		qry('words.replace_translation(2, 16, $1)', ['two'])
		qry('words.replaced_for(16)')
		assert_equal [{id:2,sentence_code:'aaaaaaad',lang:'zh',translated_by:1,replaced_by:2,translation:'<到><这个>'},{id:3,sentence_code:'aaaaaaad',lang:'zh',translated_by:1,replaced_by:2,translation:'one'}], @j
	end

	def test_get_questions
		qry('words.get_questions()')
		assert_equal(@j, [{id:15,
article_id:1,
filename:'finished',
sentence_code:'aaaaaaad',
state:'wait',
lang:'pt',
sentence:'See <about> <this>?',
s2:'See <a href="/about">about</a> <a href="/">this</a>?',
translation:'ver <sobre> <este>',
t2:'ver <a href="/about">sobre</a> <a href="/">este</a>',
question:'ver?',
translator:{id:6, person_id:2, lang:'pt', role:'1st', name:'Willy Wonka'},
reviewer:nil}])
	end

	def test_answer_question
		qry("words.answer_question(15, 'yeah')")
		eid = @j[:email_id]
		qry("peeps.get_email(1, #{eid})")
		assert_equal(@j[:subject], 'your translation question [15]')
		assert_equal(@j[:body], 'Hi Mr. Wonka -

ARTICLE: https://tr.sivers.org/article/1
SENTENCE: See <about> <this>?
TRANSLATION: ver <sobre> <este>
YOUR QUESTION: ver?
MY REPLY: 

yeah

--
Derek Sivers  derek@sivers.org  https://sivers.org/')
		qry('words.get_translation(15)')
		assert_nil @j[:question]
		assert_equal 'new', @j[:state]
		qry('words.get_questions()')
		assert_equal(@j, [])
	end

end
