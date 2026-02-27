-- ============================================================
-- POSTCODE LOTERIJ AI LAB
-- Module 1: Foundation Setup
-- ============================================================
-- This script creates all the infrastructure and synthetic data
-- needed for the hands-on lab.
-- ============================================================

-- 1. Account-level settings (run once)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- 2. Create database and schemas
CREATE OR REPLACE DATABASE POSTCODE_LOTERIJ_AI;
CREATE SCHEMA POSTCODE_LOTERIJ_AI.RAW;
CREATE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- 3. Create warehouse
CREATE WAREHOUSE IF NOT EXISTS LOTERIJ_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.RAW;

-- ============================================================
-- 4. CHARITIES TABLE
-- Real-ish charity partners inspired by actual Postcode Loterij beneficiaries
-- ============================================================
CREATE OR REPLACE TABLE CHARITIES (
    CHARITY_ID INT,
    CHARITY_NAME VARCHAR,
    CATEGORY VARCHAR,
    DESCRIPTION VARCHAR,
    ANNUAL_ALLOCATION_PCT FLOAT
);

INSERT INTO CHARITIES VALUES
(1, 'Natuurmonumenten', 'Nature', 'Protecting natural areas and landscapes across the Netherlands', 4.5),
(2, 'Wereld Natuur Fonds', 'Nature', 'Global wildlife conservation and habitat preservation', 4.2),
(3, 'Rode Kruis Nederland', 'Health', 'Emergency relief and humanitarian aid worldwide', 3.8),
(4, 'Amnesty International', 'Human Rights', 'Protecting human rights and fighting injustice globally', 3.5),
(5, 'UNICEF Nederland', 'Human Rights', 'Supporting children rights and welfare worldwide', 3.5),
(6, 'Greenpeace Nederland', 'Nature', 'Environmental activism and climate change awareness', 3.2),
(7, 'Artsen zonder Grenzen', 'Health', 'Medical humanitarian aid in conflict zones', 3.0),
(8, 'War Child', 'Human Rights', 'Supporting children affected by armed conflict', 2.8),
(9, 'Oxfam Novib', 'Human Rights', 'Fighting poverty and inequality globally', 2.8),
(10, 'Stichting DOEN', 'Culture', 'Supporting green, social and cultural entrepreneurs', 2.5),
(11, 'Vogelbescherming Nederland', 'Nature', 'Bird conservation and habitat protection in the Netherlands', 2.5),
(12, 'SOS Kinderdorpen', 'Human Rights', 'Providing family-based care for orphaned children', 2.3),
(13, 'Nationaal Fonds Kinderhulp', 'Health', 'Supporting children growing up in poverty in the Netherlands', 2.2),
(14, 'Vluchtelingenwerk', 'Human Rights', 'Legal aid and integration support for refugees', 2.0),
(15, 'Milieudefensie', 'Nature', 'Environmental protection and sustainable development', 2.0),
(16, 'Prins Bernhard Cultuurfonds', 'Culture', 'Preserving Dutch cultural heritage and nature', 1.8),
(17, 'Nederlands Openluchtmuseum', 'Culture', 'Living history museum preserving Dutch traditions', 1.5),
(18, 'Stichting Vluchteling', 'Human Rights', 'Emergency aid for refugees in crisis areas', 1.5),
(19, 'IUCN Nederland', 'Nature', 'International nature conservation programs', 1.5),
(20, 'Wakker Dier', 'Nature', 'Animal welfare and sustainable farming advocacy', 1.3),
(21, 'PAX', 'Human Rights', 'Peacebuilding and conflict resolution worldwide', 1.3),
(22, 'Free Press Unlimited', 'Human Rights', 'Supporting independent journalism in restrictive countries', 1.2),
(23, 'Rutgers', 'Health', 'Sexual and reproductive health and rights', 1.2),
(24, 'Urgenda', 'Nature', 'Accelerating the sustainability transition in the Netherlands', 1.0),
(25, 'Stichting de Noordzee', 'Nature', 'Protecting the North Sea ecosystem', 1.0),
(26, 'Global Witness', 'Human Rights', 'Exposing environmental and human rights abuses', 0.9),
(27, 'Rijksmuseum', 'Culture', 'Preserving and sharing Dutch art and history', 0.8),
(28, 'Concertgebouw Fonds', 'Culture', 'Supporting world-class classical music performances', 0.7),
(29, 'JINC', 'Health', 'Providing equal opportunities for underprivileged youth', 0.7),
(30, 'Het Vergeten Kind', 'Health', 'Supporting children in youth care institutions', 0.6);

