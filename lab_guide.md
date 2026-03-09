<img src="assets/border.svg" width="100%">

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

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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
    │  │ CHARITIES│               │ SEGMENT_     │       │
    │  │ DONATIONS│               │ SUMMARY      │       │
    │  └─────────┘                │ CHARITY_     │       │
    │                             │ IMPACT       │       │
    │                             │ DRAW_RESULTS │       │
    │                             └──────┬───────┘       │
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

<p align="center"><img src="assets/divider.svg" width="80%"></p>

## Lab Agenda

| # | Module | Duration |
|:-:|--------|:--------:|
| 0 | **Environment Setup** | 5 min |
| 1 | **Foundation** — Create Database & Synthetic Data | 15 min |
| 2 | **AI Enrichment** — Cortex AI Functions | 25 min |
| 3 | **Streamlit Dashboard** — Build & Deploy | 20 min |
| 4 | **Explore** — Interact with the App | 10 min |
| 5 | **Semantic View & Cortex Agent** | 20 min |
| + | **Bonus** — Cortex Code Challenge | 15 min |

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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

<p align="center"><img src="assets/divider.svg" width="80%"></p>

<img src="https://img.shields.io/badge/Module_1-Foundation_Setup-E40421?style=flat-square" alt="Module 1">

## Module 1 — Foundation Setup (15 min)

> **Goal**: Create the database, warehouse, and generate synthetic data that represents Postcode Loterij's business.

### 1.1 Create Database, Schemas, and Warehouse

Copy and run this block:

```sql
-- Make sure you have the right role (in case you opened a new worksheet)
USE ROLE ACCOUNTADMIN;

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
        -- Monthly spend derived from ticket type (€15 per lot)
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN 45 WHEN 2 THEN 45
            WHEN 3 THEN 30 WHEN 4 THEN 30 WHEN 5 THEN 30
            ELSE 15
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
    SELECT POSTCODE, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
    FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS WHERE STATUS = 'Active'
)
SELECT
    DRAW_ID, DRAW_DATE, PRIZE_TYPE, TOTAL_PRIZE_POOL,
    rp.POSTCODE AS WINNING_POSTCODE
FROM draw_dates dd
JOIN random_postcodes rp ON rp.rn = dd.DRAW_ID;
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
>
> **Troubleshooting**:
>
> | Problem | Fix |
> |---------|-----|
> | `Object does not exist` or `Table not found` | Make sure you ran `USE SCHEMA POSTCODE_LOTERIJ_AI.RAW;` from Step 1.1 |
> | PLAYERS shows 0 rows | Re-run the Players query from Step 1.3 — make sure you selected the full query before pressing Run |
> | TICKETS shows 0 rows | Re-run Step 1.4 — the TICKETS query depends on PLAYERS and DRAWS existing first |
> | `Warehouse does not exist` | Run `USE WAREHOUSE LOTERIJ_WH;` — you may have skipped Step 1.1 |

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

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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

> **Why ANALYTICS?** We switch to the `ANALYTICS` schema because that's where we'll create the AI-enriched table and views (Step 2.6 onwards). In the queries below, we use fully qualified names like `POSTCODE_LOTERIJ_AI.RAW.PLAYERS` to read from the `RAW` schema. Fully qualified names (`DATABASE.SCHEMA.TABLE`) work regardless of which schema you're currently in — they're like an absolute path to the table.

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
>
 > **Model not available?** If you get an error like `Unknown model` for `claude-3-5-sonnet`, it means this model is not enabled in your account's region. Replace `'claude-3-5-sonnet'` with `'mistral-large2'` or `'llama3.1-70b'` in the query above. You can test if a model works by running: `SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', 'Say hello');`

### 2.6 Build the PLAYER_INTELLIGENCE Table

Now we combine the AI functions into one enriched table. **This runs on all 10,000 players and will take 2-5 minutes**.

> **Note**: We include SENTIMENT, AI_CLASSIFY, and AI_EXTRACT in the table below, but *not* SUMMARIZE or COMPLETE. Why? Those two functions generate longer text output and are slower per row. Running them on 10,000 rows would take significantly longer. We demonstrated them on small samples in Steps 2.4 and 2.5 so you understand the capability — in production you would run them on targeted subsets (e.g., only churned players) rather than the full table.

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
>
> **Troubleshooting**:
>
> | Problem | Fix |
> |---------|-----|
> | `Function not found` or `unknown function` | Make sure you ran `USE ROLE ACCOUNTADMIN;` (Step 0.3) and the cross-region setting |
> | Query takes very long (>5 min) | This is normal for Step 2.6 — it runs AI functions on 10,000 rows. Wait for it to finish |
> | `Table 'PLAYERS' does not exist` | Run `USE SCHEMA POSTCODE_LOTERIJ_AI.RAW;` first, or check that Module 1 completed successfully |
> | PLAYER_INTELLIGENCE has 0 or fewer than 10,000 rows | Re-run the full query from Step 2.6. Make sure you selected the entire block before running |
> | SEGMENT_SUMMARY shows weird segment names | Check Step 2.7 — the view should use `PLAYER_SEGMENT_JSON:labels[0]::VARCHAR`, not just `PLAYER_SEGMENT_JSON` |

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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

