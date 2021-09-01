-- 1. What range of years for baseball games played does the provided database cover?
SELECT MAX(yearid),MIN(yearid)
FROM salaries;


-- 2a. Find the name and height of the shortest player in the database. 
SELECT namegiven, height, playerid
FROM people
ORDER BY height
LIMIT 1; 
-- 2b. How many games did he play in? What is the name of the team for which he played?
SELECT teamid, COUNT(*) AS n_games
FROM appearances
WHERE playerid = 'gaedeed01'
GROUP BY teamid;


-- 3. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player’s first and last names as well as the total salary 
--they earned in the major leagues. Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?
SELECT DISTINCT p.namefirst, p.namelast, salary AS total_salary
FROM people AS p
LEFT JOIN collegeplaying AS cp
ON cp.playerid = p.playerid
LEFT JOIN salaries AS s
ON cp.playerid = p.playerid
LEFT JOIN schools AS sc
ON cp.schoolid = sc.schoolid
WHERE sc.schoolname ILIKE '%Vanderbilt%'
GROUP by p.playerid, salary
ORDER BY total_salary DESC;						-- Issues: duplicate names, uncertain if total salary is accurate


-- 4. Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield", those with position "SS", "1B", "2B", 
--and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.
SELECT CASE WHEN pos IN ('OF') THEN 'Outfield' 
		WHEN pos IN ('SS','1B','2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		END AS field,
		SUM(po) AS po
FROM fielding AS f
LEFT JOIN people as p
ON p.playerid = f.playerid
GROUP BY field
ORDER BY po DESC;


-- 5. Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends?
						-- TREND: As time progressed, there was an increase in both so's and hr's. 
SELECT 
	decade, 
	ROUND((avg_so/g),2) AS avg_so_per_game,
	ROUND((avg_hr/g),2) AS avg_hr_per_game
FROM
	(SELECT g,
	ROUND(AVG(b.so),2) AS avg_so,
	ROUND(AVG(b.hr),2) AS avg_hr,
	CASE WHEN yearid BETWEEN 1920 AND 1930 THEN 1920
		WHEN yearid BETWEEN 1930 AND 1940 THEN 1930
		WHEN yearid BETWEEN 1940 AND 1950 THEN 1940
		WHEN yearid BETWEEN 1950 AND 1960 THEN 1950
		WHEN yearid BETWEEN 1960 AND 1970 THEN 1960
		WHEN yearid BETWEEN 1970 AND 1980 THEN 1970
		WHEN yearid BETWEEN 1980 AND 1990 THEN 1980
		WHEN yearid BETWEEN 1990 AND 2000 THEN 1990
		WHEN yearid BETWEEN 2000 AND 2010 THEN 2000
		WHEN yearid BETWEEN 2010 AND 2020 THEN 2010
		END AS decade
FROM batting as b
WHERE yearid >= 1920
GROUP BY decade, g) AS subquery
GROUP BY decade, avg_so
ORDER BY decade;



-- 6. Find the player who had the most success stealing bases in 2016, 
--where success is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) 
--Consider only players who attempted at least 20 stolen bases.
SELECT *
FROM 
(SELECT 
 	p.namegiven, 
 	(CAST(b.sb AS float)/SUM(CAST(b.sb AS float)+CAST(b.cs AS float))) * 100 AS success_rate, 
 	SUM(CAST(b.sb AS float)+CAST(b.cs AS float)) AS attempts 
FROM people AS p
LEFT JOIN batting AS b
ON p.playerid = b.playerid
WHERE sb > 0
 AND yearid = 2016
GROUP BY p.namegiven, b.sb
) AS sub
WHERE 20 <= attempts
ORDER BY success_rate DESC
LIMIT 1;


-- 7a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--What is the smallest number of wins for a team that did win the world series? 
SELECT t.name, w, wswin, yearid
FROM teams AS t
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w, wswin, yearid
ORDER BY w;
--Doing this will probably result in an unusually small number of wins for 
--a world series champion – determine why this is the case.
						--This happened because there was a player strike that year.

