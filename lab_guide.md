<p align="center">
  <img src="assets/banner.svg" alt="Postcode Loterij AI Lab" width="100%">
</p>

<h1 align="center">Postcode Loterij AI Lab</h1>

<p align="center">
  <b>Hands-on: Building AI-Powered Player Intelligence with Snowflake</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Duration-1.5_hours-E40421?style=for-the-badge" alt="Duration: 1.5 hours">
  <img src="https://img.shields.io/badge/Level-Beginner_to_Advanced-0069B4?style=for-the-badge" alt="Level: Beginner to Advanced">
  <img src="https://img.shields.io/badge/Platform-Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white" alt="Platform: Snowflake">
</p>

---

## What You Will Build

In this lab you will create an end-to-end AI-powered analytics solution — entirely within Snowflake. No external APIs, no additional tools, no data leaving your account.

By the end you will have:

1. **Synthetic lottery data** — 10,000 players, 24 months of draws, 30 charity partners
2. **AI-enriched player intelligence** — sentiment analysis, segmentation, insights extraction, and personalized messages using Cortex AI
3. **An interactive Streamlit dashboard** — branded with Postcode Loterij colors, featuring player KPIs, charts, a live winner draft with animation, and an AI chatbot
4. **A Semantic View & Cortex Agent** — a business-friendly data model that powers a natural language AI agent

### Architecture Overview

```
                       SNOWFLAKE ACCOUNT
    ┌─────────────────────────────────────────────────────┐
    │                                                     │
    │  ┌─────────┐   Cortex AI    ┌──────────────┐       │
    │  │ RAW     │ ────────────>  │ ANALYTICS    │       │
    │  │ Schema  │  Sentiment     │ Schema       │       │
    │  │         │  Classify      │              │       │
    │  │ PLAYERS │  Extract       │ PLAYER_      │       │
    │  │ DRAWS   │                │ INTELLIGENCE │       │
    │  │ TICKETS │                │              │       │
    │  │ CHARITIES│               │ Views        │       │
    │  │ DONATIONS│               └──────┬───────┘       │
    │  └─────────┘                       │               │
    │                          ┌─────────▼──────────┐    │
    │                          │ SEMANTIC VIEW       │    │
    │                          │ Business data model │    │
    │                          └─────────┬──────────┘    │
    │                    ┌───────────────┼────────┐      │
    │            ┌───────▼────────┐  ┌───▼──────┐ │      │
    │            │ STREAMLIT APP  │  │ CORTEX   │ │      │
    │            │ Dashboard      │  │ AGENT    │ │      │
    │            │ Winner Draft   │  │ NL → SQL │ │      │
    │            │ AI Chatbot     │  └──────────┘ │      │
    │            └────────────────┘               │      │
    │                                             │      │
    └─────────────────────────────────────────────────────┘
```

---

## Lab Agenda

| # | Module | Duration |
|:-:|--------|:--------:|
| 0 | **Environment Setup** | 5 min |
| 1 | **Foundation** — Create Database & Synthetic Data | 15 min |
| 2 | **AI Enrichment** — Cortex AI Functions | 25 min |
| 3 | **Streamlit Dashboard** — Build & Deploy | 20 min |
| 4 | **Explore** — Interact with the App | 10 min |
| 5 | **Semantic View & Cortex Agent** | 15 min |
| + | **Bonus** — Cortex Code Challenge | 15 min |

---

<img src="https://img.shields.io/badge/Module_0-Environment_Setup-E40421?style=flat-square" alt="Module 0">

## Module 0 — Environment Setup (5 min)

### 0.1 Log into Snowflake

1. Open your Snowflake account URL in a browser
2. Log in with the credentials provided by your instructor
3. You should see **Snowsight** — the Snowflake web interface

> **What is Snowsight?** Snowsight is Snowflake's built-in web interface. It is where you write SQL, build dashboards, manage data, and create apps — all from the browser. There is nothing to install.

### 0.2 Open a SQL Worksheet

A SQL Worksheet is where you write and run SQL commands against Snowflake.

1. In the left sidebar, click **Projects** > **Worksheets**
2. Click the blue **+** button in the top-right corner
3. Select **SQL Worksheet** from the dropdown
4. A new worksheet opens. Click on the tab name (top-left, it will say something like "Untitled") and rename it to `Postcode Loterij Lab`

> **Tip**: You can run individual SQL statements by placing your cursor on a statement and pressing **Ctrl+Enter** (Windows) or **Cmd+Enter** (Mac). To run multiple statements, select them all first, then press the same shortcut.

### 0.3 Set Your Role and Enable Cross-Region AI

Copy and run the following two statements in your worksheet:

```sql
-- Use the ACCOUNTADMIN role (gives full permissions for this lab)
USE ROLE ACCOUNTADMIN;

-- Enable Cortex AI across regions
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
```

You should see `Statement executed successfully.` for each.

> **What is a Role?** In Snowflake, a *role* controls what you can do. `ACCOUNTADMIN` is the most powerful role — it can create databases, warehouses, and manage account settings. In production you would use more restricted roles, but for this lab we need full access.

> **Why cross-region?** Snowflake Cortex AI functions (like sentiment analysis or LLM calls) run on specialized AI infrastructure hosted in specific cloud regions. If your Snowflake account is in a region without AI infrastructure, this setting allows your requests to be securely routed to the nearest available region. Your data stays encrypted in transit.

---

<img src="https://img.shields.io/badge/Module_1-Foundation_Setup-E40421?style=flat-square" alt="Module 1">

## Module 1 — Foundation Setup (15 min)

> **Goal**: Create the database, warehouse, and generate synthetic data that represents Postcode Loterij's business.

### 1.1 Create Database, Schemas, and Warehouse

Copy and run this block:

```sql
-- Create a database to hold all our lab data
CREATE OR REPLACE DATABASE POSTCODE_LOTERIJ_AI;

-- Create two schemas: one for raw data, one for AI-enriched analytics
CREATE SCHEMA POSTCODE_LOTERIJ_AI.RAW;
CREATE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- Create a compute warehouse to run our queries
CREATE WAREHOUSE IF NOT EXISTS LOTERIJ_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- Tell Snowflake to use this warehouse and schema for the next queries
USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.RAW;
```

> **Snowflake Concepts — Database, Schema, Warehouse:**
>
> | Concept | What it is | Analogy |
> |---------|-----------|---------|
> | **Database** | A container for your data | Like a filing cabinet |
> | **Schema** | A folder within a database that groups related tables | Like a drawer in the filing cabinet |
> | **Warehouse** | A compute engine that runs your queries | Like an employee who does the work |
>
> The warehouse does *not* store data — it only provides compute power. When idle, it automatically suspends (pauses) to save costs, and automatically resumes when you run a query. `MEDIUM` gives us enough power for AI workloads.
>
> We create two schemas: `RAW` for our source data, and `ANALYTICS` for AI-enriched results. This separation is a best practice in data engineering.

### 1.2 Create the Charities Table

Postcode Loterij donates 40% of its revenue to 150+ charity partners. We'll create a table with 30 realistic charity entries:

