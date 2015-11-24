# TODO:

## Profile URL:

```sql
UPDATE peeps ADD COLUMN profile char(4);
CREATE INDEX on peeps(profile);
```

* random generate function
* add for existing
* now.urls adding runs peeps.generate_profile_chars if not there
* update merge function to keep whichever one has the profile url
* map nginx nownownow current profile to these

## Tweets:

```sql
CREATE TABLE peeps.tweets (
	id bigint primary key,
	person_id integer REFERENCES peeps.people(id),
	created_at timestamp(0),
	outgoing boolean default 'f',
	reference_id integer REFERENCES peeps.tweets(id),
	answer_id integer REFERENCES peeps.tweets(id),
	dump jsonb,
	body text
);
```


## Protected file downloads

Use people.lopass for person authentication.

```sql
CREATE TABLE files (
	id serial primary key,
	filename varchar(127) unique,
	mime varchar(32),
	bytes integer
);

CREATE TABLE file_permissions (
	file_id integer not null references files(id),
	person_id integer not null references people(id),
	PRIMARY KEY (file_id, person_id)
);

CREATE TABLE file_history (
	id serial primary key,
	created_at datetime,
	file_id integer not null references files(id),
	person_id integer not null references people(id),
	client_data text
);
```

### Example URL & SQL:

<https://sivers.org/download/321321/abcd/5/DerekSivers-MarketingYourMusic.pdf>

```sql
	SELECT files.* FROM files
	JOIN file_permissions fp ON files.id=fp.file_id
	JOIN people ON fp.person_id=people.id
	WHERE fp.file_id=5 AND fp.person_id=321321 AND people.lopass='abcd';
```

### API:

	-- PARAMS: person_id, file_id, lopass, client_data
	download_file(integer, integer, text, text)
	Returns JSON of files.* info and logs download

