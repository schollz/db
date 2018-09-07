P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class EarmouthAPITest < Minitest::Test
	include JDB

	def setup
		super
		@derek = {id:1,
			public_id:'p9q',
			public_name:'Derek Sivers',
			image: 'https://earmouth.com/images/p9q.jpg',
			city:'Singapore',
			state:nil,
			country:'SG',
			bio:'creator of EarMouth'}
	end

	def test_auth_user
		qry("earmouth.auth_user('abcdefgh', 'ijklmnop')")
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
		qry("earmouth.auth_user('OGhUkqpm', '5xLFkZrT')")
		assert_equal @j, {id: 1}
		qry("earmouth.auth_user('OGhUkqpm', '5xLFkZrT')")
		assert_equal @j, {id: 1}
		qry("earmouth.accept_invitation('WC63KK')")
		apiuser, apipass = @j[:apikey].split(':')
		qry("earmouth.auth_user($1, $2)", [apiuser, apipass])
		assert_equal @j, {id: 4}
	end

	def test_get_users
		qry('earmouth.get_users()')
		assert_equal 3, @j.size
		assert_equal 1, @j[0][:id]
		assert_equal 'Sean’s mom', @j[1][:bio]
		assert_equal 'Bill W', @j[2][:public_name]
	end

	def test_user_get_users
		# wonka blocks derek so now won't be in list of users for him
		qry("earmouth.revoke_connection(3, 1)")
		qry('earmouth.user_get_users(1)')
		assert_equal 1, @j.size
		assert_equal 2, @j[0][:id]
		assert_equal 'Yoko', @j[0][:public_name]
	end

	def test_get_user
		qry('earmouth.get_user(1)')
		assert_equal @j, @derek
		qry('earmouth.get_user(99)')
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
	end

	def test_user_get_user
		# wonka blocks derek so now won't be in list of users for him
		qry("earmouth.revoke_connection(3, 1)")
		qry('earmouth.user_get_user(1, 3)')
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
		qry('earmouth.user_get_user(1, 2)')
		assert_equal 'Yoko', @j[:public_name]
	end

	def test_get_user_full
		qry('earmouth.get_user_full(3)')
		assert_equal @j, {id:3,
			public_id:'vC2',
			public_name:'Bill W',
			image: 'https://earmouth.com/images/vC2.jpg',
			city:'Hershey',
			state:'PA',
			country:'US',
			bio:'chocolate dude',
			urls:[
				{id:3, url:'http://www.wonka.com/', main:true},
				{id:4, url:'http://cdbaby.com/cd/wonka', main:nil},
				{id:5, url:'https://twitter.com/wonka', main:nil}
			],
			relationship: 'unconnected'}
		qry('earmouth.get_user_full(99)')
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
	end

	def test_user_get_user_full
		# wonka blocks derek so now won't be in list of users for him
		qry("earmouth.revoke_connection(3, 1)")
		qry('earmouth.user_get_user_full(1, 3)')
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
		qry('earmouth.user_get_user_full(1, 2)')
		assert_equal @j[:public_name], 'Yoko'
	end

	def test_relationship
		qry('earmouth.user_get_user_full(1, 2)')
		assert_equal @j[:relationship], 'unconnected'
		qry('earmouth.user_get_user_full(1, 3)')
		assert_equal @j[:relationship], 'connected'
		qry('earmouth.user_get_user_full(1, 1)')
		assert_equal @j[:relationship], 'self'
	end

	def test_user_update_public_name
		nu = 'þ'  # even one unicode character is OK
		qry('earmouth.user_update_public_name($1, $2)', [1, nu])
		assert_equal @j, @derek.merge(public_name: nu)
		# must not be empty
		qry('earmouth.user_update_public_name($1, $2)', [1, ''])
		assert_equal @res[0]['status'], '500'
		assert @j[:message].include? 'no_public_name'
		# and max length 40
		nu = 'This is too long because the maximum length is 40'
		qry('earmouth.user_update_public_name($1, $2)', [1, nu])
		assert_equal @res[0]['status'], '500'
		assert_equal @j[:code], '22001'
		# invalid user returns 404
		qry('earmouth.user_update_public_name($1, $2)', [99, 'not found'])
		assert_equal @res[0]['status'], '404'
		assert_equal @j, {}
	end

	def test_user_update_bio
		nu = 'bio inside test'
		qry('earmouth.user_update_bio($1, $2)', [1, nu])
		assert_equal @j, @derek.merge(bio: nu)
		nu = ''  # empty is OK
		qry('earmouth.user_update_bio($1, $2)', [1, nu])
		assert_equal @j, @derek.merge(bio: nu)
	end

	def test_clean_user_trigger
		qry('earmouth.user_update_public_name($1, $2)', [1, "\t\n Dude Sivers \t \n "])
		assert_equal @j[:public_name], 'Dude Sivers'
		qry('earmouth.user_update_bio($1, $2)', [1, "\t\n Too much space! \t \n "])
		assert_equal @j[:bio], 'Too much space!'
	end

	def test_delete_user
		qry('earmouth.delete_user(1)')
		assert_equal @j, @derek
		qry('earmouth.get_users()')
		assert_equal 2, @j.size
		assert_equal 2, @j[0][:id]
		assert_equal 3, @j[1][:id]
		qry('earmouth.get_user(1)')
		assert_equal @res[0]['status'], '404'
		qry('earmouth.delete_user(99)')
		assert_equal @res[0]['status'], '404'
	end

	def test_create_invitation_existing
		# Yoko invites Veruca 
		qry('earmouth.create_invitation($1, $2, $3)', [2, 'Veruca', 'veruca@salt.com'])
		new_email_id = @j[:id]
		assert_equal 11, @j[:id]
		qry('peeps.get_email(1, $1)', [new_email_id])
		assert @j[:subject].include? 'Yoko Ono'
		assert @j[:subject].include? 'yoko@ono.com'
		assert_match %r{Your code is: [A-Za-z0-9]{6}$}, @j[:body]
		assert_equal 'veruca@salt.com', @j[:their_email]
		assert_equal 'Veruca Salt', @j[:their_name]
	end

	def test_create_invitation_bad
		qry('earmouth.create_invitation($1, $2, $3)', [2, 'bad', 'bad.email'])
		assert @j[:message].include?('valid_email')
		assert_equal '500', @res[0]['status']
	end

	def test_create_invitation_new
		# Yoko invites Sean 
		qry('earmouth.create_invitation($1, $2, $3)', [2, 'Sean', 'sean@lennon.com'])
		new_email_id = @j[:id]
		qry('peeps.get_email(1, $1)', [new_email_id])
		assert_match %r{Your code is: [A-Za-z0-9]{6}$}, @j[:body]
		assert_equal 'Sean', @j[:their_name]
		assert_equal 9, @j[:person][:id] # new person
	end

	def test_accept_invitation
		qry("earmouth.accept_invitation('XXXXXX')")
		assert_equal @res[0]['status'], '404'
		qry("earmouth.accept_invitation('WC63KK')")
		assert_equal 4, @j[:id]
		assert_equal '巩俐', @j[:public_name]
		assert_match %r{[a-zA-Z0-9]{8}:[a-zA-Z0-9]{8}}, @j[:apikey]
		qry("earmouth.accept_invitation('WC63KK')")
		assert_equal @res[0]['status'], '404'
	end

	def test_create_request
		qry("earmouth.create_request(2, 1)") # yoko requests derek
		assert_equal @j, {id: 2}
		qry("earmouth.create_request(2, 1)") # dupe = 500
		assert_equal @res[0]['status'], '500'
		assert @j[:message].include? 'unique_request_pair'
		qry("earmouth.create_request(1, 2)") # either direction = dupe
		assert_equal @res[0]['status'], '500'
		assert @j[:message].include? 'unique_request_pair'
		qry("earmouth.create_request(3, 1)") # already connected
		assert_equal @res[0]['status'], '500'
		assert @j[:message].include? 'already_connected'
	end

	def test_delete_request
		qry("earmouth.delete_request(1, 2)")	# invalid user requesting deletion
		assert_equal @res[0]['status'], '404'
		qry("earmouth.delete_request(3, 9)")  # right user, wrong other.id
		assert_equal @res[0]['status'], '404'
		qry("earmouth.delete_request(3, 2)") 
		assert_equal @j, {id: 1}
		qry("earmouth.delete_request(3, 2)")  # doing it twice = 404
		assert_equal @res[0]['status'], '404'
	end

	def test_refuse_request
		qry("earmouth.requests WHERE id = 1")
		assert_nil @res[0]['approved']
		qry("earmouth.refuse_request(1, 2)")	# invalid user refusing it
		assert_equal @res[0]['status'], '404'
		qry("earmouth.refuse_request(2, 9)")	# right user, wrong other.id
		assert_equal @res[0]['status'], '404'
		qry("earmouth.refuse_request(2, 3)")
		assert_equal @j, {id: 1}
		qry("earmouth.refuse_request(2, 3)")	# doing it twice = 404
		assert_equal @res[0]['status'], '404'
		qry("earmouth.requests WHERE id = 1")
		assert_equal @res[0]['approved'], 'f'
		qry("earmouth.accept_request(2, 3)")	# reversible if mistake!
		qry("earmouth.requests WHERE id = 1")
		assert_equal @res[0]['approved'], 't'
	end

	def test_accept_request
		qry("earmouth.accept_request(1, 2)")	# invalid user accepting it
		assert_equal @res[0]['status'], '404'
		qry("earmouth.accept_request(2, 9)")	# right user, wrong other.id
		assert_equal @res[0]['status'], '404'
		qry("earmouth.accept_request(2, 3)")
		assert_equal @j[:public_name], 'Bill W'	# returns newly-connected user when accepted
		qry("earmouth.accept_request(2, 3)")	# doing it twice is OK
		assert_equal @j[:public_name], 'Bill W'
	end

	def test_revoke_connection
		qry("earmouth.revoke_connection(2, 1)")	# invalid user revoking it
		assert_equal @res[0]['status'], '404'
		qry("earmouth.revoke_connection(2, 3)")	# right user, wrong other.id
		assert_equal @res[0]['status'], '404'
		qry("earmouth.revoke_connection(3, 1)")	
		assert_equal @j, {id: 1}
		qry("earmouth.revoke_connection(3, 1)")	# doing it twice = 404
		assert_equal @res[0]['status'], '404'
		qry("earmouth.revoke_connection(1, 3)")	# other user doing it = doing it twice
		assert_equal @res[0]['status'], '404'
	end

	def test_get_unknown_users_for
		qry("earmouth.get_unknown_users_for(1)")
		assert_equal [2], @j.map {|u| u[:id]}
		qry("earmouth.get_unknown_users_for(2)")
		assert_equal [1], @j.map {|u| u[:id]}
		qry("earmouth.get_unknown_users_for(3)")
		assert_equal 0, @j.size
	end

	def test_connections_for
		qry("earmouth.connections_for(1)")
		assert_equal 1, @j.size
		assert_equal @j[0][:public_name], 'Bill W'
		# then Gong Li accepts my invitation:
		qry("earmouth.accept_invitation('WC63KK')")
		# now she's my best friend, and listed first, newest
		qry("earmouth.connections_for(1)")
		assert_equal 2, @j.size
		assert_equal @j[0][:public_name], '巩俐'
	end

	def test_request_in
		qry("earmouth.requests_in_for(1)")
		assert_equal 0, @j.size
		qry("earmouth.requests_in_for(2)")
		assert_equal [3], @j.map {|u| u[:id]}
		qry("earmouth.requests_in_for(3)")
		assert_equal 0, @j.size
	end

	def test_request_out
		qry("earmouth.requests_out_for(1)")
		assert_equal 0, @j.size
		qry("earmouth.requests_out_for(2)")
		assert_equal 0, @j.size
		qry("earmouth.requests_out_for(3)")
		assert_equal [2], @j.map {|u| u[:id]}
	end

	def test_user_update_country_state_city
		qry("earmouth.user_update_country_state_city(2, $1, $2, $3)", 
				['US', 'NY', 'New York'])
		assert_equal @j[:country], 'US'
		assert_equal @j[:state], 'NY'
		assert_equal @j[:city], 'New York'
		qry("earmouth.user_update_country_state_city(1, $1, NULL, $2)", 
				['NZ', 'Wellington'])
		assert_equal @j[:country], 'NZ'
		assert_nil @j[:state]
		assert_equal @j[:city], 'Wellington'
		qry("earmouth.user_update_country_state_city(3, 'XX', 'xx', 'xx')")
		assert_equal '500', @res[0]['status']
	end

	def test_user_counts
		qry("earmouth.user_counts(1)")
		assert_equal({connected: 1, unconnected: 1, request_out: 0, request_in: 0}, @j)
		qry("earmouth.user_counts(2)")
		assert_equal({connected: 0, unconnected: 1, request_out: 0, request_in: 1}, @j)
		qry("earmouth.user_counts(3)")
		assert_equal({connected: 1, unconnected: 0, request_out: 1, request_in: 0}, @j)
	end
end