```sql
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
```

You should see: `number of rows inserted: 30`

> **What is `CREATE OR REPLACE TABLE`?** This creates a new table (or replaces it if it already exists). The column definitions inside the parentheses define the table structure. Then `INSERT INTO ... VALUES` adds data row by row. This is ideal for small reference tables like our charity list.

### 1.3 Generate 10,000 Synthetic Players

This is the largest table. Instead of loading data from a file, we use Snowflake's built-in data generation functions to create 10,000 realistic player records.

**Select and run this entire block** (it's one single SQL statement):

```sql
CREATE OR REPLACE TABLE PLAYERS AS
WITH
-- Step A: Generate 500 unique Dutch postcodes (format: "1234 AB")
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
-- Step B: Generate 10K player records
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
            WHEN 1 THEN '3-lot' WHEN 2 THEN '3-lot'
            WHEN 3 THEN '2-lot' WHEN 4 THEN '2-lot' WHEN 5 THEN '2-lot'
            ELSE '1-lot'
        END AS TICKET_TYPE,
        CASE
            WHEN UNIFORM(1, 10, RANDOM()) <= 2 THEN 45.00
            WHEN UNIFORM(1, 10, RANDOM()) <= 5 THEN 30.00
            ELSE 15.00
        END AS MONTHLY_SPEND,
        CASE UNIFORM(1, 8, RANDOM())
            WHEN 1 THEN 'TV Campaign' WHEN 2 THEN 'Door-to-door'
            WHEN 3 THEN 'Online' WHEN 4 THEN 'Online'
            WHEN 5 THEN 'Referral' WHEN 6 THEN 'Direct Mail'
            WHEN 7 THEN 'TV Campaign' ELSE 'Social Media'
        END AS ACQUISITION_CHANNEL,
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'Churned' WHEN 2 THEN 'Churned' WHEN 3 THEN 'Churned'
            WHEN 4 THEN 'Paused'
            ELSE 'Active'
        END AS STATUS,
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN '18-25' WHEN 2 THEN '25-35' WHEN 3 THEN '25-35'
            WHEN 4 THEN '35-45' WHEN 5 THEN '35-45'
            WHEN 6 THEN '45-55' WHEN 7 THEN '45-55'
            WHEN 8 THEN '55-65' WHEN 9 THEN '55-65'
            ELSE '65+'
        END AS AGE_GROUP,
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
-- Step C: Join players with postcodes
SELECT
    p.PLAYER_ID, p.PLAYER_CODE, p.PLAYER_NAME, pc.POSTCODE, pc.CITY,
    p.SUBSCRIPTION_START, p.TICKET_TYPE, p.MONTHLY_SPEND, p.ACQUISITION_CHANNEL,
    p.STATUS, p.AGE_GROUP, p.FEEDBACK_TEXT,
    DATEDIFF('month', p.SUBSCRIPTION_START, CURRENT_DATE()) AS TENURE_MONTHS
FROM players_raw p
JOIN postcode_pool pc ON p.postcode_idx = pc.rn;
```

You should see: `Table PLAYERS successfully created.`

> **Snowflake Concepts — Data Generation:**
>
> | Function | What it does |
> |----------|-------------|
> | `GENERATOR(ROWCOUNT => N)` | Creates N empty rows — no source table needed |
> | `UNIFORM(min, max, RANDOM())` | Generates a random integer between min and max |
> | `RANDOM()` | Provides a random seed |
> | `CHR(65)` to `CHR(90)` | Converts numbers to letters A-Z |
> | `DATEDIFF('month', start, end)` | Calculates difference between two dates |
>
> The `CREATE TABLE ... AS SELECT` pattern (called **CTAS**) creates a table and fills it with query results in one step. The `WITH` clause defines temporary named subqueries (CTEs) that only exist during this query.

### 1.4 Generate Draws, Tickets, and Donations

Now we create three more tables. **Run each statement separately** (place your cursor on it and press Ctrl/Cmd+Enter), or select all three and run together:

```sql
-- DRAWS: 24 months of lottery draws
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
            THEN UNIFORM(50000000, 76900000, RANDOM())
            WHEN UNIFORM(1, 4, RANDOM()) = 1
            THEN UNIFORM(250000, 1000000, RANDOM())
            ELSE UNIFORM(25000, 150000, RANDOM())
        END AS TOTAL_PRIZE_POOL
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
)
SELECT
    DRAW_ID, DRAW_DATE, PRIZE_TYPE, TOTAL_PRIZE_POOL,
    (SELECT POSTCODE FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
     WHERE STATUS = 'Active' ORDER BY RANDOM() LIMIT 1) AS WINNING_POSTCODE
FROM draw_dates;
```

```sql
-- TICKETS: link players to the draws they participated in
CREATE OR REPLACE TABLE TICKETS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.PLAYER_ID, d.DRAW_ID) AS TICKET_ID,
    p.PLAYER_ID, d.DRAW_ID, d.DRAW_DATE, p.POSTCODE, p.TICKET_TYPE,
    CASE WHEN p.POSTCODE = d.WINNING_POSTCODE THEN TRUE ELSE FALSE END AS IS_WINNER,
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
```

```sql
-- DONATIONS: how each draw's revenue is allocated to charities
CREATE OR REPLACE TABLE DONATIONS AS
SELECT
    ROW_NUMBER() OVER (ORDER BY d.DRAW_ID, c.CHARITY_ID) AS DONATION_ID,
    d.DRAW_ID, d.DRAW_DATE, c.CHARITY_ID, c.CHARITY_NAME, c.CATEGORY,
    ROUND(
        (SELECT COUNT(*) FROM POSTCODE_LOTERIJ_AI.RAW.TICKETS t WHERE t.DRAW_ID = d.DRAW_ID)
        * 15.00 * 0.40 * (c.ANNUAL_ALLOCATION_PCT / 100.0)
    , 2) AS DONATION_AMOUNT
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS d
CROSS JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c;
```

> **What is a CROSS JOIN?** A `CROSS JOIN` combines every row from one table with every row from another. For DONATIONS, we combine each of 24 draws with each of 30 charities = 720 donation records. For TICKETS, we combine active players with draws, then filter to ~60% participation using `UNIFORM(1, 10, RANDOM()) <= 6`.

### 1.5 Verify Your Data

Run this to confirm everything was created:

```sql
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
```

**Expected results** (your TICKETS count will differ due to random sampling):

| TABLE_NAME | ROW_COUNT |
|------------|-----------|
| CHARITIES  | 30        |
| DONATIONS  | 720       |
| DRAWS      | 24        |
| PLAYERS    | 10,000    |
| TICKETS    | ~100,000-120,000 |

> **Checkpoint**: If your PLAYERS count is 10,000 and all other tables have data, you are on track. The exact TICKETS count varies because we randomly sampled ~60% participation per draw.

### 1.6 Explore Your Data (Optional)

If you finish early or are curious, run a few queries to get a feel for the data:

```sql
-- How many players per city?
SELECT CITY, COUNT(*) AS PLAYER_COUNT
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
GROUP BY CITY ORDER BY PLAYER_COUNT DESC;

-- Player status breakdown
SELECT STATUS, COUNT(*) AS CNT,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS PCT
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
GROUP BY STATUS ORDER BY CNT DESC;

-- Total charity donations by category
SELECT CATEGORY, ROUND(SUM(DONATION_AMOUNT), 2) AS TOTAL_DONATED,
       COUNT(DISTINCT CHARITY_ID) AS NUM_CHARITIES
FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS
GROUP BY CATEGORY ORDER BY TOTAL_DONATED DESC;
```

---

<img src="https://img.shields.io/badge/Module_2-AI_Enrichment-E40421?style=flat-square" alt="Module 2">

## Module 2 — AI Enrichment with Cortex AI (25 min)

> **Goal**: Use five different Snowflake Cortex AI functions to transform raw player data into actionable intelligence — all running directly inside Snowflake SQL, no external APIs.

### What is Snowflake Cortex AI?

Cortex AI is a set of built-in AI functions that run directly in Snowflake. They work just like regular SQL functions — you call them in a `SELECT` statement and they return results. The key difference: these functions are powered by large language models (LLMs) and machine learning models running inside Snowflake's infrastructure.

**Your data never leaves Snowflake.** There are no external API calls, no data exports, no third-party services involved.

### 2.0 Set Your Context

Before starting, make sure you're using the right warehouse and schema:

```sql
USE WAREHOUSE LOTERIJ_WH;
USE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;
```

### 2.1 Sentiment Analysis

Our first AI function: `SNOWFLAKE.CORTEX.SENTIMENT`. It scores text on a scale from **-1** (very negative) to **+1** (very positive).

**Test it on 3 rows first** to see how it works:

```sql
SELECT
    PLAYER_ID,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) AS SENTIMENT_SCORE
FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
WHERE FEEDBACK_TEXT != 'No feedback provided.'
LIMIT 3;
```

**What to look for**: Compare the feedback text with the score. A player saying *"I love playing with my neighbours"* should have a high positive score. A player saying *"Too expensive for what you get"* should have a negative score.

> **How it works**: `SNOWFLAKE.CORTEX.SENTIMENT` uses a pre-trained NLP model to analyze text. You don't need to train anything or provide examples — it works out of the box on any text in any supported language.

### 2.2 Player Segmentation with AI_CLASSIFY

`AI_CLASSIFY` automatically categorizes text into labels **you define**. We give it a player profile description and ask it to classify into one of 6 segments:

```sql
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
LIMIT 3;
```

**What to look for**: The result is a JSON object like `{"labels":["High-Value Loyal"]}`. The AI reads the entire profile and picks the most appropriate label from your array.

> **How it works**: `AI_CLASSIFY` takes two arguments: (1) the text to classify, and (2) an array of possible labels. The AI model reads the text and determines which label fits best. No training data needed — you define the categories and the AI figures out the rest. This is called **zero-shot classification**.

### 2.3 Extract Structured Insights with AI_EXTRACT

`AI_EXTRACT` pulls specific named fields from unstructured text — turning free-form text into structured data:

```sql
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
LIMIT 3;
```

**What to look for**: The result is a JSON object with each field you requested, e.g., `{"engagement_level": "high", "churn_risk": "low", ...}`. The AI interprets what each field name means in context.

> **How it works**: `AI_EXTRACT` takes text and an array of field names. The AI reads the text and fills in values for each field. You can use *any* field names — the AI infers what you mean from the name itself. Try changing the field names to things relevant to your own business!

### 2.4 Summarize Player Profiles

`SNOWFLAKE.CORTEX.SUMMARIZE` creates concise summaries from longer text:

```sql
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
LIMIT 3;
```

> **Use case**: Imagine having 10,000 customer profiles. Instead of reading each one, you get a one-sentence summary. This is useful for customer service, account management, and reporting.

### 2.5 Generate Personalized Retention Messages

`SNOWFLAKE.CORTEX.COMPLETE` is the most powerful function — it generates text using a large language model (LLM). Here we create personalized win-back messages for churned players:

```sql
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
LIMIT 3;
```

**What to look for**: Each player gets a unique, personalized message that references their specific feedback and situation. This is AI-generated marketing copy running directly in SQL.

> **How it works**: `SNOWFLAKE.CORTEX.COMPLETE` takes two arguments: (1) the model name (e.g., `'claude-3-5-sonnet'`), and (2) a text prompt. The LLM generates a response based on the prompt. You can use this for any text generation task — emails, reports, translations, code, and more. The first argument selects which LLM to use; Snowflake supports several models.

### 2.6 Build the PLAYER_INTELLIGENCE Table

Now we combine the AI functions into one enriched table. **This runs on all 10,000 players and will take 2-5 minutes**:

```sql
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

    -- AI: Sentiment score (-1 to +1)
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

    -- AI: Extracted structured insights
    AI_EXTRACT(
        'Player profile: ' || p.PLAYER_NAME || ', ' || p.STATUS || ' player from ' || p.CITY || '. ' ||
        'Age group: ' || p.AGE_GROUP || '. ' ||
        'Subscribed since ' || p.SUBSCRIPTION_START::VARCHAR || ' (' || p.TENURE_MONTHS || ' months). ' ||
        'Plays ' || p.TICKET_TYPE || ' at EUR' || p.MONTHLY_SPEND || '/month via ' || p.ACQUISITION_CHANNEL || '. ' ||
        'Feedback: ' || p.FEEDBACK_TEXT,
        ['engagement_level', 'churn_risk', 'preferred_channel', 'key_motivation']
    ) AS EXTRACTED_INSIGHTS_JSON,

    -- Derived: estimated lifetime value
    p.MONTHLY_SPEND * p.TENURE_MONTHS AS ESTIMATED_LIFETIME_VALUE,

    -- Derived: charity contribution (40% of total spend)
    ROUND(p.MONTHLY_SPEND * p.TENURE_MONTHS * 0.40, 2) AS CHARITY_CONTRIBUTION

FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS p;
```

> **While it runs** (2-5 min): This query calls three AI functions per row across 10,000 rows. Snowflake parallelizes this automatically across the warehouse. Think about how long this would take with external API calls — you would need to manage rate limits, authentication, network latency, and data transfer. Here, it's just SQL.

### 2.7 Create Helper Views

Views are saved queries that act like virtual tables. They don't store data — they run the query every time you access them. We create three views to pre-aggregate data for the dashboard:

```sql
-- View 1: Player segment summary (aggregates intelligence by segment)
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
```

```sql
-- View 2: Charity impact summary (total donations per charity)
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT AS
SELECT
    c.CHARITY_NAME, c.CATEGORY, c.DESCRIPTION,
    ROUND(SUM(d.DONATION_AMOUNT), 2) AS TOTAL_RECEIVED,
    COUNT(DISTINCT d.DRAW_ID) AS DRAWS_FUNDED
FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS d
JOIN POSTCODE_LOTERIJ_AI.RAW.CHARITIES c ON d.CHARITY_ID = c.CHARITY_ID
GROUP BY c.CHARITY_NAME, c.CATEGORY, c.DESCRIPTION
ORDER BY TOTAL_RECEIVED DESC;
```

```sql
-- View 3: Draw results with winner details
CREATE OR REPLACE VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.DRAW_RESULTS AS
SELECT
    d.DRAW_ID, d.DRAW_DATE, d.PRIZE_TYPE, d.TOTAL_PRIZE_POOL, d.WINNING_POSTCODE,
    COUNT(DISTINCT t.PLAYER_ID) AS WINNERS_IN_POSTCODE,
    ROUND(d.TOTAL_PRIZE_POOL / GREATEST(COUNT(DISTINCT t.PLAYER_ID), 1), 2) AS PRIZE_PER_WINNER
FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS d
LEFT JOIN POSTCODE_LOTERIJ_AI.RAW.TICKETS t
    ON d.DRAW_ID = t.DRAW_ID AND t.IS_WINNER = TRUE
GROUP BY d.DRAW_ID, d.DRAW_DATE, d.PRIZE_TYPE, d.TOTAL_PRIZE_POOL, d.WINNING_POSTCODE
ORDER BY d.DRAW_DATE DESC;
```

> **View vs Table — What's the difference?**
>
> | | Table | View |
> |---|-------|------|
> | Stores data? | Yes (on disk) | No (just a saved query) |
> | When does it run? | Data is static until updated | Query runs every time you read it |
> | Best for | Source data, large datasets | Aggregations, reports, dashboards |
>
> The expression `PLAYER_SEGMENT_JSON:labels[0]::VARCHAR` is Snowflake's semi-structured data syntax. `AI_CLASSIFY` returns JSON like `{"labels":["High-Value Loyal"]}`. The `:labels[0]` navigates into the JSON to extract the first label, and `::VARCHAR` converts it to a text string.

### 2.8 Verify the Enrichment

```sql
-- Count: should be 10,000
SELECT COUNT(*) AS TOTAL_ROWS FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE;

-- Sample enriched rows
SELECT
    PLAYER_NAME, CITY, STATUS, MONTHLY_SPEND, FEEDBACK_SENTIMENT,
    PLAYER_SEGMENT_JSON, EXTRACTED_INSIGHTS_JSON,
    ESTIMATED_LIFETIME_VALUE, CHARITY_CONTRIBUTION
FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
LIMIT 5;

-- Segment distribution
SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY ORDER BY PLAYER_COUNT DESC;
```

> **Checkpoint**: You should see:
> - 10,000 rows in PLAYER_INTELLIGENCE
> - Each row has a FEEDBACK_SENTIMENT score, a PLAYER_SEGMENT_JSON classification, and EXTRACTED_INSIGHTS_JSON
> - The SEGMENT_SUMMARY view shows 6 segments with clean names like "High-Value Loyal", "At-Risk", etc.
>
> If you see segment names with extra JSON formatting, make sure you used the `PLAYER_SEGMENT_JSON:labels[0]::VARCHAR` syntax in the view (Step 2.7).

---

<img src="https://img.shields.io/badge/Module_3-Streamlit_Dashboard-E40421?style=flat-square" alt="Module 3">

## Module 3 — Build the Streamlit Dashboard (20 min)

> **Goal**: Build an interactive, branded dashboard directly inside Snowflake using Streamlit in Snowflake (SiS).

### What is Streamlit in Snowflake?

Streamlit is a Python framework for building interactive data apps. **Streamlit in Snowflake (SiS)** lets you build and run Streamlit apps directly within your Snowflake account — no separate server, no deployment pipeline, no infrastructure to manage. The app runs where your data lives.

Key benefits:
- **Zero deployment**: The app runs inside Snowflake, accessible via a URL
- **Data stays secure**: The app queries data directly using your Snowflake permissions
- **No infrastructure**: No servers to manage, no containers to deploy

### 3.1 Create the Streamlit App

1. In the left sidebar, click **Projects** > **Streamlit**
2. Click the blue **+ Streamlit App** button (top right)
3. A dialog appears. Fill in:
   - **App name**: `POSTCODE_LOTERIJ_APP`
   - **App location (database)**: Select `POSTCODE_LOTERIJ_AI` from the dropdown
   - **App location (schema)**: Select `ANALYTICS` from the dropdown
   - **App warehouse**: Select `LOTERIJ_WH` from the dropdown
4. Click **Create**

You will see the **Streamlit editor** — a code editor on the left and a preview pane on the right. It opens with a sample "Hello World" app. We will replace all of this code.

### 3.2 Set Up the Environment File

We need to pin a specific Streamlit version for compatibility. The default version in Snowflake doesn't support all the features we need (like chat input).

1. In the Streamlit editor, look at the **left panel** below the code editor. You should see a file list showing:
   - `streamlit_app.py`
   - `environment.yml`
2. Click on **`environment.yml`**
3. **Select all** the existing content (Ctrl+A / Cmd+A) and **replace it** with exactly this:

```yaml
name: sf_env
channels:
- snowflake
dependencies:
- streamlit=1.35.0
```

4. Click back on **`streamlit_app.py`** in the file list

> **Why pin the version?** Streamlit in Snowflake uses a default Streamlit version that may not include newer features like `chat_input` and `chat_message` (needed for our AI chatbot). By pinning to `1.35.0`, we ensure all features work correctly.

### 3.3 Paste the Dashboard Code

Now **select all** the code in `streamlit_app.py` (Ctrl+A / Cmd+A) and **replace it entirely** with the code below.

**This is a long code block.** The easiest approach:

1. Select all the code below (from `import streamlit` to the last line)
2. Copy it (Ctrl+C / Cmd+C)
3. Click in the Streamlit editor's `streamlit_app.py`
4. Select all existing code (Ctrl+A / Cmd+A)
5. Paste (Ctrl+V / Cmd+V)

```python
import streamlit as st
import pandas as pd
import json
import time
import random
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.functions import call_builtin, lit

# -- Page Config --
st.set_page_config(
    page_title="Postcode Loterij Intelligence",
    layout="wide",
)

session = get_active_session()

# -- Brand Colors --
PL_RED = "#E40421"
PL_DARK_RED = "#B8031A"
PL_ORANGE = "#F39200"
PL_GREEN = "#23A638"
PL_BLUE = "#0069B4"

# -- Custom CSS for Postcode Loterij branding --
st.markdown(f"""
<style>
    .pl-header {{
        background: linear-gradient(135deg, {PL_RED} 0%, {PL_DARK_RED} 100%);
        color: white;
        padding: 1.5rem 2rem;
        border-radius: 12px;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 1.2rem;
    }}
    .pl-logo {{
        font-size: 2.8rem;
        font-weight: 900;
        line-height: 1;
    }}
    .pl-logo .heart {{
        display: inline-block;
        color: white;
        background: rgba(255,255,255,0.2);
        border-radius: 50%;
        width: 52px;
        height: 52px;
        text-align: center;
        line-height: 52px;
        font-size: 1.6rem;
    }}
    .pl-header-text h1 {{
        margin: 0;
        font-size: 1.8rem;
        font-weight: 700;
    }}
    .pl-header-text p {{
        margin: 0.2rem 0 0 0;
        font-size: 0.95rem;
        opacity: 0.9;
    }}
    div[data-testid="stMetric"] {{
        background: white;
        border: 1px solid #f0f0f0;
        border-left: 4px solid {PL_RED};
        padding: 0.8rem 1rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06);
    }}
    div[data-testid="stMetric"] label {{
        color: #666 !important;
        font-size: 0.85rem !important;
    }}
    button[data-baseweb="tab"][aria-selected="true"] {{
        color: {PL_RED} !important;
        border-bottom-color: {PL_RED} !important;
    }}
    .stButton > button[kind="primary"] {{
        background-color: {PL_RED} !important;
        border-color: {PL_RED} !important;
    }}
    .winner-reveal {{
        background: linear-gradient(135deg, {PL_RED} 0%, {PL_ORANGE} 100%);
        color: white;
        padding: 1.5rem;
        border-radius: 12px;
        text-align: center;
        font-size: 2rem;
        font-weight: 800;
        margin: 1rem 0;
    }}
    .spinning-postcode {{
        background: #f8f9fa;
        border: 2px dashed {PL_RED};
        border-radius: 12px;
        padding: 1.2rem;
        text-align: center;
        font-size: 1.8rem;
        font-weight: 700;
        color: {PL_RED};
    }}
    .charity-banner {{
        background: linear-gradient(135deg, {PL_GREEN} 0%, #1a8a2e 100%);
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        margin: 0.5rem 0;
    }}
</style>
""", unsafe_allow_html=True)

# -- Branded Header --
st.markdown("""
<div class="pl-header">
    <div class="pl-logo"><span class="heart">PL</span></div>
    <div class="pl-header-text">
        <h1>Postcode Loterij — Player Intelligence</h1>
        <p>AI-powered analytics dashboard built entirely on Snowflake</p>
    </div>
</div>
""", unsafe_allow_html=True)

tab1, tab2, tab3 = st.tabs(["Player Dashboard", "Winner Draft", "AI Assistant"])

# ============================================================
# TAB 1: PLAYER DASHBOARD
# ============================================================
with tab1:
    kpi_df = session.sql("""
        SELECT
            COUNT(*) AS TOTAL_PLAYERS,
            SUM(CASE WHEN STATUS = 'Active' THEN 1 ELSE 0 END) AS ACTIVE_PLAYERS,
            ROUND(AVG(MONTHLY_SPEND), 2) AS AVG_MONTHLY_SPEND,
            ROUND(AVG(FEEDBACK_SENTIMENT), 3) AS AVG_SENTIMENT,
            ROUND(SUM(CHARITY_CONTRIBUTION), 0) AS TOTAL_CHARITY_IMPACT,
            ROUND(AVG(TENURE_MONTHS), 0) AS AVG_TENURE,
            ROUND(SUM(CASE WHEN STATUS = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS CHURN_RATE
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
    """).to_pandas()

    row = kpi_df.iloc[0]
    k1, k2, k3, k4 = st.columns(4)
    k1.metric("Total Players", f"{int(row['TOTAL_PLAYERS']):,}")
    k2.metric("Active Players", f"{int(row['ACTIVE_PLAYERS']):,}")
    k3.metric("Avg Monthly Spend", f"\u20ac{row['AVG_MONTHLY_SPEND']:.2f}")
    k4.metric("Churn Rate", f"{row['CHURN_RATE']:.1f}%")

    k5, k6, k7, k8 = st.columns(4)
    k5.metric("Avg Sentiment", f"{row['AVG_SENTIMENT']:.3f}")
    k6.metric("Avg Tenure", f"{int(row['AVG_TENURE'])} months")
    k7.metric("Charity Impact", f"\u20ac{int(row['TOTAL_CHARITY_IMPACT']):,}")
    k8.metric("Charity %", "40%")

    st.markdown("---")

    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Players by Segment")
        seg_df = session.sql("""
            SELECT SEGMENT, PLAYER_COUNT
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY
            ORDER BY PLAYER_COUNT DESC
        """).to_pandas()
        st.bar_chart(seg_df, x="SEGMENT", y="PLAYER_COUNT", color=PL_RED)

    with col2:
        st.subheader("Players by City")
        city_df = session.sql("""
            SELECT CITY, COUNT(*) AS PLAYER_COUNT
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            GROUP BY CITY ORDER BY PLAYER_COUNT DESC
        """).to_pandas()
        st.bar_chart(city_df, x="CITY", y="PLAYER_COUNT", color=PL_BLUE)

    col3, col4 = st.columns(2)
    with col3:
        st.subheader("Acquisition Channels")
        ch_df = session.sql("""
            SELECT ACQUISITION_CHANNEL, COUNT(*) AS PLAYERS
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            GROUP BY ACQUISITION_CHANNEL ORDER BY PLAYERS DESC
        """).to_pandas()
        st.bar_chart(ch_df, x="ACQUISITION_CHANNEL", y="PLAYERS", color=PL_ORANGE)

    with col4:
        st.subheader("Sentiment by Segment")
        sent_seg_df = session.sql("""
            SELECT SEGMENT, AVG_SENTIMENT
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY
            ORDER BY AVG_SENTIMENT ASC
        """).to_pandas()
        st.bar_chart(sent_seg_df, x="SEGMENT", y="AVG_SENTIMENT", color=PL_GREEN)

    st.subheader("Segment Intelligence")
    seg_detail = session.sql("""
        SELECT SEGMENT, PLAYER_COUNT, AVG_MONTHLY_SPEND, AVG_SENTIMENT,
            AVG_TENURE AS AVG_TENURE_MONTHS, TOTAL_LTV, TOTAL_CHARITY_IMPACT
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY
        ORDER BY PLAYER_COUNT DESC
    """).to_pandas()
    st.dataframe(seg_detail, use_container_width=True)

    st.subheader("Charity Impact by Category")
    st.markdown('<div class="charity-banner">40% of every ticket sold goes directly to charity partners</div>', unsafe_allow_html=True)
    charity_cat = session.sql("""
        SELECT CATEGORY, COUNT(DISTINCT CHARITY_NAME) AS CHARITIES,
            ROUND(SUM(TOTAL_RECEIVED), 0) AS TOTAL_DONATED
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT
        GROUP BY CATEGORY ORDER BY TOTAL_DONATED DESC
    """).to_pandas()
    st.bar_chart(charity_cat, x="CATEGORY", y="TOTAL_DONATED", color=PL_GREEN)


# ============================================================
# TAB 2: WINNER DRAFT
# ============================================================
with tab2:
    st.subheader("Draft a Winner!")
    st.write("Select a draw and watch as we pick the winning postcode. Neighbours win together!")

    draws_df = session.sql("""
        SELECT DRAW_ID, DRAW_DATE, PRIZE_TYPE, TOTAL_PRIZE_POOL, WINNING_POSTCODE
        FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS ORDER BY DRAW_DATE DESC
    """).to_pandas()

    draw_options = draws_df.apply(
        lambda r: f"Draw {r['DRAW_ID']} \u2014 {r['DRAW_DATE']} \u2014 {r['PRIZE_TYPE']} (\u20ac{int(r['TOTAL_PRIZE_POOL']):,})",
        axis=1).tolist()
    selected_draw_idx = st.selectbox("Select a draw", range(len(draw_options)),
                                      format_func=lambda i: draw_options[i])
    selected_draw = draws_df.iloc[selected_draw_idx]

    d1, d2, d3 = st.columns(3)
    d1.metric("Prize Type", selected_draw["PRIZE_TYPE"])
    d2.metric("Prize Pool", f"\u20ac{int(selected_draw['TOTAL_PRIZE_POOL']):,}")
    d3.metric("Draw Date", str(selected_draw["DRAW_DATE"]))

    st.markdown("---")

    if st.button("Draft Winner!", type="primary"):
        postcodes_df = session.sql("""
            SELECT DISTINCT POSTCODE, CITY FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
            WHERE STATUS = 'Active'
        """).to_pandas()

        placeholder = st.empty()
        postcode_list = postcodes_df["POSTCODE"].tolist()
        for i in range(20):
            rand_pc = random.choice(postcode_list)
            placeholder.markdown(f'<div class="spinning-postcode">{rand_pc}</div>', unsafe_allow_html=True)
            time.sleep(0.1 + i * 0.02)

        winning_pc = selected_draw["WINNING_POSTCODE"]
        placeholder.empty()
        st.balloons()
        st.markdown(f'<div class="winner-reveal">Winning Postcode: {winning_pc}</div>', unsafe_allow_html=True)

        winners_df = session.sql(f"""
            SELECT PLAYER_NAME, POSTCODE, CITY, TICKET_TYPE, MONTHLY_SPEND, TENURE_MONTHS, STATUS
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            WHERE POSTCODE = '{winning_pc}' AND STATUS = 'Active'
        """).to_pandas()

        num_winners = len(winners_df)
        prize_per_winner = int(selected_draw["TOTAL_PRIZE_POOL"]) // max(num_winners, 1)

        w1, w2, w3 = st.columns(3)
        w1.metric("Winners in Postcode", num_winners)
        w2.metric("Prize per Winner", f"\u20ac{prize_per_winner:,}")
        w3.metric("Winning City", winners_df["CITY"].iloc[0] if not winners_df.empty else "N/A")

        if not winners_df.empty:
            st.subheader("Congratulations to:")
            st.dataframe(winners_df, use_container_width=True)
        else:
            st.info("No active players found in this postcode for this draw.")

        st.markdown("---")
        st.subheader("Charities supported by this draw")
        st.markdown('<div class="charity-banner">Every draw directly funds charity partners</div>', unsafe_allow_html=True)
        charity_draw = session.sql(f"""
            SELECT CHARITY_NAME, CATEGORY, ROUND(DONATION_AMOUNT, 2) AS DONATED
            FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS
            WHERE DRAW_ID = {selected_draw['DRAW_ID']}
            ORDER BY DONATED DESC LIMIT 10
        """).to_pandas()
        st.dataframe(charity_draw, use_container_width=True)


# ============================================================
# TAB 3: AI ASSISTANT
# ============================================================
with tab3:
    st.subheader("Ask questions about player data and charity impact")
    st.caption("Powered by Snowflake Cortex AI \u2014 your data never leaves Snowflake")

    @st.cache_data(ttl=600)
    def get_context():
        seg = session.sql("SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY").to_pandas()
        charity = session.sql("SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT ORDER BY TOTAL_RECEIVED DESC LIMIT 15").to_pandas()
        kpis = session.sql("""
            SELECT COUNT(*) AS TOTAL_PLAYERS,
                SUM(CASE WHEN STATUS = 'Active' THEN 1 ELSE 0 END) AS ACTIVE,
                ROUND(AVG(MONTHLY_SPEND), 2) AS AVG_SPEND,
                ROUND(SUM(CHARITY_CONTRIBUTION), 0) AS CHARITY_TOTAL,
                ROUND(AVG(FEEDBACK_SENTIMENT), 3) AS AVG_SENTIMENT
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
        """).to_pandas()
        return seg, charity, kpis

    seg_df, charity_df, kpi_context = get_context()

    SYSTEM_PROMPT = f"""You are an analytics assistant for the Postcode Loterij (Dutch Postcode Lottery).
You have access to player intelligence data.

Key metrics:
{kpi_context.to_string(index=False)}

Player segments:
{seg_df.to_string(index=False)}

Top charity partners by donations received:
{charity_df.to_string(index=False)}

Context about the business:
- Postcode Loterij is the largest charity lottery in the Netherlands
- Players subscribe monthly using their postcode as their ticket number
- Neighbours win together — whole streets can win the StreetPrize
- 40% of all revenue goes to 150+ charity partners
- The PostcodeKanjer (January draw) is the biggest prize — EUR 59.7 million in 2026
- They operate in 5 countries: Netherlands, Sweden, UK, Germany, Norway

Answer questions about player segments, charity impact, retention strategies, and business performance.
Be specific with numbers. Give actionable recommendations when asked."""

    SUGGESTIONS = {
        "Segment analysis": "What are the key characteristics of each player segment? Which segment should we focus retention efforts on?",
        "Charity impact": "How is our charity funding distributed? Which categories receive the most and what is the total impact?",
        "Churn insights": "What can you tell me about churn patterns? What strategies would you recommend to reduce churn?",
        "Growth ideas": "What are the top 3 growth opportunities based on the player data?",
    }

    if "messages" not in st.session_state:
        st.session_state.messages = []

    if not st.session_state.messages:
        st.write("**Try one of these questions:**")
        for label, question in SUGGESTIONS.items():
            if st.button(f"{label}: {question}"):
                st.session_state.messages.append({"role": "user", "content": question})
                st.experimental_rerun()

    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.write(msg["content"])

    if prompt := st.chat_input("Ask about players, charities, or performance..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.write(prompt)

    if st.session_state.messages and st.session_state.messages[-1]["role"] == "user":
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                prompt_parts = [f"SYSTEM: {SYSTEM_PROMPT}"]
                for m in st.session_state.messages:
                    prompt_parts.append(f"{m['role'].upper()}: {m['content']}")
                prompt_parts.append("ASSISTANT:")
                full_prompt = "\n\n".join(prompt_parts)

                result_df = session.create_dataframe([{"dummy": "x"}]).select(
                    call_builtin("SNOWFLAKE.CORTEX.COMPLETE", lit("claude-3-5-sonnet"), lit(full_prompt)).alias("RESPONSE")
                )
                response = result_df.collect()[0]["RESPONSE"]
                st.write(response)

        st.session_state.messages.append({"role": "assistant", "content": response})
```

### 3.4 Run the App

Click the **Run** button (blue play icon, top right of the editor). The app should load in the preview pane on the right.

You should see:
- A **red branded header** with the PL logo and title
- **Three tabs**: Player Dashboard, Winner Draft, AI Assistant
- The Player Dashboard tab loaded with KPI cards and charts

> **Troubleshooting**:
>
> | Error | Fix |
> |-------|-----|
> | `Table 'PLAYER_INTELLIGENCE' does not exist` | Go back and complete Module 2, Step 2.6 |
> | `View 'SEGMENT_SUMMARY' does not exist` | Go back and complete Module 2, Step 2.7 |
> | `module 'streamlit' has no attribute 'chat_input'` | Check that `environment.yml` has `streamlit=1.35.0` |
> | Charts show but no data | Make sure the AI enrichment query (Step 2.6) completed successfully |

> **Snowflake Concept — Streamlit in Snowflake (SiS):**
>
> The Python code runs *inside Snowflake*, not on your laptop. Key elements:
> - `get_active_session()` — connects to the Snowflake session that's hosting the app
> - `session.sql("...")` — runs SQL queries directly against your Snowflake data
> - `session.sql(...).to_pandas()` — executes the query and returns results as a Pandas DataFrame
> - `call_builtin("SNOWFLAKE.CORTEX.COMPLETE", ...)` — calls the Cortex AI LLM from Python code
> - `st.cache_data(ttl=600)` — caches query results for 10 minutes to improve performance
> - `st.session_state` — preserves data (like chat history) between user interactions

---

<img src="https://img.shields.io/badge/Module_4-Explore_the_App-E40421?style=flat-square" alt="Module 4">

## Module 4 — Explore the App (10 min)

Now let's explore what you built. Take a few minutes to interact with each tab.

### 4.1 Player Dashboard

1. **Review the 8 KPI cards** at the top. Notice the red accent on each card — that's the Postcode Loterij brand color.
2. **Players by Segment chart** (top-left): Which segment is the largest? What does this tell you about the player base?
3. **Players by City chart** (top-right): Are players evenly distributed? Which cities have the most players?
4. **Acquisition Channels** (bottom-left): Which channel brings the most players? What does this suggest about marketing spend?
5. **Sentiment by Segment** (bottom-right): Which segment has the lowest sentiment? This is a signal for where to focus retention efforts.
6. **Segment Intelligence table**: Scroll down to see detailed metrics per segment — average spend, lifetime value, and charity impact.
7. **Charity Impact by Category**: See how donations are distributed across Nature, Human Rights, Health, and Culture.

### 4.2 Winner Draft

1. Click the **Winner Draft** tab
2. Use the dropdown to **select a draw** — try picking a **PostcodeKanjer** (the biggest prize, happens in January)
3. Notice the KPI cards showing prize type, pool, and date
4. Click the red **"Draft Winner!"** button
5. Watch the **animated postcode spinner** — postcodes flash rapidly, then slow down
6. See the winning postcode revealed with balloons and a branded card
7. Review the **winners table** — these are all active players who share that postcode
8. Scroll down to see which **charities** were funded by this draw

> **This mirrors reality**: In the real Postcode Loterij, all neighbours who share a winning postcode win together. The prize pool is split among them. That's the "samen winnen" (winning together) concept.

### 4.3 AI Assistant

1. Click the **AI Assistant** tab
2. Click one of the **four suggestion buttons** to start a conversation (e.g., "Segment analysis")
3. Read the AI's response — it uses your actual player data from the PLAYER_INTELLIGENCE table
4. Type a **follow-up question** in the chat input at the bottom. Try:
   - *"Which city has the highest churn rate?"*
   - *"Write a marketing email for At-Risk players in Rotterdam"*
   - *"What would happen to charity funding if we reduced churn by 5%?"*
5. Notice the AI gives **specific numbers** from your data — it's not guessing

> **How the chatbot works**: The AI Assistant uses `SNOWFLAKE.CORTEX.COMPLETE` — the same LLM function you used in SQL (Step 2.5). Here, we give it context about your data (segment summaries, charity data, KPIs) as a system prompt, then pass the full conversation history so it can maintain context across turns. All of this runs inside Snowflake.

---

<img src="https://img.shields.io/badge/Module_5-Semantic_View_&_Agent-E40421?style=flat-square" alt="Module 5">

## Module 5 — Semantic View & Cortex Agent (15 min)

> **Goal**: Create a business-friendly data model (Semantic View) and an AI agent that can answer natural language questions about your player data by automatically generating SQL.

### What is a Semantic View?

A **Semantic View** is a metadata layer you define on top of your tables. It tells Snowflake's AI what your columns mean in business terms — which columns are dimensions (things you filter/group by), which are facts (raw values), and which are metrics (aggregations like counts and averages).

Once defined, Snowflake's **Cortex Analyst** can read the semantic view and automatically convert natural language questions into accurate SQL queries. Instead of writing SQL yourself, you just ask: *"What is the average spend by city?"* and Cortex Analyst generates the correct query.

Think of it as a **data dictionary that AI can understand**.

### What is a Cortex Agent?

A **Cortex Agent** is an AI orchestrator that sits on top of tools like Semantic Views. You give it instructions about your business, connect it to one or more data sources, and it figures out which tool to use for each question. It can:

- Convert natural language to SQL via Cortex Analyst (using your Semantic View)
- Search unstructured documents via Cortex Search
- Chain multiple tools together to answer complex questions

### 5.1 Create the Semantic View

This semantic view defines the business meaning of our PLAYER_INTELLIGENCE table. Run this in your SQL worksheet:

```sql
USE SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

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
```

You should see: `Statement executed successfully.`

> **Snowflake Concept — Semantic View:**
>
> | Component | What it defines | Example |
> |-----------|----------------|---------|
> | **TABLES** | Which physical tables to use | `PLAYER_INTELLIGENCE` |
> | **FACTS** | Raw numeric values per row | Monthly spend, Tenure |
> | **DIMENSIONS** | Columns to filter/group by | City, Status, Segment |
> | **METRICS** | Aggregations (computed from facts) | `AVG(MONTHLY_SPEND)`, `COUNT(PLAYER_ID)` |
> | **SYNONYMS** | Alternative names the AI understands | "how many players" → `player_count` |
> | **AI_SQL_GENERATION** | Custom instructions for SQL generation | "Round monetary values to 2 decimal places" |
>
> The semantic view does not store data — it's a metadata definition. When someone asks a question, Cortex Analyst reads this definition to understand how to write the SQL query.

### 5.2 Verify the Semantic View

```sql
-- List all semantic views in the schema
SHOW SEMANTIC VIEWS IN SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;

-- See the dimensions, facts, and metrics defined
SHOW SEMANTIC DIMENSIONS FOR SEMANTIC VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW;
SHOW SEMANTIC METRICS FOR SEMANTIC VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW;
```

You should see your dimensions (city, status, segment, etc.) and metrics (player_count, avg_monthly_spend, churn_rate, etc.) listed.

### 5.3 Create the Cortex Agent

Now we create an agent that uses this semantic view as its data tool. The agent will be able to answer natural language questions by generating SQL:

```sql
CREATE OR REPLACE AGENT POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_AGENT
  COMMENT = 'AI agent for Postcode Loterij player intelligence analysis'
  PROFILE = '{"display_name": "Loterij Intelligence Agent", "color": "red"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-4-sonnet

  orchestration:
    budget:
      seconds: 30
      tokens: 16000

  instructions:
    system: >
      You are an analytics assistant for the Postcode Loterij (Dutch Postcode Lottery).
      You help business users understand player data, segment performance, charity impact,
      and retention patterns. Always give specific numbers. When asked for recommendations,
      be actionable and reference the data.

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
  $$;
```

You should see: `Statement executed successfully.`

> **Snowflake Concept — Cortex Agent:**
>
> The agent has three key parts:
> - **Instructions**: Tell the AI how to behave and what business context it needs
> - **Tools**: What capabilities the agent has (here: `cortex_analyst_text_to_sql` which converts questions to SQL)
> - **Tool Resources**: Connect each tool to a data source (here: our semantic view)
>
> When you ask a question, the agent: (1) reads your question, (2) decides which tool to use, (3) passes the question to Cortex Analyst, (4) Cortex Analyst reads the Semantic View to generate SQL, (5) runs the SQL, (6) the agent formats the response.

### 5.4 Test the Agent

You can test the agent directly from Snowsight:

1. In the left sidebar, click **AI & ML** > **Agents**
2. You should see **Loterij Intelligence Agent** in the list
3. Click on it to open the chat interface
4. Try these questions:

   - *"How many players do we have per segment?"*
   - *"What is the average sentiment score for At-Risk players compared to High-Value Loyal?"*
   - *"Which acquisition channel brings the most players?"*
   - *"What is our total charity impact from active players?"*
   - *"Show me the churn rate by city"*

5. Notice how the agent generates SQL automatically — you can see the query it ran and the results

> **Compare this to the Streamlit chatbot** (Module 3, Tab 3): The Streamlit chatbot uses hardcoded data context — we manually pasted segment summaries and KPIs into the prompt. The Cortex Agent dynamically queries the actual database using your Semantic View. It can answer questions the Streamlit chatbot cannot, because it writes real SQL instead of relying on pre-loaded context.

### 5.5 What You Just Built

You created a complete AI analytics stack:

```
Natural language question
        │
        ▼
   CORTEX AGENT (understands business context)
        │
        ▼
   CORTEX ANALYST (reads semantic view, generates SQL)
        │
        ▼
   SEMANTIC VIEW (defines dimensions, facts, metrics)
        │
        ▼
   PLAYER_INTELLIGENCE table (AI-enriched data)
        │
        ▼
   Answer with real numbers
```

This is the same architecture that production Snowflake customers use to give business users self-service analytics without writing SQL.

---

<img src="https://img.shields.io/badge/Bonus-Cortex_Code_Challenge-29B5E8?style=flat-square" alt="Bonus">

## Bonus Module — Cortex Code Challenge (for those who finish early)

**Finished the lab early?** Use Cortex Code to extend what you built.

**Cortex Code** is Snowflake's AI-powered CLI assistant. You describe what you want in natural language, and it writes the SQL, Python, or Streamlit code for you.

### The Challenge

Use Cortex Code to build something new on top of the data you created. Pick one of the options below (or come up with your own idea):

**Option A — Player Lookup Tab**
> *"Add a new tab to the Postcode Loterij Streamlit app that lets users search for a player by name or postcode and see their full profile including AI-generated segment, sentiment score, and extracted insights."*

**Option B — Charity Impact Report**
> *"Create a SQL query that generates a charity impact report showing each charity's total donations, number of draws funded, average donation per draw, and rank them by total received. Save it as a view called CHARITY_REPORT."*

**Option C — Churn Risk Dashboard**
> *"Create a view called CHURN_RISK_REPORT that identifies players most likely to churn based on their sentiment score, tenure, and spend. Include a risk score and sort by highest risk first."*

**Option D — Expand the Semantic View**
> *"Add the CHARITIES and DONATIONS tables to the PLAYER_SEMANTIC_VIEW so the agent can also answer questions about charity funding, donation amounts per draw, and which charities receive the most."*

**Option E — Your Own Idea**
> Think about what would be valuable for Postcode Loterij and describe it to Cortex Code.

### How to Use Cortex Code

Your instructor will guide you through accessing Cortex Code. The general workflow is:

1. **Describe** what you want to build in plain language
2. **Review** the generated code — Cortex Code will explain what it does
3. **Run** the code in Snowflake (Cortex Code can execute it directly)
4. **Iterate** — ask for modifications or improvements

> **The takeaway**: The SQL and Streamlit code you manually built in Modules 1-3 could also be generated this way. Cortex Code accelerates the development process from hours to minutes, while keeping you in control of the result.

---

## Recap — What You Built

| | Component | Snowflake Technology | What it does |
|:-:|-----------|---------------------|--------------|
| 🎲 | Synthetic data | `GENERATOR()`, `UNIFORM()`, `RANDOM()` | Creates realistic test data without external files |
| 💬 | Sentiment analysis | `SNOWFLAKE.CORTEX.SENTIMENT` | Scores player feedback from -1 to +1 |
| 🏷️ | Player segmentation | `AI_CLASSIFY` | Categorizes players into 6 segments using zero-shot classification |
| 🔍 | Insight extraction | `AI_EXTRACT` | Pulls structured fields from unstructured text |
| 📝 | Profile summaries | `SNOWFLAKE.CORTEX.SUMMARIZE` | Creates one-sentence player summaries |
| ✉️ | Personalized messages | `SNOWFLAKE.CORTEX.COMPLETE` | Generates custom retention copy using an LLM |
| 📊 | Interactive dashboard | Streamlit in Snowflake | Three-tab branded dashboard with KPIs, charts, and tables |
| 💬 | AI chatbot | `SNOWFLAKE.CORTEX.COMPLETE` + Streamlit | Conversational analytics assistant with data context |
| 📐 | Semantic View | `CREATE SEMANTIC VIEW` | Business data model with dimensions, facts, and metrics |
| 🤖 | AI Agent | `CREATE AGENT` + Cortex Analyst | Natural language to SQL — ask questions, get answers |

**🔒 Everything ran inside Snowflake.** No external APIs. No additional tools. No data left your account.

---

## Cleanup (Optional)

To remove everything created in this lab:

```sql
DROP DATABASE IF EXISTS POSTCODE_LOTERIJ_AI;
DROP WAREHOUSE IF EXISTS LOTERIJ_WH;
```

---

## Additional Resources

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Semantic Views Documentation](https://docs.snowflake.com/en/user-guide/views-semantic/sql)
- [Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [CREATE SEMANTIC VIEW Reference](https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view)
- [CREATE AGENT Reference](https://docs.snowflake.com/en/sql-reference/sql/create-agent)
- [AI_CLASSIFY Function Reference](https://docs.snowflake.com/en/sql-reference/functions/ai_classify)
- [AI_EXTRACT Function Reference](https://docs.snowflake.com/en/sql-reference/functions/ai_extract)
- [CORTEX.COMPLETE Function Reference](https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex)
- [CORTEX.SENTIMENT Function Reference](https://docs.snowflake.com/en/sql-reference/functions/sentiment-snowflake-cortex)

---

*Lab designed for Postcode Loterij by the Snowflake team.*
