require '../test_tools.rb'

class WordsAPITest < Minitest::Test
	include JDB

	## (skipping tests for candidate stuff)

	def test_get_collections
		qry('words.get_collections()')
		assert_equal @j, [
			{id:1, name:'collection1'}, 
			{id:2, name:'collection2'}]
	end

	def test_get_collection
		qry('words.get_collection(1)')
		assert_equal @j, [
			{id:1, filename:'finished'}, 
			{id:2, filename:'unfinished'}]
		qry('words.get_collection(2)')
		assert_equal @j, [
			{id:3, filename:'secret'}]
	end

	def test_get_xors
		qry('words.get_xors()')
		assert_equal @j, [
		{id:5,
			person_id:3,
			lang:'es',
			roll:1,
			notes:'Veruca finished article1 + 1st sentence of article2',
			name:'Veruca Salt',
			email:'veruca@salt.com',
			public_id:'ijkl'},
		{id:3,
			person_id:6,
			lang:'fr',
			roll:1,
			notes:'Augustus finished article1 + 1st sentence of article2',
			name:'Augustus Gloop',
			email:'augustus@gloop.de',
			public_id:nil},
		{id:4,
			person_id:4,
			lang:'fr',
			roll:2,
			notes:'Charlie review1ed article1',
			name:'Charlie Buckets',
			email:'charlie@bucket.org',
			public_id:'mnop'},
		{id:7,
			person_id:8,
			lang:'ja',
			roll:1,
			notes:'Yoko just began. Assigned collection1 but has not claimed.',
			name:'Yoko Ono',
			email:'yoko@ono.com',
			public_id:nil},
		{id:6,
			person_id:2,
			lang:'pt',
			roll:1,
			notes:'Willy almost finished article1 but has question on last sentence:15. Has not claimed article2.',
			name:'Willy Wonka',
			email:'willy@wonka.com',
			public_id:'efgh'},
		{id:1,
			person_id:7,
			lang:'zh',
			roll:1,
			notes:'Gong finished article1 + 1st sentence of article2 + started 2nd sentence',
			name:'巩俐',
			email:'gong@li.cn',
			public_id:nil},
		{id:2,
			person_id:5,
			lang:'zh',
			roll:2,
			notes:'Oompa review1ed article1 except last sentence only started',
			name:'Oompa Loompa',
			email:'oompa@loompa.mm',
			public_id:'qrst'}]
	end

	def test_get_xor
		qry('words.get_xor(1)')
		assert_equal(@j, {id:1,
			person_id:7,
			lang:'zh',
			roll:1,
			notes:'Gong finished article1 + 1st sentence of article2 + started 2nd sentence',
			name:'巩俐',
			email:'gong@li.cn',
			public_id:nil,
			collections:[{id:1,name:'collection1'}],
			translations:[
			{id:4,finished:'2018-07-01T00:00:00+12:00',sentence_code:'aaaaaaaa',sentence:'headline here',translation:'这里头条'},
			{id:8,finished:'2018-07-01T00:00:00+12:00',sentence_code:'aaaaaaab',sentence:'Some <bold words>.',translation:'一些大<胆的话>'},
			{id:12,finished:'2018-07-01T00:00:00+12:00',sentence_code:'aaaaaaac',sentence:'Now <linked and <italic> words>.',translation:'在<联和<斜体>字>'},
			{id:16,finished:'2018-07-01T00:00:00+12:00',sentence_code:'aaaaaaad',sentence:'See <about> <this>?',translation:'<到><这个>'},
			{id:20,finished:'2018-07-01T00:00:00+12:00',sentence_code:'bbbbbbbb',sentence:'hello',translation:'你好'},
			{id:21,finished:nil,sentence_code:'bbbbbbbc',sentence:'not done yet',translation:'还没做完'}],
			review1s:nil,
			review2s:nil,
			finals:nil,
			questions:nil,
			replaced:nil})
		qry('words.get_xor(99)')
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
		qry('words.get_xor(6)')
		assert_equal @j[:questions], [{id:1,article_id:1,filename:'finished',sentence_code:'aaaaaaad',sentence:'See <about> <this>?',translation_id:15,lang:'pt',translation:'ver <sobre> <este>',question:'ver?',answer:nil}]
		qry('words.get_xor(4)')
		assert_equal @j[:replaced], [{id:1,translation_id:2,old:'tête ici',new:'titre ici'}]
	end

	def test_update_xor
		qry('words.update_xor(1, 3, $1)', ['newnotes'])
		assert_equal(@j[:roll], 3)
		assert_equal(@j[:notes], 'newnotes')
		qry('words.update_xor(2, NULL, $1)', ['newnotes'])
		assert_nil @j[:roll]
		assert_equal(@j[:notes], 'newnotes')
		qry('words.update_xor(99, 3, $1)', ['no no'])
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_assign_col_xor
		qry('words.assign_col_xor(2, 1)')
		assert_equal [{id:40},{id:41}], @j
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

	def test_get_article_lang_en
		qry('words.get_article_lang($1, $2)', [1, 'en'])
		# response comes back as one big hash, but testing individual keys here:
		assert_equal 1, @j[:id]
		assert_equal 'finished', @j[:filename]
		assert_equal @j[:template], '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>'
		assert_equal @j[:raw], '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>'
		assert_equal @j[:merged], '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>'
		assert_equal({sortid:1,
			code: 'aaaaaaaa',
			replacements: [],
			raw: 'headline here',
			merged: 'headline here'},
			@j[:sentences][0])
		assert_equal({sortid:2,
			code: 'aaaaaaab',
			replacements: ['<strong>','</strong>'],
			raw: 'Some <bold words>.',
			merged: 'Some <strong>bold words</strong>.'},
			@j[:sentences][1])
		assert_equal({sortid:3,
			code: 'aaaaaaac',
			replacements: ['<a href="/">', '<em>', '</em>', '</a>'],
			raw: 'Now <linked and <italic> words>.',
			merged: 'Now <a href="/">linked and <em>italic</em> words</a>.'},
			@j[:sentences][2])
		assert_equal({sortid:4,
			code: 'aaaaaaad',
			replacements: ['<a href="/about">', '</a>', '<a href="/">', '</a>'],
			raw: 'See <about> <this>?',
			merged: 'See <a href="/about">about</a> <a href="/">this</a>?'},
			@j[:sentences][3])
	end

	def test_get_article_lang
		qry('words.get_article_lang($1, $2)', [1, 'fr'])
		# response comes back as one big hash, but testing individual keys here:
		assert_equal 1, @j[:id]
		assert_equal 'finished', @j[:filename]
		assert_equal @j[:template], '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>'
		assert_equal @j[:raw], '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>'
		assert_equal @j[:merged], '<!-- titre ici -->
