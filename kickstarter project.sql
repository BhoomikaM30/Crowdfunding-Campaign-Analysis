use kickstarter_project;
select * from projects;
SELECT 
    DATE_FORMAT(FROM_UNIXTIME(created_at), '%d-%m-%Y') AS created_date,
    DATE_FORMAT(FROM_UNIXTIME(deadline), '%d-%m-%Y') AS deadline_date,
    DATE_FORMAT(FROM_UNIXTIME(updated_at), '%d-%m-%Y') AS updated_date,
    DATE_FORMAT(FROM_UNIXTIME(state_changed_at), '%d-%m-%Y') AS state_changed_date,
    DATE_FORMAT(FROM_UNIXTIME(successful_at), '%d-%m-%Y') AS successful_date,
    DATE_FORMAT(FROM_UNIXTIME(launched_at), '%d-%m-%Y') AS launched_date
FROM projects;
CREATE TABLE calendar (
    calendar_date DATE PRIMARY KEY,
    year INT,
    monthno INT,
    monthfullname VARCHAR(20),
    quarter VARCHAR(2),
    yearmonth VARCHAR(10),
    weekdayno INT,
    weekdayname VARCHAR(20),
    financial_month INT,
    financial_quarter VARCHAR(5)
);
describe calendar;
INSERT INTO calendar
SELECT
    DATE_ADD(
        (SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects),
        INTERVAL n DAY
    ) AS calendar_date,

    YEAR(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)),

    MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)),

    MONTHNAME(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)),

    CONCAT('Q', QUARTER(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY))),

    DATE_FORMAT(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY), '%Y-%b'),

    WEEKDAY(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) + 1,

    DAYNAME(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)),

    CASE 
        WHEN MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) >= 4 
        THEN MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) - 3
        ELSE MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) + 9
    END,

    CASE 
        WHEN MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(DATE_ADD((SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects), INTERVAL n DAY)) BETWEEN 10 AND 12 THEN 'FQ3'
        ELSE 'FQ4'
    END

