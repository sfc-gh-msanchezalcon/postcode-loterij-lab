-- ============================================================
-- POSTCODE LOTERIJ AI LAB — COMPLETE SQL
-- ============================================================
-- This file contains ALL SQL commands from the lab guide.
-- Import it into Workspaces in Snowsight so you don't need to
-- copy-paste individual commands.
--
-- HOW TO USE:
--   1. In Snowsight, click Projects > Workspaces
--   2. Click + > Upload Files and select this file
--   3. Run each block one at a time (select the block, then Ctrl+Enter)
--
-- ============================================================


-- ████████████████████████████████████████████████████████████
-- MODULE 1: FOUNDATION SETUP
-- ████████████████████████████████████████████████████████████

-- ============================================================
-- 1.0 Account settings
-- ============================================================
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ============================================================
-- 1.1 Create database, schemas, and warehouse
-- ============================================================
CREATE OR REPLACE DATABASE POSTCODE_LOTERIJ_AI;
CREATE SCHEMA POSTCODE_LOTERIJ_AI.RAW;
CREATE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

CREATE WAREHOUSE IF NOT EXISTS LOTERIJ_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.RAW;

-- ============================================================
-- 1.2 Charities table
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
-- 1.3 Players table (10,000 synthetic players)
-- ============================================================
CREATE OR REPLACE TABLE PLAYERS AS
WITH
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
        DATEADD('day', -UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()) AS SUBSCRIPTION_START,
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN '3-lot'
            WHEN 2 THEN '3-lot'
            WHEN 3 THEN '2-lot'
            WHEN 4 THEN '2-lot'
            WHEN 5 THEN '2-lot'
            ELSE '1-lot'
        END AS TICKET_TYPE,
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN 45
            WHEN 2 THEN 45
            WHEN 3 THEN 30
            WHEN 4 THEN 30
            WHEN 5 THEN 30
            ELSE 15
        END AS MONTHLY_SPEND,
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
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'Churned'
            WHEN 2 THEN 'Churned'
            WHEN 3 THEN 'Churned'
            WHEN 4 THEN 'Paused'
            ELSE 'Active'
        END AS STATUS,
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
        CASE UNIFORM(1, 15, RANDOM())
            WHEN 1 THEN 'I love playing with my neighbours, it makes winning so much more fun!'
            WHEN 2 THEN 'The charity donations are why I keep playing. Knowing I help nature conservation is important to me.'
            WHEN 3 THEN 'Disappointed that my street never wins. Considering cancelling my subscription.'
            WHEN 4 THEN 'The Postcode Kanjer draw on New Years is the highlight of my year!'
            WHEN 5 THEN 'Too expensive for what you get. The prizes seem to always go to the same areas.'
            WHEN 6 THEN 'Great concept! I signed up after seeing the TV show with the Street Prize.'
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
-- 1.4 Draws table (24 monthly draws)
-- ============================================================
CREATE OR REPLACE TABLE DRAWS AS
WITH draw_dates AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS DRAW_ID,
        DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE())) AS DRAW_DATE,
        CASE
            WHEN MONTH(DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE()))) = 1
            THEN 'Postcode Kanjer'
            WHEN UNIFORM(1, 4, RANDOM()) = 1 THEN 'Street Prize'
            ELSE 'Monthly Prize'
        END AS PRIZE_TYPE,
        CASE
            WHEN MONTH(DATEADD('month', -SEQ4(), DATE_TRUNC('month', CURRENT_DATE()))) = 1
            THEN UNIFORM(50000000, 76900000, RANDOM())
            WHEN UNIFORM(1, 4, RANDOM()) = 1
            THEN UNIFORM(250000, 1000000, RANDOM())
            ELSE UNIFORM(25000, 150000, RANDOM())
        END AS TOTAL_PRIZE_POOL
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
random_postcodes AS (
    SELECT
        POSTCODE,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
    FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
    WHERE STATUS = 'Active'
)
SELECT
    DRAW_ID,
    DRAW_DATE,
    PRIZE_TYPE,
    TOTAL_PRIZE_POOL,
    rp.POSTCODE AS WINNING_POSTCODE
FROM draw_dates dd
JOIN random_postcodes rp ON rp.rn = dd.DRAW_ID;

