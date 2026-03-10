import streamlit as st
import pandas as pd
import json
import time
import random
import os
import requests
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

    /* Section headers — inherit theme color for dark/light mode */

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

# -- Navigation --
tab1, tab2, tab3, tab4 = st.tabs(["Player Dashboard", "Winner Draft", "AI Player Scoring", "AI Assistant"])

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
# TAB 3: AI PLAYER SCORING
# ============================================================
with tab3:

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
                    parsed = json.loads(seg_raw) if isinstance(seg_raw, str) else seg_raw
                    seg = parsed.get("labels", [parsed.get("label", seg_raw)])[0]
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


# ============================================================
# TAB 4: AI ASSISTANT
# ============================================================
with tab4:

    st.subheader("Ask questions about player data and charity impact")
    st.caption("Powered by Cortex Agent + Semantic View — your data never leaves Snowflake")

    # ---- Cortex Agent helpers ----
    AGENT_ENDPOINT = (
        "/api/v2/databases/POSTCODE_LOTERIJ_AI/schemas/ANALYTICS"
        "/agents/LOTERIJ_AGENT:run"
    )

    def get_agent_token():
        """Read the SPCS session token for authenticated API calls."""
        token_path = "/snowflake/session/token"
        if not os.path.exists(token_path):
            raise RuntimeError(
                "Session token not found. This means the app is not running on container runtime. "
                "Go back to Step 5.5 and make sure you ran all three SQL blocks, then run "
                "ALTER STREAMLIT ... ADD LIVE VERSION FROM LAST in Step 5.7. "
                "After that, close this tab and reopen the app from Projects > Streamlit."
            )
        with open(token_path, "r") as f:
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
