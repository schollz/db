-- used by other functions, below, for any random strings needed
CREATE OR REPLACE FUNCTION core.gen_random_bytes(integer) RETURNS bytea AS '$libdir/pgcrypto', 'pg_random_bytes' LANGUAGE c STRICT;
CREATE OR REPLACE FUNCTION core.random_string(length integer) RETURNS text AS $$
DECLARE
	chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
	result text := '';
	i integer := 0;
	rand bytea;
BEGIN
	-- Generate secure random bytes and convert them to a string of chars.
	-- Since our charset contains 62 characters, we will have a small
	-- modulo bias, which is acceptable for our uses.
	rand := core.gen_random_bytes(length);
	FOR i IN 0..length-1 LOOP
		result := result || chars[1 + (get_byte(rand, i) % array_length(chars, 1))];
		-- note: rand indexing is zero-based, chars is 1-based.
	END LOOP;
	RETURN result;
END;
$$ LANGUAGE plpgsql;