-- ============================================================
-- 1.5 Tickets table
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
  AND UNIFORM(1, 10, RANDOM()) <= 6;

-- ============================================================
-- 1.6 Donations table
-- ============================================================
CREATE OR REPLACE TABLE DONATIONS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY d.DRAW_ID, c.CHARITY_ID) AS DONATION_ID,
    d.DRAW_ID,
    d.DRAW_DATE,
    c.CHARITY_ID,
    c.CHARITY_NAME,
    c.CATEGORY,
    ROUND(
        (SELECT COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.TICKETS t WHERE t.DRAW_ID = d.DRAW_ID)
        * 15.00
        * 0.40
        * (c.ANNUAL_ALLOCATION_PCT / 100.0)
    , 2) AS DONATION_AMOUNT
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS d
CROSS JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c;

-- ============================================================
-- 1.7 Verify setup
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


-- ████████████████████████████████████████████████████████████
-- MODULE 2: AI ENRICHMENT WITH CORTEX AI FUNCTIONS
-- ████████████████████████████████████████████████████████████

USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- ============================================================
-- 2.1 Sentiment Analysis
-- ============================================================
-- Each test query processes 1 row through an AI model.
-- Expect 10-30 seconds per query — that's normal.
SELECT
    PLAYER_ID,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) AS SENTIMENT_SCORE
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
WHERE FEEDBACK_TEXT != 'No feedback provided.'
LIMIT 1;

-- ============================================================
-- 2.2 Player Segmentation with AI_CLASSIFY
-- ============================================================
SELECT
    p.PLAYER_ID,
    p.PLAYER_NAME,
    AI_CLASSIFY(
        'Player profile: ' || p.STATUS || ' player, ' ||
        p.AGE_GROUP || ' years old, ' ||
        'subscribed for ' || p.TENURE_MONTHS || ' months, ' ||
        'spends EUR' || p.MONTHLY_SPEND || '/month on ' || p.TICKET_TYPE || ', ' ||
        'acquired via ' || p.ACQUISITION_CHANNEL || '. ' ||
        'Feedback: ' || p.FEEDBACK_TEXT,
        ['High-Value Loyal', 'Engaged Regular', 'New Player', 'At-Risk', 'Dormant', 'Price-Sensitive']
    ) AS PLAYER_SEGMENT
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS p
LIMIT 1;

-- ============================================================
-- 2.3 Extract Structured Insights with AI_EXTRACT
-- ============================================================
SELECT
    PLAYER_ID,
    AI_EXTRACT(
        'Player profile: ' || PLAYER_NAME || ', ' || STATUS || ' player from ' || CITY || '. ' ||
        'Age group: ' || AGE_GROUP || '. ' ||
        'Subscribed since ' || SUBSCRIPTION_START::VARCHAR || ' (' || TENURE_MONTHS || ' months). ' ||
        'Plays ' || TICKET_TYPE || ' at EUR' || MONTHLY_SPEND || '/month via ' || ACQUISITION_CHANNEL || '. ' ||
        'Feedback: ' || FEEDBACK_TEXT,
        ['engagement_level', 'churn_risk', 'preferred_channel', 'key_motivation']
    ) AS EXTRACTED_INSIGHTS
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
LIMIT 1;

-- ============================================================
-- 2.4 Summarize Player Profiles
-- ============================================================
SELECT
    PLAYER_ID,
    SNOWFLAKE.CORTEX.SUMMARIZE(
        'Player: ' || PLAYER_NAME || ' from ' || CITY || ' (postcode ' || POSTCODE || '). ' ||
        'Status: ' || STATUS || '. Age: ' || AGE_GROUP || '. ' ||
        'Has been a subscriber since ' || SUBSCRIPTION_START::VARCHAR || ' (' || TENURE_MONTHS || ' months). ' ||
        'Ticket type: ' || TICKET_TYPE || ', monthly spend: EUR' || MONTHLY_SPEND || '. ' ||
        'Came through: ' || ACQUISITION_CHANNEL || '. ' ||
        'Their feedback: "' || FEEDBACK_TEXT || '"'
    ) AS PLAYER_SUMMARY
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
LIMIT 1;

