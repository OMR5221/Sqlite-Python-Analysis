-- cd to Documents\Data_Analyst_Work_Product_Folder:
-- open db file and assign as musicians_db:
.open "musicians_example.db" as musicians_db;
.nullvalue "NO DATA"
.headers "on";
.mode "column";
.echo "on";
.output oswaldr_musicians_output.txt

.print "\n"
.print "1. Give the organiser's name of the concert in the Assembly Rooms after the first of Feb, 1997"
.print "\n"

-- Reviewed the concert table(c):
-- use concert_organiser (is a foreign key to the musician_id in the musician table) to get musician_name
-- filter c.concert_venue = 'Assembly Rooms'
-- filter c.concert_date > to_date('02011997', 'mmddyyyy')
-- concert_date in m/d/yy format

SELECT DISTINCT
	m.musician_name as "ORGANISER NAME"
FROM concert c
JOIN musician m
	ON c.concert_orgniser = m.musician_id
WHERE UPPER(TRIM(c.concert_venue)) = 'ASSEMBLY ROOMS'
AND c.concert_date > '2/1/97'
;



.print "\n"
.print "2. List the different instruments played by the musicians and the number of musicians who play the instrument."
.print "\n"

-- select :instrument (text) field is in the performer table, count(distinct performer_id)

SELECT DISTINCT
	p.instrument as "INSTRUMENT",
	count(distinct p.performer_is) AS "NUMBER OF MUSICIANS"
FROM performer p
GROUP BY p.instrument
order by count(distinct p.performer_is) DESC
;

.print "\n"
.print "3. List the names of musicians who have conducted concerts in USA together with the towns and dates of these concerts."
.print "\n"
-- select: m.musician_name, p.place_town, ct.concert_date
-- where: p.place_country = 'USA'

-- Use place.place_id (int - pk) to associate to performance.performed_in (int - fk)
-- use performance.conducted_by(int  - fk) to musician.musician_id (int - pk)
-- left outer join to concert.concert_organizer by lookup to m.musician_id
-- select musician.musician_name, place.place_town, concert.concert_date

SELECT DISTINCT
	m.musician_name AS "MUSICIAN NAME",
	pl.place_town AS "TOWN NAME",
	ct.concert_date AS "CONCERT DATE"
FROM place pl
JOIN performance pf
	ON pl.place_id = pf.performed_in
JOIN musician m
	ON m.musician_id = pf.conducted_by
left join concert ct
	on ct.concert_orgniser = m.musician_id
WHERE UPPER(TRIM(pl.place_country)) = 'USA'
ORDER BY 
	pl.place_town,
	ct.concert_date
;

.print "\n"
.print "4. How many concerts have featured at least one composition by Andy Jones?"
.print "List concert date, venue and the composition's title."
.print "\n"

-- SELECT: ct.concert_date, ct.concert_venue, cp.composition_title
-- JOINS: performance.performed = composition.composition_id
-- WHERE: m.musician_name = 'ANDY JONES' IN has_composed table

.print "a. Per the diagram need to use has_composed.composer_id join to musician.musician_id: NO RESULTS RETURNED"
.print "\n"

SELECT
	CASE 
	WHEN COUNT(hc.composition_id) > 0 then
		'COMPOSITIONS FOUND'
	ELSE 
		'NO COMPOSITIONS FOUND'
	END AS "COMPOSITIONS STATUS"
FROM has_composed hc
JOIN composition cp
	ON cp.composition_id = hc.composition_id
JOIN composer c
	ON c.composer_is = hc.composer_id
JOIN musician m
	on hc.composer_id = m.musician_id
WHERE UPPER(TRIM(m.musician_name)) = 'ANDY JONES'
;

.print "\n"
.print "b. Alternatively if composer.composer_id was also a fk to has_composed.composer_id:"
.print "\n"

/*
	Nested query 2: with has_composed.composer_id join to composer.composer_id
	and M.MUSICIAN_NAME = 'ANDY JONES': 1 result returned

SELECT
	cp.composition_id,
	cp.composition_title,
	m.musician_name
FROM has_composed hc
JOIN composition cp
	ON cp.composition_id = hc.composition_id
-- No line in diagram from hc.composer_id to c.compioser_id but they do have the same values:
JOIN composer c
	on hc.composer_id = c.composer_id
JOIN musician m
	on m.musician_id = c.composer_is
WHERE UPPER(TRIM(m.musician_name)) = 'ANDY JONES'
;
*/

