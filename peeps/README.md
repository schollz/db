# PEEPS

## AUTHORIZATION

From the beginning, I had the idea that there were going to be some people in my inbox that didn't have permission to see all emails.  This is done with

* emailers.profiles
* emailers.categories
* emailers.admin

But I'm using none of these.  All I really need is a boolean emailers.active so I can disable them so they can't log in.  But once they're in, they can see anyting.

ALTER TABLE peeps.emailers ALTER COLUMN person_id DROP NOT NULL;
ALTER TABLE peeps.emailers ADD COLUMN was integer references peeps.people(id);
UPDATE peeps.emailers SET was = person_id WHERE id NOT IN (1, 14);
UPDATE peeps.emailers SET person_id = NULL WHERE id NOT IN (1, 14);

Then maybe do a data-only dump, and re-load the database from scraatch to reload all the functions I changed.

Then finally:
ALTER TABLE peeps.emailers DROP COLUMN profiles;
ALTER TABLE peeps.emailers DROP COLUMN categories;
ALTER TABLE peeps.emailers DROP COLUMN admin;