-- ============================================================
-- 5. PLAYERS TABLE
-- 10,000 synthetic players with realistic Dutch postcodes
-- ============================================================
CREATE OR REPLACE TABLE PLAYERS AS
WITH
-- Generate Dutch postcodes (format: 4 digits + 2 letters)
postcode_pool AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') || ' ' ||
        CHR(UNIFORM(65, 90, RANDOM())) || CHR(UNIFORM(65, 90, RANDOM())) AS POSTCODE,
        CASE UNIFORM(1, 12, RANDOM())
            WHEN 1 THEN 'Amsterdam'
            WHEN 2 THEN 'Rotterdam'
            WHEN 3 THEN 'Den Haag'
            WHEN 4 THEN 'Utrecht'
            WHEN 5 THEN 'Eindhoven'
            WHEN 6 THEN 'Groningen'
            WHEN 7 THEN 'Tilburg'
            WHEN 8 THEN 'Almere'
            WHEN 9 THEN 'Breda'
            WHEN 10 THEN 'Nijmegen'
            WHEN 11 THEN 'Arnhem'
            ELSE 'Maastricht'
        END AS CITY
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
-- Generate 10K players
players_raw AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS PLAYER_ID,
        'PLR-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 6, '0') AS PLAYER_CODE,
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'Jan' WHEN 2 THEN 'Pieter' WHEN 3 THEN 'Maria' WHEN 4 THEN 'Anne'
            WHEN 5 THEN 'Kees' WHEN 6 THEN 'Willem' WHEN 7 THEN 'Sophie' WHEN 8 THEN 'Emma'
            WHEN 9 THEN 'Lucas' WHEN 10 THEN 'Daan' WHEN 11 THEN 'Julia' WHEN 12 THEN 'Lotte'
            WHEN 13 THEN 'Bram' WHEN 14 THEN 'Fleur' WHEN 15 THEN 'Thomas' WHEN 16 THEN 'Lisa'
            WHEN 17 THEN 'Sanne' WHEN 18 THEN 'Niels' WHEN 19 THEN 'Eva' ELSE 'Max'
        END ||' '||
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'de Vries' WHEN 2 THEN 'Jansen' WHEN 3 THEN 'de Boer' WHEN 4 THEN 'van Dijk'
            WHEN 5 THEN 'Bakker' WHEN 6 THEN 'Visser' WHEN 7 THEN 'Smit' WHEN 8 THEN 'Meijer'
            WHEN 9 THEN 'Mulder' WHEN 10 THEN 'de Groot' WHEN 11 THEN 'Bos' WHEN 12 THEN 'Peters'
            WHEN 13 THEN 'Hendriks' WHEN 14 THEN 'van Leeuwen' WHEN 15 THEN 'Dekker'
            WHEN 16 THEN 'Brouwer' WHEN 17 THEN 'de Wit' WHEN 18 THEN 'Dijkstra'
            WHEN 19 THEN 'Vermeer' ELSE 'van den Berg'
        END AS PLAYER_NAME,
        UNIFORM(1, 500, RANDOM()) AS postcode_idx,
        -- Subscription start: between 2015 and 2025
        DATEADD('day', -UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()) AS SUBSCRIPTION_START,
        -- Ticket type
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN '3-lot'
            WHEN 2 THEN '3-lot'
            WHEN 3 THEN '2-lot'
            WHEN 4 THEN '2-lot'
            WHEN 5 THEN '2-lot'
            ELSE '1-lot'
        END AS TICKET_TYPE,
        -- Monthly spend based on ticket type (approx €15 per lot per month)
        CASE
            WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 45.00  -- 3-lot
            WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 30.00  -- 2-lot
            ELSE 15.00  -- 1-lot
        END AS MONTHLY_SPEND,
        -- Acquisition channel
        CASE UNIFORM(1, 8, RANDOM())
            WHEN 1 THEN 'TV Campaign'
            WHEN 2 THEN 'Door-to-door'
            WHEN 3 THEN 'Online'
            WHEN 4 THEN 'Online'
            WHEN 5 THEN 'Referral'
            WHEN 6 THEN 'Direct Mail'
            WHEN 7 THEN 'TV Campaign'
            ELSE 'Social Media'
        END AS ACQUISITION_CHANNEL,
        -- Player status
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'Churned'
            WHEN 2 THEN 'Churned'
            WHEN 3 THEN 'Churned'
            WHEN 4 THEN 'Paused'
            ELSE 'Active'
        END AS STATUS,
        -- Age group
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN '18-25'
            WHEN 2 THEN '25-35'
            WHEN 3 THEN '25-35'
            WHEN 4 THEN '35-45'
            WHEN 5 THEN '35-45'
            WHEN 6 THEN '45-55'
            WHEN 7 THEN '45-55'
            WHEN 8 THEN '55-65'
            WHEN 9 THEN '55-65'
            ELSE '65+'
        END AS AGE_GROUP,
        -- Feedback text (survey response)
        CASE UNIFORM(1, 15, RANDOM())
            WHEN 1 THEN 'I love playing with my neighbours, it makes winning so much more fun!'
            WHEN 2 THEN 'The charity donations are why I keep playing. Knowing I help nature conservation is important to me.'
            WHEN 3 THEN 'Disappointed that my street never wins. Considering cancelling my subscription.'
            WHEN 4 THEN 'The PostcodeKanjer draw on New Years is the highlight of my year!'
            WHEN 5 THEN 'Too expensive for what you get. The prizes seem to always go to the same areas.'
            WHEN 6 THEN 'Great concept! I signed up after seeing the TV show with the StreetPrize.'
            WHEN 7 THEN 'Been playing for 10 years. The charity impact reports are wonderful to read.'
            WHEN 8 THEN 'I think the door-to-door sales tactics are too aggressive. But I like the lottery itself.'
            WHEN 9 THEN 'My neighbour won last month and shared the celebration with the whole street. Amazing community feeling!'
            WHEN 10 THEN 'Would be great to have an app where I can check results and see charity impact in real-time.'
            WHEN 11 THEN 'The monthly prize amount should be higher. Other lotteries offer better odds.'
            WHEN 12 THEN 'Proud supporter since 2005. The work with Natuurmonumenten is close to my heart.'
            WHEN 13 THEN 'Just signed up online. The process was smooth and I like that I can choose extra lots.'
            WHEN 14 THEN 'I paused my subscription due to financial reasons but plan to come back.'
            ELSE 'No feedback provided.'
        END AS FEEDBACK_TEXT
    FROM TABLE(GENERATOR(ROWCOUNT => 10000))
)
SELECT
    p.PLAYER_ID,
    p.PLAYER_CODE,
    p.PLAYER_NAME,
    pc.POSTCODE,
    pc.CITY,
    p.SUBSCRIPTION_START,
    p.TICKET_TYPE,
    p.MONTHLY_SPEND,
    p.ACQUISITION_CHANNEL,
    p.STATUS,
    p.AGE_GROUP,
    p.FEEDBACK_TEXT,
    DATEDIFF('month', p.SUBSCRIPTION_START, CURRENT_DATE()) AS TENURE_MONTHS
