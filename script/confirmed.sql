UPDATE peeps.people SET confirmed=TRUE WHERE id IN (SELECT person_id FROM peeps.emails WHERE outgoing IS FALSE);
UPDATE peeps.people SET confirmed=TRUE WHERE id IN (SELECT person_id FROM sivers.comments);