-- Final query using nested query 2 as this return results:

SELECT 
	ct.concert_date AS "CONCERT DATE",
	ct.concert_venue AS "CONCERT VENUE",
	mc.composition_title AS "PERFORMED"
FROM
(
	SELECT
		cp.composition_id,
		cp.composition_title,
		m.musician_name
	FROM has_composed hc
	JOIN composition cp
		ON cp.composition_id = hc.composition_id
	-- No line in diagram from hc.composer_id to c.compioser_id but they do have the same values:
	JOIN composer c
		on hc.composer_id = c.composer_id
	JOIN musician m
		on m.musician_id = c.composer_is
	WHERE UPPER(TRIM(m.musician_name)) = 'ANDY JONES'
) mc
JOIN performance pf
	ON pf.performed = mc.composition_id
JOIN concert ct
	on pf.conducted_by = ct.concert_orgniser
ORDER BY ct.concert_date
;


.print "\n"
.print "5. List the names, dates of birth and the instrument played of living musicians who play a instrument which Theo Mengel also plays.";
.print "\n"

-- select: musician.musician_name, musician.born_on, performer.instrument
-- joins: performer, musician
-- where: m.died_on is null & instrument in (select instrument where musician_name = 'THEO MENGEL')

/*
Subquery: Instrument played by THEO MENGEL:"

SELECT 
	pr.instrument
FROM performer pr
JOIN musician m
	ON m.musician_id = pr.performer_is
WHERE UPPER(TRIM(m.musician_name)) = 'THEO MENGEL'
;
*/

-- UPDATE BLANK SPACE ('') TO NULL:
/*
UPDATE musician
SET died_on = NULL 
WHERE ISNULL(died_on, '')
;
*/

.print "Final query result: Excluding Theo Mengel"
.print "\n"

WITH tm_details AS
(
	SELECT 
		pr.instrument,
		m.musician_id
	FROM performer pr
	JOIN musician m
		ON m.musician_id = pr.performer_is
	WHERE UPPER(TRIM(m.musician_name)) = 'THEO MENGEL'
)
SELECT
	m.musician_name as "MUSICIAN NAME",
	m.born_on AS "DATE OF BIRTH",
	pr.instrument AS "INSTRUMENT PLAYED"
FROM musician m
JOIN performer pr
	ON m.musician_id = pr.performer_is
-- is still alive:
WHERE NULLIF(died_on, '') IS NULL
AND LOWER(pr.instrument) IN
(
	SELECT 
		LOWER(instrument)
	FROM tm_details
)
-- exclude theo mengel:
AND m.musician_id != (SELECT DISTINCT musician_id FROM tm_details)
order by m.musician_name
;

.print "\n"
.print "Final query result: Including Theo Mengel"
.print "\n"

WITH tm_details AS
(
	SELECT 
		pr.instrument,
		m.musician_id
	FROM performer pr
	JOIN musician m
		ON m.musician_id = pr.performer_is
	WHERE UPPER(TRIM(m.musician_name)) = 'THEO MENGEL'
)
SELECT
	m.musician_name as "MUSICIAN NAME",
	m.born_on AS "DATE OF BIRTH",
	pr.instrument AS "INSTRUMENT PLAYED"
FROM musician m
JOIN performer pr
	ON m.musician_id = pr.performer_is
-- is still alive:
WHERE NULLIF(died_on, '') IS NULL
-- (m.died_on IS NULL OR m.died_on = '')
AND LOWER(pr.instrument) IN
(
	SELECT 
		LOWER(instrument)
	FROM tm_details
)
order by m.musician_name
;


.print "\n"
.print "6. List the names of musicians who both conduct and compose and live in England:"
.print "\n"

/*
select: musician.name
joins: musician(LIVING_IN), place, performance(conducted_by), has_composed(composer_id)
where: place_country = 'ENGLAND', EXISTS AS HAS_COMPOSED, EXISTS AS CONDUCTED_BY
*/