-- ============================================================
-- 2.5 Generate Personalized Retention Messages
-- ============================================================
-- If 'claude-3-5-sonnet' is unavailable, try 'mistral-large2' or 'llama3.1-70b'
SELECT
    PLAYER_ID,
    PLAYER_NAME,
    STATUS,
    SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',
        'Write a short, warm, personalized retention message (max 2 sentences) for this Dutch Postcode Lottery player. ' ||
        'Player: ' || PLAYER_NAME || ', ' || STATUS || ' for ' || TENURE_MONTHS || ' months. ' ||
        'They play ' || TICKET_TYPE || ' and joined via ' || ACQUISITION_CHANNEL || '. ' ||
        'Their feedback was: "' || FEEDBACK_TEXT || '". ' ||
        'The message should encourage continued play and mention charity impact. Write in English.'
    ) AS RETENTION_MESSAGE
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
WHERE STATUS IN ('Churned', 'Paused')
LIMIT 1;

-- ============================================================
-- 2.6 Build the PLAYER_INTELLIGENCE table
-- ============================================================
-- This runs on ALL 10,000 players — expect 2-8 minutes.
-- Good time for a break!
CREATE OR REPLACE TABLE POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE AS
SELECT
    p.PLAYER_ID,
    p.PLAYER_CODE,
    p.PLAYER_NAME,
    p.POSTCODE,
    p.CITY,
    p.SUBSCRIPTION_START,
    p.TICKET_TYPE,
    p.MONTHLY_SPEND,
    p.ACQUISITION_CHANNEL,
    p.STATUS,
    p.AGE_GROUP,
    p.TENURE_MONTHS,
    p.FEEDBACK_TEXT,

    -- AI: Sentiment score
    SNOWFLAKE.CORTEX.SENTIMENT(p.FEEDBACK_TEXT) AS FEEDBACK_SENTIMENT,

    -- AI: Player segment classification
    AI_CLASSIFY(
        'Player profile: ' || p.STATUS || ' player, ' ||
        p.AGE_GROUP || ' years old, ' ||
        'subscribed for ' || p.TENURE_MONTHS || ' months, ' ||
        'spends EUR' || p.MONTHLY_SPEND || '/month on ' || p.TICKET_TYPE || ', ' ||
        'acquired via ' || p.ACQUISITION_CHANNEL || '. ' ||
        'Feedback: ' || p.FEEDBACK_TEXT,
        ['High-Value Loyal', 'Engaged Regular', 'New Player', 'At-Risk', 'Dormant', 'Price-Sensitive']
    ) AS PLAYER_SEGMENT_JSON,

    -- AI: Extracted insights
    AI_EXTRACT(
        'Player profile: ' || p.PLAYER_NAME || ', ' || p.STATUS || ' player from ' || p.CITY || '. ' ||
        'Age group: ' || p.AGE_GROUP || '. ' ||
        'Subscribed since ' || p.SUBSCRIPTION_START::VARCHAR || ' (' || p.TENURE_MONTHS || ' months). ' ||
        'Plays ' || p.TICKET_TYPE || ' at EUR' || p.MONTHLY_SPEND || '/month via ' || p.ACQUISITION_CHANNEL || '. ' ||
        'Feedback: ' || p.FEEDBACK_TEXT,
        ['engagement_level', 'churn_risk', 'preferred_channel', 'key_motivation']
    ) AS EXTRACTED_INSIGHTS_JSON,

    -- Derived: total spend estimate
    p.MONTHLY_SPEND * p.TENURE_MONTHS AS ESTIMATED_LIFETIME_VALUE,

    -- Derived: charity contribution (40% of spend)
    ROUND(p.MONTHLY_SPEND * p.TENURE_MONTHS * 0.40, 2) AS CHARITY_CONTRIBUTION

FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS p;

-- ============================================================
-- 2.6b BACKUP: Load pre-built table from CSV (if 2.6 takes too long)
-- ============================================================
-- The facilitator may have staged a backup CSV. If Step 2.6 is still
-- running after 8 minutes, cancel it and run this instead:
--
-- CREATE OR REPLACE TABLE POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE AS
-- SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE_BACKUP;

-- ============================================================
-- 2.7 Create helper views
-- ============================================================

