SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS earmouth CASCADE;
CREATE SCHEMA earmouth;
SET search_path = earmouth;

CREATE EXTENSION intarray; -- for unique pair indexes

CREATE TABLE earmouth.users (
	id serial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	apiuser char(8) not null UNIQUE CONSTRAINT valid_apiuser CHECK (apiuser ~ '\A[a-zA-Z0-9]{8}\Z'),
	apipass char(8) not null UNIQUE CONSTRAINT valid_apipass CHECK (apipass ~ '\A[a-zA-Z0-9]{8}\Z'),
	created_at date not null default current_date,
	deleted_at date,
	public_id char(3) not null UNIQUE CONSTRAINT valid_public_id CHECK (public_id ~ '\A[a-zA-Z0-9]{3}\Z'),
	public_name varchar(40) not null CONSTRAINT no_public_name CHECK (length(public_name) > 0),
	bio text
);

CREATE TABLE earmouth.invitations (
	id serial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	code char(6) not null UNIQUE CONSTRAINT valid_code CHECK (code ~ '\A[a-zA-Z0-9]{6}\Z'),
	created_by integer not null REFERENCES earmouth.users(id),
	created_at date not null default current_date,
	claimed_at date
);

CREATE TABLE earmouth.requests (
	id serial primary key,
	requester integer not null REFERENCES earmouth.users(id),
	requestee integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_request_self CHECK (requester != requestee),
	created_at date not null default current_date,
	approved boolean,
	closed_at date
);
CREATE UNIQUE INDEX unique_request_pair on earmouth.requests(earmouth.sort(array[requester, requestee]));

CREATE TABLE earmouth.connections (
	id serial primary key,
	user1 integer not null REFERENCES earmouth.users(id),
	user2 integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_connect_self CHECK (user1 != user2),
	created_at date not null default current_date,
	revoked_at date,
	revoked_by integer REFERENCES earmouth.users(id)
);
CREATE UNIQUE INDEX unique_connection_pair on earmouth.connections(earmouth.sort(array[user1, user2]));

CREATE TABLE earmouth.calls (
	id serial primary key,
	public_id char(4) not null UNIQUE CONSTRAINT valid_call_id CHECK (public_id ~ '\A[a-zA-Z0-9]{4}\Z'),
	caller integer not null REFERENCES earmouth.users(id),
	callee integer not null REFERENCES earmouth.users(id),
	CONSTRAINT not_call_self CHECK (caller != callee),
	started_at timestamp(0) with time zone not null DEFAULT current_timestamp,
	finished_at timestamp(0) with time zone
);