.print "Subquery test: 3 results returned due to towns in country England"
.print "\n"
SELECT place_id 
FROM place 
WHERE UPPER(TRIM(place_country, ' ')) = 'ENGLAND'
;

.print "\n"
.print "Final query results:"
.print "\n"

.width 18
with england_towns AS
(
	SELECT place_id 
	FROM place 
	WHERE UPPER(TRIM(place_country, ' ')) = 'ENGLAND'
)
SELECT DISTINCT 
	m.musician_name AS "MUSICIAN"
FROM musician m
WHERE m.living_in in (SELECT place_id FROM england_towns)
-- is a composer: (bool)
and exists
(
	SELECT 
		hc.COMPOSER_ID
	FROM has_composed hc
	WHERE hc.composer_id = m.musician_id
)
-- is a conductor: (bool)
and exists
(
	SELECT 
		pf.conducted_by
	FROM performance pf
	WHERE pf.conducted_by = m.musician_id
)
;


.print "\n"
.print "7. List the bands that have played music composed by Sue Little and the titles of the composition in each case."
.print "\n"

-- SUBQUERY:
/*
	SELECT: composition_id
	from: has_composed
	join: composition, musician
	where: musician_name = 'SUE LITTLE'
*/


-- A. Going by EER Diagram: composer.composer_is is a fk to has_composed.composer_id

-- MAIN QUERY:
/*
	SELECT: BAND_NAME, COMPOSITION_TITLE
	JOINS: BAND, PERFORMANCE, COMPOSITION
	WHERE:  COMPOSITION_ID IN (SUBQUERY)	
*/

-- Found that band_contact not necessarily is player in band
/*
select 
pi.band_id,
pi.player_id,
b.band_contact
from plays_in pi
join band b
on b.band_id = pi.band_id
order by pi.band_id,
pi.player_id
;
*/

WITH sl_compositions AS
(
	select distinct
		hc.composition_id
	from has_composed hc
	join composition cm
		on cm.composition_id = hc.composition_id
	join musician m
		on m.musician_id = hc.composer_id
	WHERE UPPER(TRIM(m.musician_name)) = 'SUE LITTLE'
)
SELECT 
	b.band_name AS "BAND",
	cs.composition_title AS "COMPOSITION TITLE"
FROM performance pf
JOIN composition cs
	ON cs.composition_id = pf.performed
JOIN plays_in pi
	ON player_id = pf.conducted_by
JOIN band b
	on b.band_id = pi.band_id
WHERE pf.performed IN
(
	-- A. SUE LITTLE COMPSITIONS:
	select
		slc.composition_id
	from sl_compositions slc
)
;

-- B. If has_composed.composer_id had linked to composer.composer_id:

/*
select
	hc.composition_id
from has_composed hc
join composer cp
	on cp.composer_id = hc.composer_id
join composition cm
	on cm.composition_id = hc.composition_id
join musician m
	on m.musician_id = cp.composer_is
WHERE UPPER(TRIM(m.musician_name)) = 'SUE LITTLE'
; 


SELECT DISTINCT
	cs.composition_title AS "COMPOSITION TITLE",
	GROUP_CONCAT(DISTINCT UPPER(B.BAND_NAME)) AS "BANDS PLAYED BY"
FROM performance pf
JOIN composition cs
	ON cs.composition_id = pf.performed
JOIN plays_in pi
	ON player_id = pf.conducted_by
JOIN band b
	on b.band_id = pi.band_id
WHERE pf.performed IN
(
	-- B. SUE LITTLE COMPSITIONS:
	select
		hc.composition_id
	from has_composed hc
	join composer cp
		on cp.composer_id = hc.composer_id
	join composition cm
		on cm.composition_id = hc.composition_id
	join musician m
		on m.musician_id = cp.composer_is
	WHERE UPPER(TRIM(m.musician_name)) = 'SUE LITTLE'
)
GROUP BY cs.composition_title
ORDER BY cs.composition_title
;
*/



.print "\n"
.print "8. List the name and town of birth of any performer born in the same city as James First:"
.print "\n"

-- Subquery:
/*
	SELECT: place_id
	FROM: place
	JOINS: MUSICIAN, PLACE
	WHERE: musician_name = 'James First' 
*/