-- View 1: Player segment summary
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY AS
SELECT
    PLAYER_SEGMENT_JSON:labels[0]::VARCHAR AS SEGMENT,
    COUNT(*) AS PLAYER_COUNT,
    ROUND(AVG(MONTHLY_SPEND), 2) AS AVG_MONTHLY_SPEND,
    ROUND(AVG(FEEDBACK_SENTIMENT), 3) AS AVG_SENTIMENT,
    ROUND(AVG(TENURE_MONTHS), 0) AS AVG_TENURE,
    ROUND(SUM(ESTIMATED_LIFETIME_VALUE), 2) AS TOTAL_LTV,
    ROUND(SUM(CHARITY_CONTRIBUTION), 2) AS TOTAL_CHARITY_IMPACT
FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
GROUP BY SEGMENT;

-- View 2: Charity impact summary
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT AS
SELECT
    c.CHARITY_NAME, c.CATEGORY, c.DESCRIPTION,
    ROUND(SUM(d.DONATION_AMOUNT), 2) AS TOTAL_RECEIVED,
    COUNT(DISTINCT d.DRAW_ID) AS DRAWS_FUNDED
FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS d
JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c ON d.CHARITY_ID = c.CHARITY_ID
GROUP BY c.CHARITY_NAME, c.CATEGORY, c.DESCRIPTION
ORDER BY TOTAL_RECEIVED DESC;

-- View 3: Draw results with winner info
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.DRAW_RESULTS AS
SELECT
    d.DRAW_ID,
    d.DRAW_DATE,
    d.PRIZE_TYPE,
    d.TOTAL_PRIZE_POOL,
    d.WINNING_POSTCODE,
    COUNT(DISTINCT t.PLAYER_ID) AS WINNERS_IN_POSTCODE,
    ROUND(d.TOTAL_PRIZE_POOL / GREATEST(COUNT(DISTINCT t.PLAYER_ID), 1), 2) AS PRIZE_PER_WINNER
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS d
LEFT JOIN POSTCODE_LOTERIJ_AI.RAW.TICKETS t
    ON d.DRAW_ID = t.DRAW_ID AND t.IS_WINNER = TRUE
GROUP BY d.DRAW_ID, d.DRAW_DATE, d.PRIZE_TYPE, d.TOTAL_PRIZE_POOL, d.WINNING_POSTCODE
ORDER BY d.DRAW_DATE DESC;

-- ============================================================
-- 2.8 Verify the enrichment
-- ============================================================
SELECT 'PLAYER_INTELLIGENCE' AS TABLE_NAME, COUNT(*) AS ROWS FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE;

SELECT
    PLAYER_NAME, CITY, STATUS, MONTHLY_SPEND, FEEDBACK_SENTIMENT,
    PLAYER_SEGMENT_JSON, EXTRACTED_INSIGHTS_JSON,
    ESTIMATED_LIFETIME_VALUE, CHARITY_CONTRIBUTION
FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
LIMIT 5;

SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY ORDER BY PLAYER_COUNT DESC;


-- ████████████████████████████████████████████████████████████
-- MODULE 5: SEMANTIC VIEW & CORTEX AGENT
-- ████████████████████████████████████████████████████████████
-- (Module 3 & 4 use the Streamlit UI — no SQL needed)

