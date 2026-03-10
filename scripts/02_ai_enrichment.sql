-- ============================================================
-- POSTCODE LOTERIJ AI LAB
-- Module 2: AI Enrichment with Cortex AI Functions
-- ============================================================
-- This script uses Snowflake Cortex AI functions to enrich
-- our player data with intelligence — no external APIs needed.
-- ============================================================

USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- ============================================================
-- STEP 1: Sentiment Analysis on Player Feedback
-- ============================================================
-- SNOWFLAKE.CORTEX.SENTIMENT scores text from -1 (negative) to +1 (positive)
-- Let's see how our players feel!

-- First, test on a single row:
SELECT
    PLAYER_ID,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) AS SENTIMENT_SCORE
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
WHERE FEEDBACK_TEXT != 'No feedback provided.'
LIMIT 1;

-- ============================================================
-- STEP 2: Classify Players into Segments using AI
-- ============================================================
-- AI_CLASSIFY automatically categorizes text into labels you define.
-- We'll classify players based on a profile description.

-- Test on a single row:
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
-- STEP 3: Extract Structured Insights with AI_EXTRACT
-- ============================================================
-- AI_EXTRACT pulls specific fields from unstructured text.

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
-- STEP 4: Summarize Player Profiles
-- ============================================================
-- SNOWFLAKE.CORTEX.SUMMARIZE creates concise summaries.

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
-- STEP 5: Generate Personalized Retention Messages
-- ============================================================
-- SNOWFLAKE.CORTEX.COMPLETE generates text using an LLM.
-- Perfect for creating personalized outreach!

SELECT
    PLAYER_ID,
    PLAYER_NAME,
    STATUS,
    SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',  -- If this model is unavailable, try 'mistral-large2' or 'llama3.1-70b'
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
-- STEP 6: Build the PLAYER_INTELLIGENCE table
-- ============================================================
-- Now let's combine everything into one enriched table.
-- We run on ALL players (this may take a few minutes with 10K rows).

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
-- STEP 7: Create helper views for the Streamlit app
-- ============================================================

-- Player segment summary
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

-- Charity impact summary
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT AS
SELECT
    c.CHARITY_NAME,
    c.CATEGORY,
    c.DESCRIPTION,
    ROUND(SUM(d.DONATION_AMOUNT), 2) AS TOTAL_RECEIVED,
    COUNT(DISTINCT d.DRAW_ID) AS DRAWS_FUNDED
FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS d
JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c ON d.CHARITY_ID = c.CHARITY_ID
GROUP BY c.CHARITY_NAME, c.CATEGORY, c.DESCRIPTION
ORDER BY TOTAL_RECEIVED DESC;

-- Draw results with winner info
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
-- STEP 8: Verify the enrichment
-- ============================================================
SELECT 'PLAYER_INTELLIGENCE' AS TABLE_NAME, COUNT(*) AS ROWS FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE;

-- Sample enriched data
SELECT
    PLAYER_NAME, CITY, STATUS, MONTHLY_SPEND, FEEDBACK_SENTIMENT,
    PLAYER_SEGMENT_JSON, EXTRACTED_INSIGHTS_JSON,
    ESTIMATED_LIFETIME_VALUE, CHARITY_CONTRIBUTION
FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
LIMIT 5;

-- Segment distribution
SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY ORDER BY PLAYER_COUNT DESC;

-- Top charities by donations
SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT LIMIT 10;
