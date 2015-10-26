# db-api

My PostgreSQL database.  © 2015 50pop LLC | Contact: [Derek Sivers](http://sivers.org/)

# WHAT'S WHAT:

Just a reminder to my future self, what's with this new PostgreSQL db-api way of doing things

In short:  **The database schema functions do all the work.  The other bits just map them to the UI.**

## As of 2015-10-26:

1. All smarts, all business rules, are in the database schema functions.
2. A little library simplifies database calls by handling the schema, arguments, and JSON conversion.
3. 50web has the actual end-user UI websites, calling PostreSQL functions by name, and using hash responses.

### Authentication:

**db-api/HTTP** REST API uses HTTP Basic Authentication, and most **a50c** client library classes need the API key and pass to initialize.  When testing API, just give it the key and pass strings from the fixtures.

To see whether they're legit, PostgreSQL searches api_keys table for that key, pass, and making sure this API is in the array of apis.  This could be a peeps schema function, but for now is not.  It'd probably be two queries: one for api_keys to get the person, then once authed, returning person_id, another one could get peeps.emailers.id or muckwork.managers.id or whatever, based on their person_id.  One more layer where it might fail just in case their person_id is not in that table.

When **real people** using it, a **50web** route called **ModAuth** checks for three cookies:  person_id, api_key, api_pass.  If they don't exist, it redirects to /login

/login is a form requiring email address and password, posted to /login, which is also grabbed by ModAuth.  If peeps.person authenticates that email & password, it looks in api_keys for theirs, and returns api_keys using SELECT * FROM auth_api(akey, apass, APIName)

If POST /login works, it sets the 3 needed cookies (person_id, api_key, api_pass).  Those are included in all calls, and sent to A50C To init client library.

# CHANGES? MIGRATIONS?

For small changes, just use psql to add a function, drop a table, etc.

The easiest way to make major changes is to copy the schema.sql files to /tmp/, the edit them to remove the "DROP SCHEMA" and "CREATE TABLE" lines.  All functions, triggers, and views can be replaced.

When adding a new schema, update the d50b user search_path:

```sql
ALTER USER d50b SET SEARCH_PATH TO core, peeps, muckwork, lat, musicthoughts, sivers, woodegg;
```

# TODO:

* email parsing: set personID using email address first before in-reply-to
* Where to translate ugly errors (probably using regexp matching) into simple i18n keys for the UI to show in user's language?
* clean up this README
* combine Gengo features into one CLI script

## API:

## Muckwork Client API:

* TODO: create payment, add note(projectId, taskId)

## Muckwork Worker API:

* initialize with API keys: MuckworkWorker
* get project(id)
* get task(id)
* claim task(id)
* unclaim task(id)
* start task(id)
* finish task(id)
* unclaimed tasks
* TODO: get payments, add note(projectId, taskId)
* TODO?: business rule against # of claimed tasks by worker?

## Muckwork Manager API:

* everything but init with API keys