FROM players_raw p
JOIN postcode_pool pc ON p.postcode_idx = pc.rn;

-- ============================================================
-- 6. DRAWS TABLE
-- 24 months of monthly draws
-- ============================================================
CREATE OR REPLACE TABLE DRAWS AS
WITH draw_dates AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS DRAW_ID,
        DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE())) AS DRAW_DATE,
        CASE
            WHEN MONTH(DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE()))) = 1
            THEN 'PostcodeKanjer'
            WHEN UNIFORM(1, 4, RANDOM()) = 1 THEN 'StreetPrize'
            ELSE 'MonthlyPrize'
        END AS PRIZE_TYPE,
        CASE
            WHEN MONTH(DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE()))) = 1
            THEN UNIFORM(50000000, 76900000, RANDOM())  -- PostcodeKanjer: €50M-€76.9M
            WHEN UNIFORM(1, 4, RANDOM()) = 1
            THEN UNIFORM(250000, 1000000, RANDOM())      -- StreetPrize: €250K-€1M
            ELSE UNIFORM(25000, 150000, RANDOM())         -- MonthlyPrize: €25K-€150K
        END AS TOTAL_PRIZE_POOL
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
)
SELECT
    DRAW_ID,
    DRAW_DATE,
    PRIZE_TYPE,
    TOTAL_PRIZE_POOL,
    -- Pick a winning postcode from our player pool
    (SELECT POSTCODE FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
     WHERE STATUS = 'Active'
     ORDER BY RANDOM()
     LIMIT 1) AS WINNING_POSTCODE
