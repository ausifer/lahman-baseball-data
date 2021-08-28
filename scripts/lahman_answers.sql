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
						-- TREND: As games progressed, there was an increase in both so's and hr's. 
SELECT g, ROUND(AVG(b.so),2) AS avg_so,
	ROUND(AVG(b.hr),2) AS avg_hr
FROM batting as b
WHERE yearid >= 1920
GROUP BY g
ORDER BY avg_so;

SELECT * FROM batting;


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
-- 7c. How often from 1970 – 2016 was it the case that a team with the most wins 
--also won the world series? What percentage of the time?
SELECT yearid,
	CASE WHEN wswin='Y' AND 
	--------------------------Here, trying to figure out this one.


-- 8. Using the attendance figures from the homegames table, 
--find the teams and parks which had the top 5 average attendance per game 
---in 2016 (where average attendance is defined as total attendance divided by number of games). 
--Only consider parks where there were at least 10 games played. 
--Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the 
--National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.


-- Open-ended questions

-- Analyze all the colleges in the state of Tennessee. Which college has had the most success in the major leagues. Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc.

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?