USE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- ============================================================
-- 5.1 Create the Semantic View
-- ============================================================
CREATE OR REPLACE SEMANTIC VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW

  TABLES (
    player_intelligence AS POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
      PRIMARY KEY (PLAYER_ID)
      COMMENT = 'AI-enriched player data with 10,000 lottery players'
  )

  FACTS (
    player_intelligence.monthly_spend AS MONTHLY_SPEND
      WITH SYNONYMS = ('spend', 'monthly cost', 'payment')
      COMMENT = 'Monthly subscription amount in EUR (15, 30, or 45)',

    player_intelligence.tenure_months AS TENURE_MONTHS
      WITH SYNONYMS = ('tenure', 'months active', 'loyalty')
      COMMENT = 'Number of months since the player subscribed',

    player_intelligence.feedback_sentiment AS FEEDBACK_SENTIMENT
      WITH SYNONYMS = ('sentiment', 'satisfaction', 'mood')
      COMMENT = 'AI sentiment score from -1 (very negative) to +1 (very positive)',

    player_intelligence.estimated_lifetime_value AS ESTIMATED_LIFETIME_VALUE
      WITH SYNONYMS = ('LTV', 'lifetime value', 'total spend')
      COMMENT = 'Total estimated spend: monthly_spend * tenure_months',

    player_intelligence.charity_contribution AS CHARITY_CONTRIBUTION
      WITH SYNONYMS = ('charity impact', 'donation', 'good cause contribution')
      COMMENT = '40% of lifetime value that goes to charity partners'
  )

  DIMENSIONS (
    player_intelligence.player_name AS PLAYER_NAME
      WITH SYNONYMS = ('name', 'speler')
      COMMENT = 'Full name of the player',

    player_intelligence.city AS CITY
      WITH SYNONYMS = ('stad', 'location', 'place')
      COMMENT = 'City where the player lives',

    player_intelligence.postcode AS POSTCODE
      WITH SYNONYMS = ('postal code', 'zip code', 'postcode')
      COMMENT = 'Dutch postcode (4 digits + 2 letters). Players with the same postcode are neighbours and win together.',

    player_intelligence.status AS STATUS
      WITH SYNONYMS = ('player status', 'subscription status')
      COMMENT = 'Current subscription status: Active, Churned, or Paused',

    player_intelligence.age_group AS AGE_GROUP
      WITH SYNONYMS = ('age', 'leeftijd', 'age range')
      COMMENT = 'Age bracket of the player (e.g. 25-35, 45-55)',

    player_intelligence.ticket_type AS TICKET_TYPE
      WITH SYNONYMS = ('lot type', 'subscription type')
      COMMENT = 'Number of lots: 1-lot (EUR 15), 2-lot (EUR 30), or 3-lot (EUR 45)',

    player_intelligence.acquisition_channel AS ACQUISITION_CHANNEL
      WITH SYNONYMS = ('channel', 'source', 'how they joined')
      COMMENT = 'Marketing channel through which the player was acquired',

    player_intelligence.segment AS PLAYER_SEGMENT_JSON:labels[0]::VARCHAR
      WITH SYNONYMS = ('segment', 'player segment', 'classification', 'category')
      COMMENT = 'AI-classified player segment: High-Value Loyal, Engaged Regular, New Player, At-Risk, Dormant, or Price-Sensitive',

    player_intelligence.subscription_start AS SUBSCRIPTION_START
      COMMENT = 'Date the player first subscribed'
  )

  METRICS (
    player_intelligence.player_count AS COUNT(PLAYER_ID)
      WITH SYNONYMS = ('number of players', 'total players', 'how many players')
      COMMENT = 'Total number of players',

    player_intelligence.avg_monthly_spend AS AVG(MONTHLY_SPEND)
      WITH SYNONYMS = ('average spend', 'mean spend')
      COMMENT = 'Average monthly subscription spend in EUR',

    player_intelligence.avg_sentiment AS AVG(FEEDBACK_SENTIMENT)
      WITH SYNONYMS = ('average sentiment', 'mean sentiment', 'happiness score')
      COMMENT = 'Average feedback sentiment score',

    player_intelligence.total_charity_impact AS SUM(CHARITY_CONTRIBUTION)
      WITH SYNONYMS = ('total charity', 'total donations', 'charity total')
      COMMENT = 'Total EUR contributed to charity partners',

    player_intelligence.total_ltv AS SUM(ESTIMATED_LIFETIME_VALUE)
      WITH SYNONYMS = ('total lifetime value', 'total revenue')
      COMMENT = 'Sum of all player lifetime values',

    player_intelligence.avg_tenure AS AVG(TENURE_MONTHS)
      WITH SYNONYMS = ('average tenure', 'how long players stay')
      COMMENT = 'Average number of months players have been subscribed',

    player_intelligence.churn_rate AS
      SUM(CASE WHEN STATUS = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(PLAYER_ID)
      WITH SYNONYMS = ('churn percentage', 'attrition rate')
      COMMENT = 'Percentage of players who have churned'
  )

  COMMENT = 'Postcode Loterij player intelligence - AI-enriched player data with segments, sentiment, and charity impact'
  AI_SQL_GENERATION 'When calculating metrics per segment, use PLAYER_SEGMENT_JSON:labels[0]::VARCHAR as the segment column. Round all monetary values to 2 decimal places and percentages to 1 decimal place.'
;

-- ============================================================
-- 5.2 Verify the Semantic View
-- ============================================================
SHOW SEMANTIC VIEWS IN SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

DESCRIBE SEMANTIC VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW;

-- ============================================================
-- 5.3 Create the Cortex Agent
-- ============================================================
-- If 'claude-4-sonnet' is unavailable, try 'claude-3-5-sonnet' or 'mistral-large2'
CREATE OR REPLACE AGENT POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_AGENT
  COMMENT = 'AI agent for Postcode Loterij player intelligence analysis'
  PROFILE = '{"display_name": "Loterij Intelligence Agent", "color": "red"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-4-sonnet

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    system: >
      You are an analytics assistant for the Postcode Loterij (Dutch Postcode Lottery).
      You help business users understand player data, segment performance, charity impact,
      and retention patterns. Always give specific numbers. When asked for recommendations,
      be actionable and reference the data.
      Keep answers concise — 2-3 paragraphs maximum.

      Key business context:
      - Postcode Loterij is the largest charity lottery in the Netherlands
      - Players subscribe monthly using their postcode as their ticket number
      - Neighbours win together (same postcode = same prize)
      - 40% of all revenue goes to 150+ charity partners
      - Player segments: High-Value Loyal, Engaged Regular, New Player, At-Risk, Dormant, Price-Sensitive

    response: >
      Respond in a friendly but professional manner. Use specific numbers from the data.
      Format large numbers with thousands separators. Use EUR for currency.

    sample_questions:
      - question: "How many active players do we have?"
        answer: "I'll query the player intelligence data to get the current count of active players."
      - question: "What is the average spend by segment?"
        answer: "Let me break down the average monthly spend for each player segment."
      - question: "Which city has the highest churn rate?"
        answer: "I'll analyze churn rates across all cities to find the highest."
      - question: "What is our total charity impact?"
        answer: "I'll calculate the total charity contributions from all players."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "PlayerAnalyst"
        description: "Analyzes Postcode Loterij player data including segments, sentiment, spend, churn, and charity impact"

  tool_resources:
    PlayerAnalyst:
      semantic_view: "POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW"
      execution_environment:
        type: "warehouse"
        warehouse: "LOTERIJ_WH"
  $$;

-- ============================================================
-- 5.5 Set up container runtime (requires external network access)
-- ============================================================
-- NOTE: Steps 5.5-5.8 require external network access, which is
-- not available on trial accounts. Skip to Module 3 if these fail.

-- 1. Create compute pool
CREATE COMPUTE POOL IF NOT EXISTS LOTERIJ_COMPUTE_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300;

-- 2. Network access for PyPI packages
CREATE OR REPLACE NETWORK RULE POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_PYPI_RULE
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('pypi.org', 'files.pythonhosted.org');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION LOTERIJ_PYPI_ACCESS
  ALLOWED_NETWORK_RULES = (POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_PYPI_RULE)
  ENABLED = TRUE;

-- 3. Recreate the Streamlit app with container runtime
--    This replaces the warehouse-based app with a container-based one.
--    You will paste your code back in the Streamlit editor afterwards.
CREATE OR REPLACE STREAMLIT POSTCODE_LOTERIJ_AI.ANALYTICS.POSTCODE_LOTERIJ_APP
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = 'LOTERIJ_WH'
  RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'
  COMPUTE_POOL = 'LOTERIJ_COMPUTE_POOL'
  TITLE = 'Postcode Loterij Intelligence'
  EXTERNAL_ACCESS_INTEGRATIONS = (LOTERIJ_PYPI_ACCESS);

-- 4. After pasting and running the updated code in the Streamlit editor,
--    activate the live version so the app is accessible via its URL.
ALTER STREAMLIT POSTCODE_LOTERIJ_AI.ANALYTICS.POSTCODE_LOTERIJ_APP
  ADD LIVE VERSION FROM LAST;


