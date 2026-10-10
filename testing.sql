-- 7 TEST CASES 

-- Test 1: list all the players that play for a particular department 
-- Expected: 2 rows - Aedan Petty (Data Masters), Kyleigh Phelps (BI Gods)
SELECT p.player_id, p.first_name, p.last_name, t.team_name, g.group_name
FROM players AS p
JOIN groups AS g ON g.group_id = p.group_id  -- obtain group names via a group_id join
JOIN teams AS t ON t.team_id  = p.team_id    -- obtain team names via a team_id join
WHERE g.group_name = 'Cohort 4'               
ORDER BY p.player_id;

-- Test 2: list all the fixtures for a particular date (e.g. 29th Oct 2022)
-- Expected: 2 rows - matches 7 and 8 on 2022-10-29
SELECT m.match_id,
       m.match_datetime,
       home.team_name AS home_team,   -- teams joined once for the home side
       away.team_name AS away_team,   -- and again for the away side
       v.venue_name,
       m.home_score,
       m.away_score
FROM matches AS m
JOIN teams AS home ON home.team_id = m.home_team_id
JOIN teams AS away ON away.team_id = m.away_team_id
JOIN venues AS v ON v.venue_id = m.venue_id
WHERE m.match_datetime::date = DATE '2022-10-29'   -- compare on the date only, ignoring the time
ORDER BY m.match_id;

-- Test 3: list all players who scored more than 2 goals
-- Expected: 4 rows - Ali 5, Dodson 5, Cochran 4, Stevenson 4
SELECT p.player_id,
       p.first_name,
       p.last_name,
       COUNT(*) AS goals_scored        -- one row per goal, so COUNT(*) is used here 
FROM goals AS g
JOIN players AS p ON p.player_id = g.player_id
GROUP BY p.player_id, p.first_name, p.last_name
HAVING COUNT(*) > 2                     -- HAVING filters the grouped totals
ORDER BY goals_scored DESC, p.last_name;

--  Test 4: List the number of cards (yellow and red) per team 
-- Expected: Data Masters 5/0, BI Gods 2/0, Vis Wizards 2/0, Data Cleaners 2/2 (yellow/red)
SELECT t.team_name,
       COUNT(*) FILTER (WHERE c.card_type = 'yellow') AS yellow_cards,
       COUNT(*) FILTER (WHERE c.card_type = 'red') AS red_cards,   -- count each colour separately
       COUNT(*) AS total_cards
FROM cards AS c
JOIN players AS p ON p.player_id = c.player_id  
JOIN teams AS t ON t.team_id = p.team_id    
GROUP BY t.team_name
ORDER BY t.team_name;

-- Test 5: List the games that are going to be played (friendly matches)
-- Expected: 2 rows - matches 13 and 14 (unplayed friendlies)
SELECT m.match_id,
       m.match_datetime,
       home.team_name AS home_team,
       away.team_name AS away_team,
       v.venue_name
FROM matches AS m
JOIN teams AS home ON home.team_id = m.home_team_id
JOIN teams AS away ON away.team_id = m.away_team_id
JOIN venues AS v ON v.venue_id = m.venue_id
WHERE m.match_type = 'friendly'   -- friendlies only
  AND m.home_score IS NULL        -- use AND condition to obtain rows that satisfy both conditions
ORDER BY m.match_datetime;

--  Test 6: Obtain a table displaying the team's name and the points earned during the tournament
-- Expected: Vis Wizards 11, Data Masters 8, BI Gods 8, Data Cleaners 5
WITH results AS (
    -- points earned by each team in its HOME fixtures, we use the sql equivalent of if/else statements
    SELECT home_team_id AS team_id,
           CASE WHEN home_score > away_score THEN 3   -- home win
                WHEN home_score = away_score THEN 1   -- draw
                ELSE 0 END AS points                  -- home loss
    FROM matches
    WHERE match_type = 'league' AND home_score IS NOT NULL  -- exclude friendlies
    UNION ALL                                               -- stack the away results (below) beneath the home results, duplicates included
    -- points earned by each team in its AWAY fixtures
    SELECT away_team_id AS team_id,
           CASE WHEN away_score > home_score THEN 3   -- away win
                WHEN away_score = home_score THEN 1   -- draw
                ELSE 0 END AS points
    FROM matches
    WHERE match_type = 'league' AND home_score IS NOT NULL
)
SELECT t.team_name,
	SUM(r.points) AS points  
FROM teams AS t
JOIN results AS r ON r.team_id = t.team_id  
GROUP BY t.team_name
ORDER BY points DESC, t.team_name;

--  Test 7: List the goals scored and conceded, per team, per half 
-- Expected: 4 rows, scored columns total 32 and conceded columns total 32
WITH goal_detail AS 
(
    SELECT p.team_id AS scoring_team,           			   -- the team that scored
           CASE WHEN p.team_id = m.home_team_id                -- if the scorer is the home team, 
                THEN m.away_team_id 						   -- the away team conceded
				ELSE m.home_team_id END AS conceding_team,     -- otherwise home team conceded the goal
           CASE WHEN g.minute <= 45 
		   		THEN 'First half'          					   -- categorise each goal by minute
                ELSE 'Second half' END AS half
    FROM goals AS g
    JOIN players AS p ON p.player_id = g.player_id  		   -- obtain the team belonging to the scorer
    JOIN matches AS m ON m.match_id  = g.match_id			   -- obtain the match containing the goal
    WHERE m.match_type = 'league'                           
)
SELECT t.team_name,
       COUNT(*) FILTER 
	   		(WHERE gd.scoring_team = t.team_id AND gd.half = 'First half') AS scored_first_half,
       COUNT(*) FILTER 
	   		(WHERE gd.scoring_team = t.team_id AND gd.half = 'Second half') AS scored_second_half,
       COUNT(*) FILTER 
	   		(WHERE gd.conceding_team = t.team_id AND gd.half = 'First half') AS conceded_first_half,
       COUNT(*) FILTER 
	   		(WHERE gd.conceding_team = t.team_id AND gd.half = 'Second half') AS conceded_second_half
FROM teams AS t
LEFT JOIN goal_detail AS gd
       ON t.team_id IN (gd.scoring_team, gd.conceding_team)   -- any goal in a match the team played
GROUP BY t.team_name, t.team_id
ORDER BY t.team_name;