/*
SELECT 
pl.place_id,
pl.place_town,
M.MUSICIAN_ID
FROM place pl
JOIN musician m
	ON m.born_in = pl.place_id
WHERE UPPER(TRIM(m.musician_name)) = 'JAMES FIRST' 
;
*/

-- MAIN QUERY:
/*
	SELECT: musician_NAME, BORN_IN
	FROM: PERFORMER
	JOINS: MUSICIAN, PLACE
	WHERE: PLACE_id = (SUBQUERY)
*/


.print "Including James First:"
.print "\n"

with jf_details AS
(
	SELECT 
		pl.place_id,
		M.MUSICIAN_ID
	FROM place pl
	JOIN musician m
		ON m.born_in = pl.place_id
	WHERE UPPER(TRIM(m.musician_name)) = 'JAMES FIRST'
)
SELECT DISTINCT
	m.musician_name AS "MUSICIAN NAME",
	pl.place_town AS "TOWN"
FROM performer pr
JOIN musician m
	ON m.musician_id = pr.performer_is
JOIN place pl	
	ON m.born_in = pl.place_id
-- Born in same place
WHERE pl.place_id = 
(
	SELECT 
		jfd.place_id
	FROM jf_details jfd
)
;


.print "\n"
.print "Excluding James First:"
.print "\n"

with jf_details AS
(
	SELECT 
		pl.place_id,
		M.MUSICIAN_ID
	FROM place pl
	JOIN musician m
		ON m.born_in = pl.place_id
	WHERE UPPER(TRIM(m.musician_name)) = 'JAMES FIRST'
)
SELECT DISTINCT
	m.musician_name AS "MUSICIAN NAME",
	pl.place_town AS "TOWN"
FROM performer pr
JOIN musician m
	ON m.musician_id = pr.performer_is
JOIN place pl	
	ON m.born_in = pl.place_id
-- Born in same place
WHERE pl.place_id = 
(
	SELECT 
		jfd.place_id
	FROM jf_details jfd
)
-- not JAMES_FIRST
and m.musician_id != 
(
	SELECT 
		jfd.musician_id
	FROM jf_details jfd
)
;


.print "\n"
.print "9. Give a list of musicians associated with Glasgow."
.print "Include the name of the musician and the nature of the association."
.print "\n"

-- With query: Place_id for Glasglow

-- MAIN QUERY:
/*
SELECT: musician_name, association_type(CASE STATEMENT) (born_in, concert_in, living_in, performed_in, composed_in, band_home?)
FROM: Need to use UNION between tables: composition, performance, comcert(not affilaited in eer diagram),
musician, band (no connection in eer diagram), 
JOINS: place, musician, concert, performance, band
WHERE: place_id == 'GLASGOW'

*/

.width 18 36
WITH glasgow AS
(
	SELECT DISTINCT 
		pl.place_id
	FROM place pl
	WHERE UPPER(TRIM(pl.place_town, ' ')) = 'GLASGOW'
)
SELECT DISTINCT
	mq.musician_name AS "MUSICIAN NAME",
	mq.gl_assoc AS "ASSOC TO GLASGOW"
FROM 
(
	-- musician born/living in:
	SELECT 
		m.musician_name,
		CASE 
		WHEN m.born_in = gl.place_id and m.living_in = gl.place_id then
			'WAS BORN IN AND IS LIVING IN'
		WHEN m.born_in = gl.place_id then
			'WAS BORN IN' 
		WHEN m.living_in = gl.place_id then	
			'IS LIVING IN'
		END gl_assoc
	FROM glasgow gl
	JOIN musician m 
		ON (m.born_in = gl.place_id or m.living_in = gl.place_id)
	union all
	-- music composed in Glasgow:
	SELECT 
		m.musician_name,
		'COMPOSED IN' gl_assoc
	FROM composition cs
	JOIN has_composed hc
		ON hc.composition_id = cs.composition_id
	JOIN musician m
		ON m.musician_id = hc.composer_id
	WHERE (cs.composed_in) IN
	(
		SELECT place_id
		from glasgow
	)
	UNION ALL
	-- performace was in Glasgow:
	SELECT 
		m.musician_name,
		'HAD PERFORMANCE IN' gl_assoc
	FROM performance pf
	JOIN musician m
		ON m.musician_id = pf.conducted_by
	WHERE (pf.performed_in) IN
	(
		SELECT place_id
		from glasgow
	)
	/*
	-- Concert was in: Not defined in diagram:
	UNION ALL
	SELECT 
		m.musician_name,
		'HAD CONCERT IN' gl_assoc
	FROM concert ct
	JOIN musician m
		ON m.musician_id = ct.concert_orgniser
	WHERE (ct.concert_in) IN
	(
		SELECT place_id
		from glasgow
	)
	-- Band home: not defined in diagram
	UNION ALL
	SELECT 
		b.band_name musician_name,
		'BAND FORMED IN' gl_assoc
	FROM band b
	JOIN plays_in pi
		ON b.band_id = pi.band_id
	JOIN musician m
		ON m.musician_id = pi.player_id
	WHERE (b.band_home) IN
	(
		SELECT place_id
		from glasgow
	)
	*/
) mq
ORDER BY mq.musician_name
;

