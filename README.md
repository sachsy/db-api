# db-api

My PostgreSQL database.  © 2015 50pop LLC | Contact: [Derek Sivers](http://sivers.org/)

# WHAT'S WHAT:

Just a reminder to my future self, what's with this new PostgreSQL db-api way of doing things

In short:  **The database schema functions do all the work.  The other bits just map them to the UI.**

## As of 2015-10-26:

1. All smarts, all business rules, are in the database schema functions.
2. A little library simplifies database calls by handling the schema, arguments, and JSON conversion.
3. 50web has the actual end-user UI websites, calling PostreSQL functions by name, and using hash responses.

## As of 2015-03-17:

1. All smarts, all business rules, are in the database schema functions.
2. B50D is a PostgreSQL API client, with one Ruby class per API, methods mapping to the pg functions, converting the JSON to hashes.
3. 50web has the actual end-user UI websites, letting the B50D Ruby class do all the work.

Important to note that the HTTP way of doing things is still the architecture/structure, and can be turned on with little effort if/when the APIs need to be made public.  (For example: JavaScript-created pages.)

## Before 2015-03-17:

1. All smarts, all business rules, are in the database schema functions.
2. HTTP/ has REST API Sinatra files that map HTTP URLs to the api.sql functions. Most require HTTP authentication. All return just mime and JSON. They're mostly private, but could be public some day.
3. a50c is a REST API client, with one Ruby class per API, methods mapping to the calls, converting the JSON to hashes.
4. 50web has the actual end-user UI websites, letting the a50c Ruby class do all the work.

### What's gone from -2014:

**d50b** was just Ruby+Sequel models around the database.  No more.  All gone.

**50apis** is now routes in db-api/HTTP since they use schema.sql files for resetting fixtures.  Views are now SQL views in db-api/~/views.sql

### What's new 2015+:

**db-api** has subdirectories with the rules that were once in d50b models, and views that were once in 50apis/views

**db-api/HTTP** has Sinatra API routes

### What's mostly the same:

**a50c** (now **b50d**) is still a “client library” Ruby gem to access the HTTP API with Ruby.  Only now instead of Struct with method calls, it's Hash with symbol keys.  I'll probably have to make other “client libraries” some day: JavaScript for JS-heavy front-end sites, Java for Android, ObjC for iOS?

**50web** is still all the end-user websites, using Sinatra + a50c/b50d gem.  Only now instead of Struct with method calls, it's Hash with symbol keys.

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
* Question why b50d gem is needed. Shouldn't SQL functions be simple enough for routes to call directly?
* Where to translate ugly errors (probably using regexp matching) into simple i18n keys for the UI to show in user's language?

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