SELECT * FROM teams;
-- 7b. Then redo your query, excluding the problem year. 
SELECT *
FROM
(SELECT t.name, w, wswin, yearid
FROM teams AS t
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w, wswin, yearid
ORDER BY w) AS sub
WHERE yearid <> 1981;
-- 7c. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
SELECT team_name, yearid, MAX(w) OVER(PARTITION BY yearid) AS wins_per_year, wswin
FROM
(SELECT t.name AS team_name, w, wswin, yearid
FROM teams AS t
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
GROUP BY name, w, wswin, yearid
ORDER BY w) AS sub
WHERE yearid <> 1981;
--What percentage of the time?
SELECT CAST((SELECT COUNT(*)
			FROM (SELECT team_name, 
				  yearid, 
				  MAX(w) OVER(PARTITION BY yearid) AS wins_per_year, 
				  wswin
				FROM
				(SELECT t.name AS team_name, w, wswin, yearid
					FROM teams AS t
					WHERE wswin = 'Y'
					AND yearid BETWEEN 1970 AND 2016
					GROUP BY name, w, wswin, yearid
					ORDER BY w) AS sub1
			WHERE yearid <> 1981) AS subquery) AS float) /
		CAST((
		SELECT COUNT(DISTINCT yearid) AS total_years
			FROM teams
			WHERE yearid BETWEEN 1970 AND 2016
		) AS float) AS perc_time;
-- 8. Using the attendance figures from the homegames table, 
--find the teams and parks which had the top 5 average attendance per game 
---in 2016 (where average attendance is defined as total attendance divided by number of games).
SELECT t.name AS team_name, p.park_name AS ballpark, AVG(hg.attendance) AS avg_attendance 
FROM homegames AS hg
LEFT JOIN teams AS t
ON hg.team = t.teamid
LEFT JOIN parks AS p
ON p.park = hg.park
WHERE yearid = 2016
GROUP BY team_name, ballpark
ORDER BY avg_attendance DESC
LIMIT 5;
--Only consider parks where there were at least 10 games played. 
SELECT t.name AS team_name, p.park_name AS ballpark, AVG(hg.attendance) AS avg_attendance 
FROM homegames AS hg
LEFT JOIN teams AS t
ON hg.team = t.teamid
LEFT JOIN parks AS p
ON p.park = hg.park
WHERE yearid = 2016
AND 10 <= games
GROUP BY team_name, ballpark
ORDER BY avg_attendance DESC
LIMIT 5;
--Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT t.name AS team_name, p.park_name AS ballpark, AVG(hg.attendance) AS avg_attendance 
FROM homegames AS hg
LEFT JOIN teams AS t
ON hg.team = t.teamid
LEFT JOIN parks AS p
ON p.park = hg.park
WHERE yearid = 2016
AND 10 <= games
GROUP BY team_name, ballpark
ORDER BY avg_attendance
LIMIT 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the 
--National League (NL) and the American League (AL)? 
SELECT am.playerid
FROM awardsmanagers AS am
LEFT JOIN 
	(SELECT playerid, awardid, lgid
		FROM awardsmanagers
		WHERE lgid = 'NL'
		AND awardid = 'TSN Manager of the Year') AS nl_mgr
ON nl_mgr.playerid = am.playerid
WHERE am.lgid = 'AL'
AND am.awardid = 'TSN Manager of the Year'
GROUP BY am.playerid;
--Give their full name and the teams that they were managing when they won the award.
SELECT CONCAT(p.namefirst,' ',p.namelast) AS mgr_name, am.yearid, t.name
FROM awardsmanagers AS am
LEFT JOIN 
	(SELECT playerid, awardid, lgid, yearid
		FROM awardsmanagers
		WHERE lgid = 'NL'
		AND awardid = 'TSN Manager of the Year') AS nl_mgr
ON nl_mgr.playerid = am.playerid AND nl_mgr.yearid = am.yearid
LEFT JOIN people AS p
ON am.playerid = p.playerid
LEFT JOIN appearances AS a
ON p.playerid = a.playerid
LEFT JOIN teams AS t
ON a.teamid = t.teamid AND am.yearid = t.yearid
WHERE am.lgid = 'AL'
AND am.awardid = 'TSN Manager of the Year'
AND t.name IS NOT NULL
GROUP BY mgr_name, am.yearid, t.name
ORDER BY am.yearid;

-- Open-ended questions

-- Analyze all the colleges in the state of Tennessee. Which college has had the most success in the major leagues. Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc.

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?