.print "\n"
.print "10. Jeff Dawn plays in a band with someone who plays in a band with Sue Little."
.print "Who is it and what are the bands?"
.print "\n"


.print "Checking musicinas in more than 1 band:"
.print "\n"
.width 18 8 12
SELECT DISTINCT
	m.musician_name AS "MUSICIAN",
	count(DISTINCT b.band_id) as "NUM BANDS",
	group_concat(distinct b.band_id) AS "BAND IDS"
FROM plays_in pi
JOIN band b
	ON b.band_id = pi.band_id
JOIN musician m
	ON m.musician_id = pi.player_id
-- Check if player is in the same band as JEFF DAWN:
GROUP BY m.musician_name
having count(distinct b.band_id) > 1
;

.print "\n"
.print "Final Query Results: No players found to be in same bands as Jeff Dawn and Sue Little:"
.print "\n"

.width 56
-- Subqueries: get all bands Jeff Dawn plays in
with jd_bands AS
(
	SELECT distinct
		pi.player_id,
		pi.band_id
	FROM plays_in pi
	JOIN musician m
		ON m.musician_id = pi.player_id
	WHERE UPPER(TRIM(m.musician_name)) = 'JEFF DAWN'
),
-- Get all players in jeff dawn's bands:
jd_players AS
(
	select pi.player_id
	FROM plays_in pi
	WHERE pi.band_id IN
	(
		select 
			band_id
		FROM jd_bands
	)
	-- Exclude Jeff Dawn
	AND pi.player_id != (select player_id from jd_bands)
),
-- Subquery: get all bands Sue Little plays in
sl_bands AS
(
	SELECT distinct
		pi.player_id,
		pi.band_id
	FROM plays_in pi
	JOIN musician m
		ON m.musician_id = pi.player_id
	WHERE UPPER(TRIM(m.musician_name)) = 'SUE LITTLE'
),
-- Get all players in sue littles bands:
sl_players AS
(
	select pi.player_id
	FROM plays_in pi
	WHERE pi.band_id IN
	(
		select 
			band_id
		FROM sl_bands
	)
	-- Exclude Sue Little
	AND pi.player_id != (select player_id from sl_bands)
)
-- MAIN QUERY:
/*
SELECT: musician_name, band_name
FROM: 
JOINS: plays_in, band, musician
WHERE: INTERSECT palyers in bands JEFF DAWN IS IN AND bands SUE LITTLE IS IN
*/
SELECT 
	CASE WHEN COUNT(DISTINCT m.musician_name) > 0 THEN
		printf('%s: %s', m.musician_name, GROUP_CONCAT(DISTINCT UPPER(b.band_name)))
	ELSE
		'No Players in bands with Jeff Dawn and Sue Little'
	END AS "BAND INTERSECT"
FROM plays_in pi
JOIN band b
	ON b.band_id = pi.band_id
JOIN musician m
	ON m.musician_id = pi.player_id
-- Check if player is in the same band JEFF DAWN and SUE LITTLE are in:
WHERE pi.player_id IN
(
	SELECT 
		jdp.player_id
	FROM jd_players jdp
	INTERSECT
	SELECT 
		slp.player_id
	FROM sl_players slp
)
;