----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS lat.concept_view CASCADE;
CREATE VIEW lat.concept_view AS
	SELECT id, created_at, title, concept, (SELECT json_agg(uq) AS urls FROM
		(SELECT u.* FROM lat.urls u, lat.concepts_urls cu
			WHERE u.id=cu.url_id AND cu.concept_id=lat.concepts.id
			ORDER BY u.id) uq),
	(SELECT json_agg(tq) AS tags FROM
		(SELECT t.* FROM lat.tags t, lat.concepts_tags ct
			WHERE t.id=ct.tag_id AND ct.concept_id=concepts.id
			ORDER BY t.id) tq)
	FROM lat.concepts;

DROP VIEW IF EXISTS lat.pairing_view CASCADE;
CREATE VIEW lat.pairing_view AS
	SELECT id, created_at, thoughts,
		(SELECT row_to_json(c1.*) AS concept1
			FROM lat.concept_view c1 WHERE id=lat.pairings.concept1_id),
		(SELECT row_to_json(c2.*) AS concept2
			FROM lat.concept_view c2 WHERE id=lat.pairings.concept2_id)
	FROM lat.pairings;