<p>
	quelques <strong>mots en gras</strong>
	maintenant <a href="/">liés et mots <em>italiques</em></a>
	voir <a href="/about">à ce</a> <a href="/">sujet</a>
</p>'
		assert_equal({id:2, sortid:1,
			code: 'aaaaaaaa',
			replacements: [],
			raw: 'titre ici',
			merged: 'titre ici'},
			@j[:sentences][0])
		assert_equal({id:6, sortid:2,
			code: 'aaaaaaab',
			replacements: ['<strong>','</strong>'],
			raw: 'quelques <mots en gras>',
			merged: 'quelques <strong>mots en gras</strong>'},
			@j[:sentences][1])
		assert_equal({id:10, sortid:3,
			code: 'aaaaaaac',
			replacements: ['<a href="/">', '<em>', '</em>', '</a>'],
			raw: 'maintenant <liés et mots <italiques>>',
			merged: 'maintenant <a href="/">liés et mots <em>italiques</em></a>'},
			@j[:sentences][2])
		assert_equal({id:14, sortid:4,
			code: 'aaaaaaad',
			replacements: ['<a href="/about">', '</a>', '<a href="/">', '</a>'],
			raw: 'voir <à ce> <sujet>',
			merged: 'voir <a href="/about">à ce</a> <a href="/">sujet</a>'},
			@j[:sentences][3])
	end

	def test_xor_get_article
		qry('words.xor_get_article(7, 3)') # 404 if not assigned
		assert_equal '404', @res[0]['status']
		assert_equal({}, @j)
		qry('words.xor_get_article(7, 1)') # yes can see before claiming
		assert_equal(@j[:id], 1)
		assert_equal(@j[:role], 1)
		assert_equal(@j[:state], 'none')
		qry('words.xor_get_article(1, 1)') # can see anytime
		assert_equal(@j[:id], 1)
		assert_equal(@j[:role], 1)
		assert_equal(@j[:state], 'done')
		assert_equal(@j[:filename], 'finished')
		assert_equal(@j[:template], %Q(<!-- {aaaaaaaa} -->\n<p>\n\t{aaaaaaab}\n\t{aaaaaaac}\n\t{aaaaaaad}\n</p>))
		assert_equal(@j[:raw], %Q(<!-- headline here -->\n<p>\n\tSome <strong>bold words</strong>.\n\tNow <a href="/">linked and <em>italic</em> words</a>.\n\tSee <a href="/about">about</a> <a href="/">this</a>?\n</p>))
		assert_equal(@j[:merged], %Q(<!-- 这里头条 -->\n<p>\n\t一些大<strong>胆的话</strong>\n\t在<a href="/">联和<em>斜体</em>字</a>\n\t<a href="/about">到</a><a href="/">这个</a>\n</p>))
		s = @j[:sentences][0]
		assert_equal(s[:id], 4)
		assert_equal(s[:done_at], '2018-07-01T00:00:00+12:00')
		assert_equal(s[:sortid], 1)
		assert_equal(s[:code], 'aaaaaaaa')
		assert_equal(s[:replacements], [])
		assert_nil s[:comment]
		assert_equal(s[:sentence], 'headline here')
		assert_equal(s[:raw], '这里头条')
		assert_equal(s[:merged], '这里头条')
		s = @j[:sentences][3]
		assert_equal(s[:id], 16)
		assert_equal(s[:done_at], '2018-07-01T00:00:00+12:00')
		assert_equal(s[:sortid], 4)
		assert_equal(s[:code], 'aaaaaaad')
		assert_equal(s[:replacements], ['<a href="/about">','</a>','<a href="/">','</a>'])
		assert_nil s[:comment]
		assert_equal(s[:sentence], 'See <about> <this>?')
		assert_equal(s[:raw], '<到><这个>')
		assert_equal(s[:merged], '<a href="/about">到</a><a href="/">这个</a>')
		qry('words.xor_get_article(2, 1)') # done_at column changes based on role
		assert_equal(@j[:role], 2)
		assert_equal(@j[:state], 'some')
		s = @j[:sentences][0]
		assert_equal(s[:id], 4)
		assert_equal(s[:done_at], '2018-07-02T00:00:00+12:00')
		s = @j[:sentences][3]
		assert_equal(s[:id], 16)
		assert_nil s[:done_at]
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
				lang:'es',
				translation:'hola'},
				{id:18,
				lang:'fr',
				translation:'bonjour'},
				{id:19,
				lang:'pt',
				translation:nil},
				{id:20,
				lang:'zh',
				translation:'你好',},
				{id:29,
				lang:'ja',
				translation:nil}
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

	def test_get_xion
		qry('words.get_xion(8)')
		assert_equal(@j, {id:8,
			article_id:1,
			filename:'finished',
			sentence_code:'aaaaaaab',
			lang:'zh',
			sentence:'Some <bold words>.',
			s2:'Some <strong>bold words</strong>.',
			translation:'一些大<胆的话>',
			t2:'一些大<strong>胆的话</strong>',
			translated_at: '2018-07-01T00:00:00+12:00',
			translator:{id:1, person_id:7, name:'巩俐'},
			review1_at: '2018-07-02T00:00:00+12:00',
			reviewer1:{id:2, person_id:5, name:'Oompa Loompa'},
			review2_at: nil,
			reviewer2:nil,
			final_at: nil,
			editor:nil,
			replaced:nil,
			questions:nil})
		qry('words.get_xion(2)')
		assert_equal(@j[:replaced], [
			{id:1,
			replaced_by:4,
			translation:'tête ici'}])
		qry('words.get_xion(15)')
		assert_equal(@j[:questions], [
			{id:1,
			asked_by:6,
			created_at:'2018-07-02',
			question:'ver?',
			answer:nil}])
	end

	def test_admin_update_xion
		qry("words.admin_update_xion(21, '话')")
		assert_equal(@j[:translation], '话')
		assert_nil @j[:replaced]
	end

	def test_xor_update_xion
		qry("words.xor_update_xion(1, 21, '话')")
		assert_equal(@j[:translation], '话')
		assert_nil @j[:replaced]
		qry("words.xor_update_xion(3, 23, 'pas fini')")
		assert_equal(@j[:translation], 'pas fini')
		assert_nil @j[:translated_at]
		assert_nil @j[:replaced]
		qry("words.xor_update_xion(2, 16, '<话><话>')")
		assert_equal(@j[:translation], '<话><话>')
		assert_equal(@j[:replaced], [{id:2,replaced_by:2,translation:'<到><这个>'}])
		qry("words.xor_update_xion(1, 1, 'x')")
		assert_equal 'not yours', @j[:error]
		qry("words.xor_update_xion(5, 1, 'x')")
		assert_equal 'no update: finished', @j[:error]
		qry("words.xor_update_xion(4, 2, 'x')")
		assert_equal 'no update: finished', @j[:error]
	end

	# if replacement is same as translation, don't insert into replaced table
	def test_replacement_same
		qry("words.xor_update_xion(2, 16, '<到><这个>')")
		assert_equal(@j[:translation], '<到><这个>')
		assert_nil @j[:replaced]
		qry("words.xor_update_xion(2, 16, '<a><bc>')")
		assert_equal(@j[:translation], '<a><bc>')
		assert_equal(@j[:replaced], [{id:2,replaced_by:2,translation:'<到><这个>'}])
		qry("words.xor_update_xion(2, 16, '<a><bc>')")
		assert_equal(@j[:replaced], [{id:2,replaced_by:2,translation:'<到><这个>'}])
		qry("words.xor_update_xion(2, 16, '<b><cd>')")
		assert_equal(@j[:translation], '<b><cd>')
		assert_equal(@j[:replaced], [
			{id:2,replaced_by:2,translation:'<到><这个>'},
			{id:3,replaced_by:2,translation:'<a><bc>'}])
	end

	def test_xor_finish_xion
		qry("words.xor_finish_xion(1, 1)")
		assert_equal 'not yours', @j[:error]
		qry("words.xor_finish_xion(3, 23)")
		assert_equal 'translation is null', @j[:error]
		qry("words.xor_finish_xion(1, 21)")
		assert @j[:translated_at]
		qry("words.xor_finish_xion(2, 16)")
		assert @j[:review1_at]
	end

	def test_xor_unfinish_xion
		qry("words.xor_unfinish_xion(1, 1)")
		assert_equal 'not yours', @j[:error]
		qry("words.xor_unfinish_xion(1, 20)")
		assert_nil @j[:translated_at]
		qry("words.xor_unfinish_xion(2, 12)")
		assert_nil @j[:review1_at]
	end

	def test_ask_question
		qry('words.ask_question(2, 19, $1)', ['why?'])
		assert_equal '403', @res[0]['status']
		qry('words.ask_question(2, 16, $1)', ['why?'])
		assert_equal '200', @res[0]['status']
		qry('words.get_xion(16)')
		assert_equal 2, @j[:questions][0][:id]
		assert_equal 2, @j[:questions][0][:asked_by]
		assert_equal 'why?', @j[:questions][0][:question]
		assert_nil @j[:questions][0][:answer]
	end

	def test_unanswered_questions
		qry("words.unanswered_questions()")
		assert_equal @j, [{id:1,
			article_id:1,
			filename:'finished',
			sentence_code:'aaaaaaad',
			sentence:'See <about> <this>?',
			translation_id:15,
			lang:'pt',
			translation:'ver <sobre> <este>',
			asked_by:6,
			name:'Willy Wonka',
			question:'ver?',
			answer:nil}]
	end

	def test_answer_question
		qry("words.answer_question(1, 'yeah')")
		eid = @j[:email_id]
		qry("peeps.get_email(1, #{eid})")
		assert_equal(@j[:subject], 'your translation question [1]')
		assert_equal(@j[:body], 'Hi Mr. Wonka -

ARTICLE: https://tr.sivers.org/article/1
SENTENCE: See <about> <this>?
TRANSLATION: ver <sobre> <este>
YOUR QUESTION: ver?
MY REPLY: 

yeah

--
Derek Sivers  derek@sivers.org  https://sivers.org/')
		qry('words.get_xion(15)')
		assert_equal(@j[:questions], [
			{id:1,
			asked_by:6,
			created_at:'2018-07-02',
			question:'ver?',
			answer:'yeah'}])
		qry("words.unanswered_questions()")
		assert_equal [], @j
	end

	def test_add_xor
		qry("words.add_xor(1, 'eo')")
		assert_equal(@j, {id:8,person_id:1,lang:'eo',roll:nil,notes:nil})
	end

	def test_hire_candidate
		qry('words.hire_candidate(1)')
		assert_equal(@j, {id:8,person_id:1,lang:'eo',roll:1,notes:'1st: hob: I will try'})
	end

	def test_unhire_xor
		qry('words.unhire_xor(7)')
		assert_equal(@j[:id], 2)
		assert_equal(@j[:person_id], 8)
		assert_equal(@j[:lang], 'ja')
		assert_equal(@j[:role], 'zzz')
		assert_equal(@j[:expert], 'zzz')
		assert_equal(@j[:yesno], false)
		assert_equal(@j[:has_emailed], true)
		assert_equal(@j[:notes], 'removed from translators for doing nothing')
		qry('words.unhire_xor(1)')
		assert_equal '500', @res[0]['status']
		assert @j[:message].include? 'violates foreign key'
	end

	def test_xor_articles
		qry('words.xor_articles(3)')
		assert_equal @j[:do], [{id:2,filename:'unfinished'}]
		assert_nil @j[:claim]
		assert_equal @j[:done], [{id:1,filename:'finished'}]
		qry('words.xor_articles(4)')
		assert_nil @j[:do]
		assert_equal @j[:claim], [{id:2,filename:'unfinished'}]
		assert_equal @j[:done], [{id:1,filename:'finished'}]
		# once I answer their question, article 1 should move from do to wait:
		qry('words.xor_articles(6)')
		assert_nil @j[:do]
		assert_equal @j[:wait], [{id:1,filename:'finished'}]
		qry("words.answer_question(1, 'yeah')")
		qry('words.xor_articles(6)')
		assert_equal @j[:do], [{id:1,filename:'finished'}]
		assert_nil @j[:wait]
	end

	def test_xor_claim_article
		qry("words.xor_claim_article(1, 2)")
		assert_equal '500', @res[0]['status']
		assert_equal 'finish others first', @j[:message]
		qry("words.xor_claim_article(4, 2)")
		assert_equal '200', @res[0]['status']
		assert_equal({}, @j)
		qry("words.xor_claim_article(7, 1)")
		assert_equal '200', @res[0]['status']
		assert_equal({}, @j)
	end

	def test_collection_progress
		qry("words.collection_progress(1)")
		assert_equal(5, @j.size)
		assert_equal({lang:'fr',t_done:5,t_claim:6,r1_done:4,r1_claim:4,r2_done:0,r2_claim:0,f_done:0,f_claim:0}, @j[0])
		qry("words.collection_progress(2)")
		assert_equal([], @j)
	end

	def test_mismatched_tags
		qry('words.mismatched_tags()')
		assert_equal([], @j)
	end

end