FROM (
    SELECT a.N + b.N * 10 + c.N * 100 + d.N * 1000 AS n
    FROM 
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
        (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
) numbers
WHERE DATE_ADD(
        (SELECT DATE(FROM_UNIXTIME(MIN(created_at))) FROM projects),
        INTERVAL n DAY
    ) <= (SELECT DATE(FROM_UNIXTIME(MAX(created_at))) FROM projects);
   SELECT * FROM calendar LIMIT 10; ---- This query shows the calendar table Limit 10---
   ---- join projects + Calendar
   SELECT 
    c.year,
    c.monthno,
    c.monthfullname,
    COUNT(*) AS total_projects
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY 
    c.year,
    c.monthno,
    c.monthfullname
ORDER BY 
    c.year,
    c.monthno;
    
    -- KPI: Total number of projects
SELECT 
    COUNT(*) AS total_projects
FROM projects;
    
    ---- KPI : Project By Outcome
    SELECT state, COUNT(*) 
FROM projects
GROUP BY state;


---- KPI : Sucessful Projects summary
SELECT 
    COUNT(*) AS successful_projects,
    SUM(usd_pledged) AS total_amount,
    SUM(backers_count) AS total_backers
FROM projects
WHERE state = 'successful';

----- Kpi  : sucess%
SELECT 
    ROUND(100 * SUM(state = 'successful') / COUNT(*), 2) AS success_rate
FROM projects;

-- KPI: Total number of backers across all projects
SELECT 
    SUM(backers_count) AS total_backers
FROM projects;


---- -- KPI : Total Projects by Year and Month
SELECT 
    c.year,
    c.monthno,
    c.monthfullname,
    COUNT(*) AS total_projects
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY c.year, c.monthno, c.monthfullname
ORDER BY c.year, c.monthno;

-- KPI 5: Number of projects created by Year, Quarter, and Month
SELECT 
    c.year,
    c.quarter,
    c.monthno,
    c.monthfullname,
    COUNT(*) AS total_projects
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY 
    c.year, c.quarter, c.monthno, c.monthfullname
ORDER BY 
    c.year, c.monthno;
    
    
    --- KPI: Total number of projects by country
SELECT 
    country,
    COUNT(*) AS total_projects
FROM projects
GROUP BY country
ORDER BY total_projects DESC;

 -- KPI: Average funding per backer for successful projects
SELECT 
    ROUND(SUM(usd_pledged) / SUM(backers_count), 2) AS avg_amount_per_backer
FROM projects
WHERE state = 'successful';

-- KPI: Success rate based on goal amount range
SELECT 
    CASE 
        WHEN goal < 1000 THEN 'Low Goal (<1000)'
        WHEN goal BETWEEN 1000 AND 10000 THEN 'Medium Goal (1000-10000)'
        ELSE 'High Goal (>10000)'
    END AS goal_range,

    COUNT(*) AS total_projects,

    ROUND(100 * SUM(state = 'successful') / COUNT(*), 2) AS success_rate

FROM projects
GROUP BY goal_range
ORDER BY success_rate DESC;

-- KPI: Percentage of successful projects by month
SELECT 
    c.year,
    c.monthno,
    c.monthfullname,
    ROUND(100 * SUM(p.state = 'successful') / COUNT(*), 2) AS success_rate
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY c.year, c.monthno, c.monthfullname
ORDER BY c.year, c.monthno;

-- KPI: Percentage of successful projects by year
SELECT 
    c.year,
    ROUND(100 * SUM(p.state = 'successful') / COUNT(*), 2) AS success_rate
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY c.year
ORDER BY c.year;

-- KPI: Top 10 successful projects based on number of backers
SELECT 
    name,
    backers_count,
    usd_pledged
FROM projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;

-- KPI: Top 10 successful projects based on amount raised
SELECT 
    name,
    usd_pledged,
    backers_count
FROM projects
WHERE state = 'successful'
ORDER BY usd_pledged DESC
LIMIT 10;

-- KPI: Total amount raised across all projects
SELECT 
    SUM(usd_pledged) AS total_amount_raised
FROM projects;

-- KPI: Average amount raised per project
SELECT 
    AVG(usd_pledged) AS avg_funding
FROM projects;

-- KPI: Percentage of projects that met or exceeded their goal
SELECT 
    ROUND(100 * SUM(usd_pledged >= goal) / COUNT(*), 2) AS funding_success_rate
FROM projects;

-- KPI: Average duration of projects (in days)
SELECT 
    AVG(DATEDIFF(
        DATE(FROM_UNIXTIME(deadline)), 
        DATE(FROM_UNIXTIME(created_at))
    )) AS avg_duration_days
FROM projects;

-- KPI: Average amount contributed per backer
SELECT 
    ROUND(SUM(usd_pledged) / SUM(backers_count), 2) AS avg_amount_per_backer
FROM projects;

-- KPI: Average number of backers per project
SELECT 
    AVG(backers_count) AS avg_backers_per_project
FROM projects;

-- KPI: Month-over-month growth in number of projects
SELECT 
    c.year,
    c.monthno,
    COUNT(*) AS total_projects
FROM projects p
JOIN calendar c
    ON DATE(FROM_UNIXTIME(p.created_at)) = c.calendar_date
GROUP BY c.year, c.monthno
ORDER BY c.year, c.monthno;

-- KPI: Category with highest total funding
SELECT 
    category_id,
    SUM(usd_pledged) AS total_funding
FROM projects
GROUP BY category_id
ORDER BY total_funding DESC
LIMIT 5;

-- KPI: Success percentage by country
SELECT 
    country,
    ROUND(100 * SUM(state = 'successful') / COUNT(*), 2) AS success_rate
FROM projects
GROUP BY country
ORDER BY success_rate DESC;

-- KPI: Number of high-value projects (goal > 10,000 USD)
SELECT 
    COUNT(*) AS high_value_projects
FROM projects
WHERE goal > 10000;

-- KPI: Distribution of projects by backer range
SELECT 
    CASE 
        WHEN backers_count = 0 THEN 'No Backers'
        WHEN backers_count BETWEEN 1 AND 100 THEN 'Low Engagement'
        WHEN backers_count BETWEEN 101 AND 1000 THEN 'Medium Engagement'
        ELSE 'High Engagement'
    END AS backer_category,
    COUNT(*) AS total_projects
FROM projects
GROUP BY backer_category;

-- KPI: Percentage of failed projects
SELECT 
    ROUND(100 * SUM(state = 'failed') / COUNT(*), 2) AS failure_rate
FROM projects;


-- KPI: Compare average goal vs average raised amount
SELECT 
    AVG(goal) AS avg_goal,
    AVG(usd_pledged) AS avg_raised
FROM projects;

























 
   
   
   
   