> **Why pin the version?** Pinning a specific Streamlit version ensures consistent behavior across all attendees and avoids compatibility surprises. In Module 5, we will switch from warehouse runtime (Conda) to container runtime (PyPI), which uses a different dependency file — pinning here keeps the initial setup clean and predictable.

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
    /* Header banner */
    .pl-header {{
        margin-bottom: 1rem;
        border-radius: 12px;
        overflow: hidden;
        line-height: 0;
    }}
    .pl-header svg {{
        width: 100%;
        height: auto;
        border-radius: 12px;
    }}

    /* KPI cards */
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
        font-weight: 500 !important;
    }}
    div[data-testid="stMetric"] div[data-testid="stMetricValue"] {{
        color: #1a1a1a !important;
        font-weight: 700 !important;
    }}

    /* Tab styling */
    button[data-baseweb="tab"] {{
        font-weight: 600 !important;
        font-size: 1rem !important;
    }}
    button[data-baseweb="tab"][aria-selected="true"] {{
        color: {PL_RED} !important;
        border-bottom-color: {PL_RED} !important;
    }}

    /* Primary buttons */
    .stButton > button[kind="primary"] {{
        background-color: {PL_RED} !important;
        border-color: {PL_RED} !important;
    }}
    .stButton > button[kind="primary"]:hover {{
        background-color: {PL_DARK_RED} !important;
        border-color: {PL_DARK_RED} !important;
    }}

    /* Winner reveal */
    .winner-reveal {{
        background: linear-gradient(135deg, {PL_RED} 0%, {PL_ORANGE} 100%);
        color: white;
        padding: 1.5rem;
        border-radius: 12px;
        text-align: center;
        font-size: 2rem;
        font-weight: 800;
        margin: 1rem 0;
        animation: pulse 0.5s ease-in-out;
    }}
    @keyframes pulse {{
        0% {{ transform: scale(0.95); opacity: 0.8; }}
        50% {{ transform: scale(1.02); }}
        100% {{ transform: scale(1); opacity: 1; }}
    }}

    /* Spinning animation */
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

    /* Charity highlight */
    .charity-banner {{
        background: linear-gradient(135deg, {PL_GREEN} 0%, #1a8a2e 100%);
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        margin: 0.5rem 0;
        font-size: 1rem;
    }}

    /* Section headers */
    h3, h2 {{
        color: #1a1a1a !important;
    }}

    /* Suggestion buttons in chat */
    .suggestion-btn {{
        display: inline-block;
        background: white;
        border: 2px solid {PL_RED};
        color: {PL_RED};
        padding: 0.5rem 1rem;
        border-radius: 20px;
        margin: 0.3rem;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.2s;
    }}
    .suggestion-btn:hover {{
        background: {PL_RED};
        color: white;
    }}
</style>
""", unsafe_allow_html=True)

# -- Branded Header (inline SVG — no external files needed) --
st.markdown("""
<div class="pl-header" style="position:relative;">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 200">
  <defs>
    <linearGradient id="sky" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#1a1a2e"/>
      <stop offset="100%" style="stop-color:#16213e"/>
    </linearGradient>
    <linearGradient id="water" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#0a1628;stop-opacity:0.8"/>
      <stop offset="100%" style="stop-color:#0a1628;stop-opacity:0.95"/>
    </linearGradient>
  </defs>

  <!-- Night sky -->
  <rect width="900" height="200" fill="url(#sky)"/>

  <!-- Stars -->
  <circle cx="50" cy="20" r="1.5" fill="white" opacity="0.7"/>
  <circle cx="150" cy="35" r="1" fill="white" opacity="0.5"/>
  <circle cx="280" cy="14" r="1.5" fill="white" opacity="0.6"/>
  <circle cx="550" cy="10" r="1.5" fill="white" opacity="0.7"/>
  <circle cx="680" cy="30" r="1" fill="white" opacity="0.5"/>
  <circle cx="780" cy="16" r="1.5" fill="white" opacity="0.6"/>
  <circle cx="850" cy="38" r="1" fill="white" opacity="0.4"/>

  <!-- Canal water -->
  <rect x="0" y="155" width="900" height="45" fill="url(#water)"/>
  <line x1="30" y1="168" x2="70" y2="168" stroke="white" stroke-width="0.5" opacity="0.15"/>
  <line x1="150" y1="178" x2="200" y2="178" stroke="white" stroke-width="0.5" opacity="0.1"/>
  <line x1="300" y1="170" x2="360" y2="170" stroke="white" stroke-width="0.5" opacity="0.12"/>

  <!-- Canal edge -->
  <rect x="0" y="150" width="900" height="6" rx="2" fill="#2a2a3e" opacity="0.8"/>

  <!-- House 1 — Red -->
  <rect x="20" y="75" width="55" height="78" fill="#E40421"/>
  <polygon points="22,75 47,48 75,75" fill="#B8031A"/>
  <rect x="32" y="88" width="12" height="14" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="52" y="88" width="12" height="14" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="32" y="112" width="12" height="14" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="52" y="112" width="12" height="14" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="40" y="130" width="16" height="23" rx="1" fill="#8B4513"/>

  <!-- House 2 — Orange -->
  <rect x="80" y="68" width="50" height="85" fill="#F39200"/>
  <rect x="80" y="68" width="50" height="7" fill="#D47E00"/>
  <polygon points="82,68 105,44 128,68" fill="#D47E00"/>
  <rect x="90" y="82" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="108" y="82" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.8"/>
  <rect x="90" y="104" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="108" y="104" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="97" y="128" width="14" height="25" rx="1" fill="#8B4513"/>

  <!-- House 3 — Dark red (stepped gable) -->
  <rect x="135" y="62" width="58" height="91" fill="#8B2500"/>
  <rect x="145" y="54" width="38" height="8" fill="#8B2500"/>
  <rect x="150" y="46" width="28" height="8" fill="#8B2500"/>
  <rect x="155" y="38" width="18" height="8" fill="#8B2500"/>
  <rect x="147" y="78" width="11" height="13" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="168" y="78" width="11" height="13" rx="1" fill="#FFE4B5" opacity="0.8"/>
  <rect x="147" y="102" width="11" height="13" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="168" y="102" width="11" height="13" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="155" y="125" width="16" height="28" rx="1" fill="#6B3000"/>

  <!-- House 4 — Blue -->
  <rect x="198" y="72" width="48" height="81" fill="#0069B4"/>
  <polygon points="200,72 222,46 244,72" fill="#005A9C"/>
  <rect x="207" y="85" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.8"/>
  <rect x="227" y="85" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="207" y="108" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="227" y="108" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="214" y="128" width="14" height="25" rx="1" fill="#8B4513"/>

  <!-- House 5 — Green -->
  <rect x="250" y="66" width="52" height="87" fill="#23A638"/>
  <rect x="250" y="66" width="52" height="5" fill="#1D8C2F"/>
  <polygon points="252,66 276,42 300,66" fill="#1D8C2F"/>
  <rect x="260" y="80" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="280" y="80" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.8"/>
  <rect x="260" y="104" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="280" y="104" width="10" height="12" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="268" y="128" width="14" height="25" rx="1" fill="#8B4513"/>

  <!-- House 6 — Red -->
  <rect x="307" y="70" width="45" height="83" fill="#E40421"/>
  <polygon points="309,70 329,48 350,70" fill="#B8031A"/>
  <rect x="315" y="84" width="9" height="11" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="333" y="84" width="9" height="11" rx="1" fill="#FFE4B5" opacity="0.8"/>
  <rect x="315" y="106" width="9" height="11" rx="1" fill="#FFE4B5" opacity="0.7"/>
  <rect x="333" y="106" width="9" height="11" rx="1" fill="#FFE4B5" opacity="0.9"/>
  <rect x="322" y="130" width="12" height="23" rx="1" fill="#8B4513"/>

  <!-- Confetti -->
  <rect x="100" y="22" width="4" height="7" rx="1" fill="#F39200" opacity="0.8" transform="rotate(25 102 26)"/>
  <rect x="180" y="32" width="4" height="7" rx="1" fill="#E40421" opacity="0.7" transform="rotate(-15 182 36)"/>
  <rect x="260" y="18" width="4" height="7" rx="1" fill="#23A638" opacity="0.8" transform="rotate(40 262 22)"/>
  <rect x="60" y="36" width="4" height="7" rx="1" fill="#0069B4" opacity="0.6" transform="rotate(-30 62 40)"/>
  <circle cx="140" cy="28" r="3" fill="#E40421" opacity="0.6"/>
  <circle cx="230" cy="40" r="2.5" fill="#F39200" opacity="0.5"/>
  <circle cx="300" cy="24" r="3" fill="#23A638" opacity="0.6"/>

  <!-- PL Logo circle (text added via HTML overlay) -->
  <circle cx="420" cy="62" r="28" fill="#E40421"/>
  <circle cx="420" cy="62" r="26" fill="none" stroke="white" stroke-width="1.5" opacity="0.3"/>

  <!-- Divider line -->
  <line x1="465" y1="90" x2="720" y2="90" stroke="#E40421" stroke-width="2" opacity="0.5"/>

  <!-- Bottom accent bar -->
  <rect x="0" y="194" width="900" height="6" fill="#E40421" opacity="0.8"/>
</svg>
<!-- HTML text overlay (Streamlit strips SVG <text> elements) -->
<div style="position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;">
  <div style="position:absolute;top:31%;left:46.7%;transform:translate(-50%,-50%);font-family:Arial,Helvetica,sans-serif;font-size:clamp(11px,1.6vw,22px);font-weight:bold;color:white;line-height:1;">PL</div>
  <div style="position:absolute;top:20%;left:51.5%;font-family:Georgia,'Times New Roman',serif;font-size:clamp(14px,2.1vw,28px);font-weight:bold;color:white;letter-spacing:0.5px;white-space:nowrap;">Postcode Loterij</div>
  <div style="position:absolute;top:34%;left:51.5%;font-family:Arial,Helvetica,sans-serif;font-size:clamp(9px,1.2vw,16px);color:white;opacity:0.75;white-space:nowrap;">Player Intelligence</div>
  <div style="position:absolute;top:53%;left:51.5%;font-family:Arial,Helvetica,sans-serif;font-size:clamp(7px,1vw,13px);color:white;opacity:0.6;white-space:nowrap;">AI-powered analytics built entirely on Snowflake</div>
</div>
</div>
""", unsafe_allow_html=True)

tab1, tab2, tab3, tab4 = st.tabs(["Player Dashboard", "Winner Draft", "AI Assistant", "AI Player Scoring"])

# ============================================================
# TAB 1: PLAYER DASHBOARD
# ============================================================
with tab1:

    # KPIs
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

    # Charts row 1
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
            GROUP BY CITY
            ORDER BY PLAYER_COUNT DESC
        """).to_pandas()
        st.bar_chart(city_df, x="CITY", y="PLAYER_COUNT", color=PL_BLUE)

    # Charts row 2
    col3, col4 = st.columns(2)

    with col3:
        st.subheader("Acquisition Channels")
        ch_df = session.sql("""
            SELECT ACQUISITION_CHANNEL, COUNT(*) AS PLAYERS
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            GROUP BY ACQUISITION_CHANNEL
            ORDER BY PLAYERS DESC
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

    # Segment detail table
    st.subheader("Segment Intelligence")
    seg_detail = session.sql("""
        SELECT
            SEGMENT,
            PLAYER_COUNT,
            AVG_MONTHLY_SPEND,
            AVG_SENTIMENT,
            AVG_TENURE AS AVG_TENURE_MONTHS,
            TOTAL_LTV,
            TOTAL_CHARITY_IMPACT
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY
        ORDER BY PLAYER_COUNT DESC
    """).to_pandas()
    st.dataframe(seg_detail, use_container_width=True)

    # Charity impact
    st.subheader("Charity Impact by Category")
    st.markdown(f'<div class="charity-banner">40% of every ticket sold goes directly to charity partners — over 150 organizations supported</div>', unsafe_allow_html=True)
    charity_cat = session.sql("""
        SELECT
            CATEGORY,
            COUNT(DISTINCT CHARITY_NAME) AS CHARITIES,
            ROUND(SUM(TOTAL_RECEIVED), 0) AS TOTAL_DONATED
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT
        GROUP BY CATEGORY
        ORDER BY TOTAL_DONATED DESC
    """).to_pandas()
    st.bar_chart(charity_cat, x="CATEGORY", y="TOTAL_DONATED", color=PL_GREEN)


# ============================================================
# TAB 2: WINNER DRAFT
# ============================================================
with tab2:

    st.subheader("Draft a Winner!")
    st.write("Select a draw and watch as we pick the winning postcode. Neighbours win together!")

    # Get available draws
    draws_df = session.sql("""
        SELECT DRAW_ID, DRAW_DATE, PRIZE_TYPE,
               TOTAL_PRIZE_POOL, WINNING_POSTCODE
        FROM POSTCODE_LOTERIJ_AI.RAW.DRAWS
        ORDER BY DRAW_DATE DESC
    """).to_pandas()

    # Select draw
    draw_options = draws_df.apply(
        lambda r: f"Draw {r['DRAW_ID']} \u2014 {r['DRAW_DATE']} \u2014 {r['PRIZE_TYPE']} (\u20ac{int(r['TOTAL_PRIZE_POOL']):,})",
        axis=1
    ).tolist()
    selected_draw_idx = st.selectbox("Select a draw", range(len(draw_options)),
                                      format_func=lambda i: draw_options[i])

    selected_draw = draws_df.iloc[selected_draw_idx]

    # Show draw info
    d1, d2, d3 = st.columns(3)
    d1.metric("Prize Type", selected_draw["PRIZE_TYPE"])
    d2.metric("Prize Pool", f"\u20ac{int(selected_draw['TOTAL_PRIZE_POOL']):,}")
    d3.metric("Draw Date", str(selected_draw["DRAW_DATE"]))

    st.markdown("---")

    # Draft button
    if st.button("Draft Winner!", type="primary"):

        # Get all active postcodes
        postcodes_df = session.sql("""
            SELECT DISTINCT POSTCODE, CITY
            FROM POSTCODE_LOTERIJ_AI.RAW.PLAYERS
            WHERE STATUS = 'Active'
        """).to_pandas()

        # Animated spinning effect
        placeholder = st.empty()
        postcode_list = postcodes_df["POSTCODE"].tolist()

        for i in range(20):
            rand_pc = random.choice(postcode_list)
            placeholder.markdown(
                f'<div class="spinning-postcode">{rand_pc}</div>',
                unsafe_allow_html=True
            )
            time.sleep(0.1 + i * 0.02)

        # Reveal the winning postcode
        winning_pc = selected_draw["WINNING_POSTCODE"]
        placeholder.empty()

        st.balloons()
        st.markdown(
            f'<div class="winner-reveal">Winning Postcode: {winning_pc}</div>',
            unsafe_allow_html=True
        )

        # Show winners in that postcode
        winners_df = session.sql(f"""
            SELECT
                PLAYER_NAME, POSTCODE, CITY, TICKET_TYPE, MONTHLY_SPEND,
                TENURE_MONTHS, STATUS
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            WHERE POSTCODE = '{winning_pc}' AND STATUS = 'Active'
        """).to_pandas()

        num_winners = len(winners_df)
        prize_per_winner = int(selected_draw["TOTAL_PRIZE_POOL"]) // max(num_winners, 1)

        w1, w2, w3 = st.columns(3)
        w1.metric("Winners in Postcode", num_winners)
        w2.metric("Prize per Winner", f"\u20ac{prize_per_winner:,}")
        w3.metric("Winning City",
                   winners_df["CITY"].iloc[0] if not winners_df.empty else "N/A")

        if not winners_df.empty:
            st.subheader("Congratulations to:")
            st.dataframe(winners_df, use_container_width=True)
        else:
            st.info("No active players found in this postcode for this draw.")

        # Show charity beneficiaries from this draw
        st.markdown("---")
        st.subheader("Charities supported by this draw")
        st.markdown(
            f'<div class="charity-banner">Every draw directly funds charity partners. Here are the top beneficiaries:</div>',
            unsafe_allow_html=True
        )
        charity_draw = session.sql(f"""
            SELECT
                CHARITY_NAME, CATEGORY,
                ROUND(DONATION_AMOUNT, 2) AS DONATED
            FROM POSTCODE_LOTERIJ_AI.RAW.DONATIONS
            WHERE DRAW_ID = {selected_draw['DRAW_ID']}
            ORDER BY DONATED DESC
            LIMIT 10
        """).to_pandas()
        st.dataframe(charity_draw, use_container_width=True)


# ============================================================
# TAB 3: AI ASSISTANT (placeholder — unlocked in Module 5)
# ============================================================
with tab3:
    st.subheader("AI Assistant")
    st.info("Complete **Module 5** to unlock the AI Assistant. "
            "You will create a Semantic View and Cortex Agent, "
            "then connect them to this tab.")


# ============================================================
# TAB 4: AI PLAYER SCORING
# ============================================================
with tab4:

    st.markdown("### AI Player Scoring")
    st.markdown(
        "Select any player and get a **real-time AI churn-risk assessment** "
        "powered by `SNOWFLAKE.CORTEX.COMPLETE`. No model training, no "
        "infrastructure — just a SQL function call that turns any LLM into "
        "a scoring engine."
    )

    # --- Player selector ---
    player_list_df = session.sql("""
        SELECT PLAYER_ID, PLAYER_NAME, CITY, STATUS
        FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
        ORDER BY PLAYER_NAME
    """).to_pandas()

    player_options = {
        f"{row['PLAYER_NAME']}  —  {row['CITY']} ({row['STATUS']})": row["PLAYER_ID"]
        for _, row in player_list_df.iterrows()
    }

    selected_label = st.selectbox(
        "Search or select a player",
        options=list(player_options.keys()),
        index=None,
        placeholder="Start typing a name...",
        key="scoring_player_select",
    )

    if selected_label:
        pid = player_options[selected_label]

        # Fetch full profile
        profile_df = session.sql(f"""
            SELECT *
            FROM POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_INTELLIGENCE
            WHERE PLAYER_ID = {pid}
        """).to_pandas()

        if profile_df.empty:
            st.warning("Player not found.")
        else:
            row = profile_df.iloc[0]

            # --- Profile card ---
            st.markdown("---")
            col_profile, col_stats = st.columns(2)

            with col_profile:
                st.markdown(f"**{row['PLAYER_NAME']}** · `{row['PLAYER_CODE']}`")
                st.markdown(
                    f"📍 {row['CITY']} · {row['POSTCODE']}  \n"
                    f"🎂 Age group: {row['AGE_GROUP']}  \n"
                    f"📅 Subscriber since {str(row['SUBSCRIPTION_START'])[:10]} "
                    f"({int(row['TENURE_MONTHS'])} months)"
                )

            with col_stats:
                seg_raw = row["PLAYER_SEGMENT_JSON"]
                try:
                    seg = json.loads(seg_raw)["label"] if isinstance(seg_raw, str) else seg_raw.get("label", str(seg_raw))
                except Exception:
                    seg = str(seg_raw)

                st.markdown(
                    f"**Status:** {row['STATUS']}  \n"
                    f"**Segment:** {seg}  \n"
                    f"**Ticket:** {row['TICKET_TYPE']} · €{int(row['MONTHLY_SPEND'])}/mo  \n"
                    f"**Lifetime value:** €{int(row['ESTIMATED_LIFETIME_VALUE']):,}  \n"
                    f"**Charity contribution:** €{int(row['CHARITY_CONTRIBUTION']):,}  \n"
                    f"**Sentiment:** {float(row['FEEDBACK_SENTIMENT']):.2f}"
                )

            # Feedback quote
            fb = row["FEEDBACK_TEXT"]
            if fb and fb != "No feedback provided.":
                st.info(f"💬  *\"{fb}\"*")

            # --- Score button ---
            st.markdown("---")
            if st.button("🎯 Score this Player", type="primary", key="score_btn"):

                with st.spinner("Running AI inference via Cortex COMPLETE..."):

                    # Build a structured prompt for the LLM scoring model
                    prompt = f"""You are a churn-risk scoring model for the Dutch Postcode Loterij.

Analyze this player profile and return a JSON object with exactly these keys:
- churn_risk_score: integer 0-100 (100 = certain to churn)
- risk_level: one of "Low", "Medium", "High", "Critical"
- top_factors: array of 3 short risk factor strings
- retention_action: one concrete recommended action (1 sentence)
- confidence: float 0.0-1.0

Player profile:
- Name: {row['PLAYER_NAME']}
- Status: {row['STATUS']}
- City: {row['CITY']}
- Age group: {row['AGE_GROUP']}
- Tenure: {int(row['TENURE_MONTHS'])} months
- Ticket type: {row['TICKET_TYPE']} (€{int(row['MONTHLY_SPEND'])}/month)
- Acquisition channel: {row['ACQUISITION_CHANNEL']}
- AI segment: {seg}
- Sentiment score: {float(row['FEEDBACK_SENTIMENT']):.2f}
- Lifetime value: €{int(row['ESTIMATED_LIFETIME_VALUE']):,}
- Feedback: "{fb}"

Return ONLY the JSON object, no explanation."""

                    scoring_df = session.sql(
                        "SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet', ?) AS RESULT",
                        params=[prompt],
                    ).to_pandas()

                    raw_result = scoring_df.iloc[0]["RESULT"]

                    # Parse JSON from LLM response
                    try:
                        # Strip markdown fences if present
                        clean = raw_result.strip()
                        if clean.startswith("```"):
                            clean = clean.split("\n", 1)[1]
                            clean = clean.rsplit("```", 1)[0]
                        score_data = json.loads(clean)
                    except Exception:
                        score_data = None

                    if score_data:
                        risk_score = score_data.get("churn_risk_score", "?")
                        risk_level = score_data.get("risk_level", "Unknown")
                        factors = score_data.get("top_factors", [])
                        action = score_data.get("retention_action", "N/A")
                        confidence = score_data.get("confidence", 0)

                        # Color-coded risk display
                        risk_colors = {
                            "Low": PL_GREEN,
                            "Medium": PL_ORANGE,
                            "High": PL_RED,
                            "Critical": PL_DARK_RED,
                        }
                        color = risk_colors.get(risk_level, "#666")

                        st.markdown(
                            f'<div style="background:{color};color:white;padding:1rem 1.5rem;'
                            f'border-radius:10px;font-size:1.3rem;font-weight:bold;'
                            f'text-align:center;margin:0.5rem 0;">'
                            f'Churn Risk: {risk_score}/100 — {risk_level}'
                            f"</div>",
                            unsafe_allow_html=True,
                        )

                        c1, c2 = st.columns(2)
                        with c1:
                            st.markdown("**Top Risk Factors**")
                            for f in factors:
                                st.markdown(f"- {f}")
                        with c2:
                            st.markdown("**Recommended Action**")
                            st.markdown(action)
                            st.caption(f"Model confidence: {confidence:.0%}")

                    else:
                        st.warning("Could not parse model response. Raw output:")
                        st.code(raw_result)

            # --- How it works callout ---
            st.markdown("---")
            st.markdown(
                f'<div style="background:#f0f7ff;border-left:4px solid {PL_BLUE};'
                f'padding:1rem 1.2rem;border-radius:6px;margin-top:0.5rem;">'
                f"<strong>💡 How does this work?</strong><br><br>"
                f"<code>SNOWFLAKE.CORTEX.COMPLETE</code> turns any supported LLM "
                f"into a real-time scoring engine with a single SQL call:<br><br>"
                f"<b>1.</b> The app fetches the player's enriched profile from "
                f"<code>PLAYER_INTELLIGENCE</code><br>"
                f"<b>2.</b> It builds a structured prompt with the player's segment, "
                f"sentiment, tenure, spend, and feedback<br>"
                f"<b>3.</b> <code>CORTEX.COMPLETE</code> sends the prompt to the LLM "
                f"and returns a JSON risk assessment<br>"
                f"<b>4.</b> The app parses the JSON and renders the result as a "
                f"color-coded risk banner<br><br>"
                f"No model training. No deployment pipeline. No data movement. "
                f"Your data stays in Snowflake and the LLM comes to it.</div>",
                unsafe_allow_html=True,
            )
```

### 3.4 Run the App

Click the **Run** button (blue play icon, top right of the editor). The app should load in the preview pane on the right.

You should see:
- A **red branded header** with the PL logo and title
- **Four tabs**: Player Dashboard, Winner Draft, AI Assistant, AI Player Scoring
- The Player Dashboard tab loaded with KPI cards and charts
- The AI Assistant tab shows a placeholder — you'll unlock it in Module 5
- The AI Player Scoring tab is live — try selecting a player and scoring them

> **Troubleshooting**:
>
> | Problem | Fix |
> |---------|-----|
> | `Table 'PLAYER_INTELLIGENCE' does not exist` | Go back and complete Module 2, Step 2.6 |
> | `View 'SEGMENT_SUMMARY' does not exist` | Go back and complete Module 2, Step 2.7 |
> | Charts show but no data | Make sure the AI enrichment query (Step 2.6) completed successfully |
> | App shows a blank screen or won't load | Click **Run** again. If it still fails, check that `environment.yml` has the exact content from Step 3.2 |
> | `Syntax error` in the code | Make sure you copied the *entire* code block from Step 3.3 — partial copies cause errors |
> | `Unknown model` error on scoring tab | Replace `'claude-3-5-sonnet'` in the Tab 4 code with `'mistral-large2'`. Test with: `SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', 'Say hello');` |

> **Snowflake Concept — Streamlit in Snowflake (SiS):**
>
> The Python code runs *inside Snowflake*, not on your laptop. Key elements:
> - `get_active_session()` — connects to the Snowflake session that's hosting the app
> - `session.sql("...")` — runs SQL queries directly against your Snowflake data
> - `session.sql(...).to_pandas()` — executes the query and returns results as a Pandas DataFrame
> - `st.session_state` — preserves data (like chat history) between user interactions

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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
2. Use the dropdown to **select a draw** — try picking a **Postcode Kanjer** (the biggest prize, happens in January)
3. Notice the KPI cards showing prize type, pool, and date
4. Click the red **"Draft Winner!"** button
5. Watch the **animated postcode spinner** — postcodes flash rapidly, then slow down
6. See the winning postcode revealed with balloons and a branded card
7. Review the **winners table** — these are all active players who share that postcode
8. Scroll down to see which **charities** were funded by this draw

> **This mirrors reality**: In the real Postcode Loterij, all neighbours who share a winning postcode win together. The prize pool is split among them. That's the "samen winnen" (winning together) concept.

### 4.3 AI Assistant (Preview)

1. Click the **AI Assistant** tab
2. You'll see a placeholder message — this tab will come alive in **Module 5**
3. After completing Module 5, you'll be able to ask natural language questions and the **Cortex Agent** will query your data in real time using the Semantic View you create

> **What's coming in Module 5**: Instead of a chatbot with hardcoded context, you'll build a Cortex Agent that dynamically generates SQL from natural language. The agent reads a Semantic View (a business-friendly data dictionary) and writes accurate queries on the fly — no manual prompt engineering needed.

### 4.4 AI Player Scoring

1. Click the **AI Player Scoring** tab
2. Use the **dropdown** to search for a player — start typing a name (e.g., "Jan" or "Sophie")
3. Review the **player profile card** — you should see their segment, sentiment, lifetime value, and feedback
4. Click the **"Score this Player"** button
5. Wait a few seconds — the LLM is analyzing the player profile and generating a structured risk assessment
6. You should see:
   - A **color-coded risk banner** (green = Low, orange = Medium, red = High/Critical)
   - **Top 3 risk factors** explaining why the player might churn
   - A **recommended retention action** — a concrete suggestion for what to do next
   - **Model confidence** — how confident the LLM is in its assessment
7. Try scoring **different player types** — compare an Active player vs a Churned player, or a High-Value Loyal vs an At-Risk player. Notice how the risk scores and factors change

> **How it works**: This tab uses the same LLM function (`CORTEX.COMPLETE`) you saw in Module 2 for generating retention messages — but here it acts as a **real-time scoring model**. You send it a player profile and it returns a structured risk score, no model training, no deployment pipeline, just a SQL function call.

> **Troubleshooting**:
>
> | Problem | Fix |
> |---------|-----|
> | `Unknown model` error | Replace `'claude-3-5-sonnet'` in the Tab 4 code with `'mistral-large2'`. Test with: `SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', 'Say hello');` |
> | Score button does nothing | Make sure you selected a player from the dropdown first |
> | `Could not parse model response` | The LLM occasionally returns malformed JSON. Click "Score this Player" again — it usually works on retry |

<p align="center"><img src="assets/divider.svg" width="80%"></p>

<img src="https://img.shields.io/badge/Module_5-Semantic_View_&_Agent-E40421?style=flat-square" alt="Module 5">

## Module 5 — Semantic View & Cortex Agent (20 min)

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

-- See all dimensions, facts, and metrics defined in the semantic view
DESCRIBE SEMANTIC VIEW POSTCODE_LOTERIJ_AI.ANALYTICS.PLAYER_SEMANTIC_VIEW;
```

You should see a detailed table listing every dimension (city, status, segment, etc.), fact (monthly_spend, tenure_months, etc.), and metric (player_count, avg_monthly_spend, churn_rate, etc.) — along with their expressions, data types, and synonyms.

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
>
 > **Model note**: The agent uses `claude-4-sonnet` as its orchestration model. If this model is not available in your region, replace `claude-4-sonnet` in the YAML with `claude-3-5-sonnet` or `mistral-large2`. You can test if a model works by running: `SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-4-sonnet', 'Say hello');`

### 5.4 Test the Agent in Snowsight

Before connecting the agent to our app, let's verify it works. You can test it directly from Snowsight:

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

> **Key insight**: The agent doesn't have hardcoded data. It reads the Semantic View you created in Step 5.1, understands the business meaning of each column, and writes SQL on the fly. This is fundamentally different from pasting data into a prompt.

### 5.5 Set Up Container Runtime

Our Streamlit app currently runs on a **warehouse** — great for dashboards, but it can't make web requests. To connect it to the Cortex Agent, we need to upgrade it to **container runtime**, which gives the app the ability to call Snowflake's AI APIs directly.

> **Trial account note**: Steps 5.5–5.8 require **external network access** (for installing PyPI packages in the container runtime), which is [not available on trial accounts](https://docs.snowflake.com/en/user-guide/admin-trial-account#current-limitations-for-trial-accounts). If the network rule or external access integration fails, you can skip steps 5.5–5.8. You already tested the agent in Step 5.4 via **AI & ML > Agents** — that works on any account. The Streamlit chatbot is just another way to access the same agent. To remove this limitation, convert your trial to a paid account.

Run these SQL statements **one block at a time** in your SQL worksheet:

```sql
-- 1. Create a compute pool (the server that will run our container)
CREATE COMPUTE POOL IF NOT EXISTS LOTERIJ_COMPUTE_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300;
```

```sql
-- 2. Allow the container to download Python packages from the internet
CREATE OR REPLACE NETWORK RULE POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_PYPI_RULE
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('pypi.org', 'files.pythonhosted.org');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION LOTERIJ_PYPI_ACCESS
  ALLOWED_NETWORK_RULES = (POSTCODE_LOTERIJ_AI.ANALYTICS.LOTERIJ_PYPI_RULE)
  ENABLED = TRUE;
```

```sql
-- 3. Verify the stage exists (Snowflake auto-creates it when you save the app)
--    You should see one row with POSTCODE_LOTERIJ_APP_STAGE
SHOW STAGES LIKE '%POSTCODE_LOTERIJ_APP%' IN SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;
```

> **What is this stage?** When you created the Streamlit app in Module 3 via the Snowsight UI, Snowflake automatically created an internal stage to store the app's files (`streamlit_app.py`, `environment.yml`). We need this stage to exist so the next command can read the code from it. If you don't see a result, go back to **Projects > Streamlit** and make sure your app exists.

```sql
-- 4. Upgrade the Streamlit app to container runtime
--    We recreate the app via SQL so we can attach the compute pool,
--    container runtime, and network access.
--    FROM copies your existing code automatically.
CREATE OR REPLACE STREAMLIT POSTCODE_LOTERIJ_AI.ANALYTICS.POSTCODE_LOTERIJ_APP
  FROM '@POSTCODE_LOTERIJ_AI.ANALYTICS.POSTCODE_LOTERIJ_APP_STAGE'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = 'LOTERIJ_WH'
  RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'
  COMPUTE_POOL = 'LOTERIJ_COMPUTE_POOL'
  TITLE = 'Postcode Loterij Intelligence'
  EXTERNAL_ACCESS_INTEGRATIONS = (LOTERIJ_PYPI_ACCESS);

-- 5. Activate the live version
--    This tells Snowflake to serve the latest saved code to users.
--    Without this, the app would show a "no live version" error.
ALTER STREAMLIT POSTCODE_LOTERIJ_AI.ANALYTICS.POSTCODE_LOTERIJ_APP
  ADD LIVE VERSION FROM LAST;
```

Each statement should show: `Statement executed successfully.` or `Streamlit POSTCODE_LOTERIJ_APP successfully created.`

> **Snowflake Concept — Container Runtime for Streamlit:**
>
> Streamlit in Snowflake can run in two modes:
> - **Warehouse runtime** (default): Your app runs on a virtual warehouse. Simple and fast, but the app cannot make web requests or install custom Python packages. This is what we used in Module 3.
> - **Container runtime**: Your app runs in its own container on a dedicated compute pool. This unlocks the ability to call Snowflake REST APIs (like the Cortex Agent) and install any Python package you need.
>
> **Why do we recreate the app with SQL?** In Module 3, we created the app through the Snowsight UI — quick and easy for a warehouse-based dashboard. To upgrade it to container runtime, we need to attach a compute pool and network access, which can only be done via SQL. The `CREATE OR REPLACE` rebuilds the app with these new settings while `FROM` preserves your existing code.
>
> **What are the three things we just created?**
> 1. **Compute pool** — a small server that runs the container (auto-suspends when idle to save costs)
> 2. **Network rule + external access integration** — a security policy that allows the container to download Python packages from `pypi.org` (Snowflake blocks all outbound traffic by default)
> 3. **Upgraded Streamlit app** — same code, now running on the container with full API access

### 5.6 Upload the Requirements File

Now reopen the Streamlit app in the editor:

1. In the left sidebar, click **Projects** > **Streamlit**
2. Click on **POSTCODE_LOTERIJ_APP** to open it

Container runtime uses a different package file than warehouse runtime. We need to replace `environment.yml` with a `requirements.txt` that lists the Python packages our app needs.

3. In the Streamlit editor, click the **file list** on the left
4. Click the **+** button to add a new file
5. Name it: `requirements.txt`
6. Paste the following content:

```
streamlit==1.50.0
snowflake-snowpark-python
requests
```

7. You can **delete** the `environment.yml` file (click the three dots next to it and select Delete) — it's no longer needed with container runtime

> **Why these packages?**
> - `streamlit==1.50.0` — The version of Streamlit that runs in container mode
> - `snowflake-snowpark-python` — Lets our app run SQL queries against Snowflake
> - `requests` — Lets our app call the Cortex Agent API

### 5.7 Upgrade Tab 3 — Connect the Agent

Now for the exciting part: replace the placeholder Tab 3 with the real Cortex Agent chatbot. 

1. Click on **`streamlit_app.py`** in the file list
2. Find the **imports** at the top of the file (lines 1-6). **Replace** them with:

```python
import streamlit as st
import pandas as pd
import json
import time
import random
import os
import requests
from snowflake.snowpark.context import get_active_session
```

3. Find the **Tab 3 placeholder** near the bottom of the file. Use **Ctrl+F / Cmd+F** to search for `# TAB 3: AI ASSISTANT`. You should find a block that looks like this:

   ```python
   # ============================================================
   # TAB 3: AI ASSISTANT (placeholder — unlocked in Module 5)
   # ============================================================
   with tab3:
       st.subheader("AI Assistant")
       st.info("Complete **Module 5** to unlock the AI Assistant. "
               ...
   ```

   **Select and delete** the entire Tab 3 placeholder block — from the `# ====` comment line above `# TAB 3` down to (but **not including**) the `# ====` comment line above `# TAB 4`. Then **paste** the following code in its place:

```python
# ============================================================
# TAB 3: AI ASSISTANT
# ============================================================
with tab3:

    st.subheader("Ask questions about player data and charity impact")
    st.caption("Powered by Cortex Agent + Semantic View — your data never leaves Snowflake")

    # ---- Cortex Agent helpers ----
    AGENT_ENDPOINT = (
        "/api/v2/databases/POSTCODE_LOTERIJ_AI/schemas/ANALYTICS"
        "/agents/LOTERIJ_AGENT:run"
    )

    def get_agent_token():
        """Read the SPCS session token for authenticated API calls."""
        with open("/snowflake/session/token", "r") as f:
            return f.read().strip()

    def call_agent(prompt, conversation_history=None):
        """Call the Cortex Agent API and return the full response text."""
        token = get_agent_token()
        host = os.environ.get("SNOWFLAKE_HOST", "")
        url = f"https://{host}{AGENT_ENDPOINT}"

        messages = []
        if conversation_history:
            for m in conversation_history:
                messages.append({
                    "role": m["role"],
                    "content": [{"type": "text", "text": m["content"]}],
                })
        messages.append({
            "role": "user",
            "content": [{"type": "text", "text": prompt}],
        })

        payload = {"messages": messages, "stream": True}
        headers = {
            "Authorization": f"Bearer {token}",
            "X-Snowflake-Authorization-Token-Type": "OAUTH",
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
        }

        response_text = ""
        current_event = ""
        with requests.post(url, json=payload, headers=headers, stream=True) as r:
            r.raise_for_status()
            for raw_line in r.iter_lines():
                if not raw_line:
                    continue
                line = raw_line.decode("utf-8")
                # Track the SSE event type
                if line.startswith("event:"):
                    current_event = line[len("event:"):].strip()
                    continue
                if line.startswith("data: "):
                    data_str = line[len("data: "):]
                elif line.startswith("data:"):
                    data_str = line[len("data:"):]
                else:
                    continue
                data_str = data_str.strip()
                if data_str == "[DONE]":
                    break
                # Only capture the final response text, skip reasoning/thinking
                if current_event not in ("response.text.delta", ""):
                    continue
                try:
                    event = json.loads(data_str)
                    if "text" in event:
                        response_text += event["text"]
                    elif "delta" in event:
                        delta = event["delta"]
                        for item in delta.get("content", []):
                            if item.get("type") == "text":
                                response_text += item.get("text", "")
                except json.JSONDecodeError:
                    continue
        return response_text

    # ---- Suggestion prompts ----
    SUGGESTIONS = {
        "Segments": "What are the key characteristics of each player segment? Which segment should we focus retention efforts on?",
        "Charity": "How is our charity funding distributed? Which categories receive the most and what is the total impact?",
        "Churn": "What can you tell me about churn patterns? What strategies would you recommend to reduce churn?",
        "Growth": "What are the top 3 growth opportunities based on the player data?",
    }

    if "messages" not in st.session_state:
        st.session_state.messages = []

    # Clear chat button (only show when there are messages)
    if st.session_state.messages:
        if st.button("Clear chat", key="clear_chat"):
            st.session_state.messages = []
            st.rerun()

    # Suggestion buttons (two rows of two)
    if not st.session_state.messages:
        st.write("**Try one of these questions:**")
        items = list(SUGGESTIONS.items())
        row1 = st.columns(2)
        for i in range(2):
            with row1[i]:
                if st.button(items[i][0], use_container_width=True):
                    st.session_state.messages.append({"role": "user", "content": items[i][1]})
                    st.rerun()
        row2 = st.columns(2)
        for i in range(2, 4):
            with row2[i - 2]:
                if st.button(items[i][0], use_container_width=True):
                    st.session_state.messages.append({"role": "user", "content": items[i][1]})
                    st.rerun()

    # Chat container — fixed height only when there are messages to scroll
    if st.session_state.messages:
        chat_container = st.container(height=500)
    else:
        chat_container = st.container()

    # Chat history
    with chat_container:
        for msg in st.session_state.messages:
            with st.chat_message(msg["role"]):
                st.markdown(msg["content"])

    # Chat input (outside container so it stays pinned below)
    if prompt := st.chat_input("Ask about players, charities, or performance..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with chat_container:
            with st.chat_message("user"):
                st.markdown(prompt)

    # Process pending user message via Cortex Agent
    if st.session_state.messages and st.session_state.messages[-1]["role"] == "user":
        with chat_container:
            with st.chat_message("assistant"):
                with st.spinner("Agent is querying your data..."):
                    history = st.session_state.messages[:-1]
                    user_msg = st.session_state.messages[-1]["content"]
                    try:
                        response = call_agent(user_msg, history)
                        if not response.strip():
                            response = "The agent returned an empty response. Try rephrasing your question."
                    except Exception as e:
                        response = f"Could not reach the Cortex Agent. Error: {e}"
                    st.markdown(response)
        st.session_state.messages.append({"role": "assistant", "content": response})
```

4. Click **Run** to reload the app

> **Snowflake Concept — How the Agent Chatbot Works:**
>
> When a user types a question in the chat, the app:
> 1. **Authenticates** automatically — the container runtime provides a secure session token, so no passwords or API keys are needed
> 2. **Sends the question** to the Cortex Agent you created in Step 5.3
> 3. **The agent generates SQL** using the Semantic View from Step 5.1 — it understands what each column means and writes the right query
> 4. **Returns the answer** as natural language — the user sees a response with real numbers, not the raw SQL
>
> The app never sees the raw data directly. It asks the agent a question and gets back a human-readable answer. This is the same pattern used in production Snowflake applications.

### 5.8 Test the AI Assistant

Now try the AI Assistant in your app:

1. Click the **AI Assistant** tab
2. Click one of the **suggestion buttons** (e.g., "Segments")
3. Watch the agent query your data and respond with real numbers
4. Try a **follow-up question** in the chat input:
   - *"Which city has the highest churn rate?"*
   - *"What would happen to charity funding if we reduced churn by 5%?"*
   - *"Compare the average spend of New Players vs High-Value Loyal"*
5. Notice the agent gives **specific numbers** — it's running SQL against your actual data, not guessing

> **Troubleshooting**:
>
> | Problem | Fix |
> |---------|-----|
> | `Could not reach the Cortex Agent` | Wait 1-2 minutes for the compute pool to start, then refresh |
> | `403 Forbidden` | Check that the Streamlit app was created with the correct compute pool and EAI in Step 5.5 |
> | Agent returns empty responses | Verify the agent exists: `SHOW AGENTS IN SCHEMA POSTCODE_LOTERIJ_AI.ANALYTICS;` |
> | App shows a loading error | Make sure you ran all three SQL blocks in Step 5.5 and that the compute pool is running: `SHOW COMPUTE POOLS;` |
> | `Syntax error` after pasting the code | Make sure you replaced only the Tab 3 placeholder block, and that the imports at the top include `os` and `requests` |

### 5.9 What You Just Built

You created a complete AI analytics stack — from raw data to a conversational interface:

```
User asks a question in the Streamlit app
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
   Answer with real numbers — displayed in the app
```

This is the same architecture that production Snowflake customers use to give business users self-service analytics without writing SQL. And it all runs inside your Streamlit app.

<p align="center"><img src="assets/divider.svg" width="80%"></p>

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

Cortex Code is available as a CLI tool. To access it:

1. **Open a terminal** on your laptop (Terminal on Mac, Command Prompt or PowerShell on Windows)
2. If Cortex Code is pre-installed, run: `cortex` to start a session
3. If not yet installed, your instructor will provide the installation command or a shared environment
4. Once connected, set your Snowflake context:
   - Type: *"Connect to my Snowflake account and use database POSTCODE_LOTERIJ_AI"*
5. Then describe what you want to build — for example, paste one of the challenge prompts above

The general workflow is:

1. **Describe** what you want to build in plain language
2. **Review** the generated code — Cortex Code will explain what it does
3. **Run** the code in Snowflake (Cortex Code can execute it directly)
4. **Iterate** — ask for modifications or improvements

> **The takeaway**: The SQL and Streamlit code you manually built in Modules 1-3 could also be generated this way. Cortex Code accelerates the development process from hours to minutes, while keeping you in control of the result.

<p align="center"><img src="assets/divider.svg" width="80%"></p>

## Recap — What You Built

| | Component | Snowflake Technology | What it does |
|:-:|-----------|---------------------|--------------|
| 🎲 | Synthetic data | `GENERATOR()`, `UNIFORM()`, `RANDOM()` | Creates realistic test data without external files |
| 💬 | Sentiment analysis | `SNOWFLAKE.CORTEX.SENTIMENT` | Scores player feedback from -1 to +1 |
| 🏷️ | Player segmentation | `AI_CLASSIFY` | Categorizes players into 6 segments using zero-shot classification |
| 🔍 | Insight extraction | `AI_EXTRACT` | Pulls structured fields from unstructured text |
| 📝 | Profile summaries | `SNOWFLAKE.CORTEX.SUMMARIZE` | Creates one-sentence player summaries |
| ✉️ | Personalized messages | `SNOWFLAKE.CORTEX.COMPLETE` | Generates custom retention copy using an LLM |
| 📊 | Interactive dashboard | Streamlit in Snowflake | Four-tab branded dashboard with KPIs, charts, tables, and AI scoring |
| 🤖 | AI Agent chatbot | Cortex Agent + Semantic View | Conversational assistant that queries your data in real time |
| 🎯 | AI Player Scoring | `SNOWFLAKE.CORTEX.COMPLETE` | Real-time churn risk assessment — no model training, just a SQL function call |
| 📐 | Semantic View | `CREATE SEMANTIC VIEW` | Business data model with dimensions, facts, and metrics |
| 🧠 | AI Agent | `CREATE AGENT` + Cortex Analyst | Natural language to SQL — ask questions, get answers |
| 🐳 | Container runtime | Compute Pool + SPCS | Enables REST API calls from Streamlit to the Cortex Agent |

**🔒 Everything ran inside Snowflake.** No external APIs. No additional tools. No data left your account.

<p align="center"><img src="assets/divider.svg" width="80%"></p>

## Cleanup (Optional)

To remove everything created in this lab:

```sql
DROP DATABASE IF EXISTS POSTCODE_LOTERIJ_AI;
DROP WAREHOUSE IF EXISTS LOTERIJ_WH;
DROP COMPUTE POOL IF EXISTS LOTERIJ_COMPUTE_POOL;
DROP INTEGRATION IF EXISTS LOTERIJ_PYPI_ACCESS;
```

<p align="center"><img src="assets/divider.svg" width="80%"></p>

## Additional Resources

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/guides-overview-ai-features)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Streamlit Container Runtime](https://docs.snowflake.com/en/developer-guide/streamlit/app-development/runtime-environments)
- [Semantic Views Documentation](https://docs.snowflake.com/en/user-guide/views-semantic/sql)
- [Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [CREATE SEMANTIC VIEW Reference](https://docs.snowflake.com/en/sql-reference/sql/create-semantic-view)
- [CREATE AGENT Reference](https://docs.snowflake.com/en/sql-reference/sql/create-agent)
- [AI_CLASSIFY Function Reference](https://docs.snowflake.com/en/sql-reference/functions/ai_classify)
- [AI_EXTRACT Function Reference](https://docs.snowflake.com/en/sql-reference/functions/ai_extract)
- [CORTEX.COMPLETE Function Reference](https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex)
- [CORTEX.SENTIMENT Function Reference](https://docs.snowflake.com/en/sql-reference/functions/sentiment-snowflake-cortex)
- [CORTEX.SUMMARIZE Function Reference](https://docs.snowflake.com/en/sql-reference/functions/summarize-snowflake-cortex)

<p align="center"><img src="assets/divider.svg" width="80%"></p>

*Lab designed for Postcode Loterij by the Snowflake team.*

<img src="assets/border.svg" width="100%">