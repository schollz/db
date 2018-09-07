P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class EarmouthFunctionTest < Minitest::Test
	include JDB

	def test_blocked
		res = DB.exec("SELECT blocked_userids_for AS i FROM earmouth.blocked_userids_for(3)")
		assert_equal [], res.map {|x| x['i']}
		DB.exec("SELECT * FROM earmouth.refuse_request(2, 3)")
		res = DB.exec("SELECT blocked_userids_for AS i FROM earmouth.blocked_userids_for(3)")
		assert_equal [2], res.map {|x| x['i'].to_i}
	end

	def test_connected
		res = DB.exec("SELECT connected_userids_for AS i FROM earmouth.connected_userids_for(1)")
		assert_equal [3], res.map {|x| x['i'].to_i}
		DB.exec("SELECT * FROM earmouth.accept_invitation('WC63KK')")
		res = DB.exec("SELECT connected_userids_for AS i FROM earmouth.connected_userids_for(1)")
		assert_equal [3,4], res.map {|x| x['i'].to_i}.sort
	end

	def test_request_in
		res = DB.exec("SELECT request_in_userids_for AS i FROM earmouth.request_in_userids_for(1)")
		assert_equal [], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT request_in_userids_for AS i FROM earmouth.request_in_userids_for(2)")
		assert_equal [3], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT request_in_userids_for AS i FROM earmouth.request_in_userids_for(3)")
		assert_equal [], res.map {|x| x['i'].to_i}
	end

	def test_request_out
		res = DB.exec("SELECT request_out_userids_for AS i FROM earmouth.request_out_userids_for(1)")
		assert_equal [], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT request_out_userids_for AS i FROM earmouth.request_out_userids_for(2)")
		assert_equal [], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT request_out_userids_for AS i FROM earmouth.request_out_userids_for(3)")
		assert_equal [2], res.map {|x| x['i'].to_i}
	end

	def test_unconnected
		res = DB.exec("SELECT unconnected_userids_for AS i FROM earmouth.unconnected_userids_for(1)")
		assert_equal [2], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT unconnected_userids_for AS i FROM earmouth.unconnected_userids_for(2)")
		assert_equal [1], res.map {|x| x['i'].to_i}
		res = DB.exec("SELECT unconnected_userids_for AS i FROM earmouth.unconnected_userids_for(3)")
		assert_equal [], res.map {|x| x['i'].to_i}
	end

	def test_relationship_from_to
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(1, 2)")
		assert_equal 'unconnected', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(1, 3)")
		assert_equal 'connected', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(2, 1)")
		assert_equal 'unconnected', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(2, 3)")
		assert_equal 'connection-request-in', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(3, 1)")
		assert_equal 'connected', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(3, 2)")
		assert_equal 'connection-request-out', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(3, 3)")
		assert_equal 'self', res[0]['relationship_from_to']
		DB.exec("SELECT * FROM earmouth.revoke_connection(3, 1)")
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(3, 1)")
		assert_equal 'blocked', res[0]['relationship_from_to']
		res = DB.exec("SELECT * FROM earmouth.relationship_from_to(1, 3)")
		assert_equal 'blocked', res[0]['relationship_from_to']
	end
end