FROM draw_dates;

-- ============================================================
-- 7. TICKETS TABLE
-- Link players to draws they participated in
-- ============================================================
CREATE OR REPLACE TABLE TICKETS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.PLAYER_ID, d.DRAW_ID) AS TICKET_ID,
    p.PLAYER_ID,
    d.DRAW_ID,
    d.DRAW_DATE,
    p.POSTCODE,
    p.TICKET_TYPE,
    CASE
        WHEN p.POSTCODE = d.WINNING_POSTCODE THEN TRUE
        ELSE FALSE
    END AS IS_WINNER,
    CASE
        WHEN p.POSTCODE = d.WINNING_POSTCODE
        THEN ROUND(d.TOTAL_PRIZE_POOL / GREATEST(
            (SELECT COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS p2
             WHERE p2.POSTCODE = d.WINNING_POSTCODE AND p2.STATUS = 'Active'), 1
        ), 2)
        ELSE 0
    END AS PRIZE_WON
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS p
CROSS JOIN POSTCODE_LOTERIJ_AI.RAW.DRAWS d
WHERE p.STATUS = 'Active'
  AND p.SUBSCRIPTION_START <= d.DRAW_DATE
  -- Sample ~60% participation per draw to keep it realistic
  AND UNIFORM(1, 10, RANDOM()) <= 6;

-- ============================================================
-- 8. DONATIONS TABLE
-- How each draw's revenue was allocated to charities
-- ============================================================
CREATE OR REPLACE TABLE DONATIONS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY d.DRAW_ID, c.CHARITY_ID) AS DONATION_ID,
    d.DRAW_ID,
    d.DRAW_DATE,
    c.CHARITY_ID,
    c.CHARITY_NAME,
    c.CATEGORY,
    -- 40% of estimated revenue goes to charity, split by allocation percentage
    ROUND(
        (SELECT COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.TICKETS t WHERE t.DRAW_ID = d.DRAW_ID)
        * 15.00  -- avg ticket price
        * 0.40   -- 40% to charity
        * (c.ANNUAL_ALLOCATION_PCT / 100.0)
    , 2) AS DONATION_AMOUNT
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS d
CROSS JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c;

-- ============================================================
-- 9. Quick verification
-- ============================================================
SELECT 'PLAYERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
UNION ALL
SELECT 'DRAWS', COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS
UNION ALL
SELECT 'TICKETS', COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.TICKETS
UNION ALL
SELECT 'CHARITIES', COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.CHARITIES
UNION ALL
SELECT 'DONATIONS', COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS
ORDER BY TABLE_NAME;

-- ============================================================
-- 10. Explore the data
-- ============================================================

-- How many players per city?
SELECT CITY, COUNT(*) AS PLAYER_COUNT
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
GROUP BY CITY ORDER BY PLAYER_COUNT DESC;

-- Player status distribution
SELECT STATUS, COUNT(*) AS CNT,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS PCT
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
GROUP BY STATUS ORDER BY CNT DESC;

-- Draws overview
SELECT DRAW_ID, DRAW_DATE, PRIZE_TYPE, TOTAL_PRIZE_POOL, WINNING_POSTCODE
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS
ORDER BY DRAW_DATE DESC;

-- Total charity impact
SELECT
    CATEGORY,
    ROUND(SUM(DONATION_AMOUNT), 2) AS TOTAL_DONATED,
    COUNT(DISTINCT CHARITY_ID) AS NUM_CHARITIES
FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS
GROUP BY CATEGORY
ORDER BY TOTAL_DONATED DESC;
