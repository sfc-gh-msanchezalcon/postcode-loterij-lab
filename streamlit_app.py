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
PL_LIGHT_BG = "#FFF5F5"

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
  <div style="position:absolute;top:22%;left:45.2%;width:56px;text-align:center;font-family:Arial,Helvetica,sans-serif;font-size:clamp(11px,1.6vw,22px);font-weight:bold;color:white;">PL</div>
  <div style="position:absolute;top:18%;left:51%;font-family:Georgia,'Times New Roman',serif;font-size:clamp(14px,2.1vw,28px);font-weight:bold;color:white;letter-spacing:0.5px;white-space:nowrap;">Postcode Loterij</div>
  <div style="position:absolute;top:33%;left:51%;font-family:Arial,Helvetica,sans-serif;font-size:clamp(9px,1.2vw,16px);color:white;opacity:0.75;white-space:nowrap;">Player Intelligence</div>
  <div style="position:absolute;top:48%;left:51%;font-family:Arial,Helvetica,sans-serif;font-size:clamp(7px,1vw,13px);color:white;opacity:0.6;white-space:nowrap;">AI-powered analytics built entirely on Snowflake</div>
</div>
</div>
""", unsafe_allow_html=True)

# -- Navigation --
tab1, tab2, tab3 = st.tabs(["Player Dashboard", "Winner Draft", "AI Assistant"])

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
# TAB 3: AI ASSISTANT
# ============================================================
with tab3:

    st.subheader("Ask questions about player data and charity impact")
    st.caption("Powered by Snowflake Cortex AI — your data never leaves Snowflake")

    # Build context
    @st.cache_data(ttl=600)
    def get_context():
        seg = session.sql("""
            SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.SEGMENT_SUMMARY
        """).to_pandas()
        charity = session.sql("""
            SELECT * FROM POSTCODE_LOTERIJ_AI.ANALYTICS.CHARITY_IMPACT
            ORDER BY TOTAL_RECEIVED DESC LIMIT 15
        """).to_pandas()
        kpis = session.sql("""
            SELECT
                COUNT(*) AS TOTAL_PLAYERS,
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
- The brand rebranded in January 2026 from Nationale Postcode Loterij to Postcode Loterij

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

    # Suggestion buttons
    if not st.session_state.messages:
        st.write("**Try one of these questions:**")
        for label, question in SUGGESTIONS.items():
            if st.button(f"{label}: {question}"):
                st.session_state.messages.append({"role": "user", "content": question})
                st.experimental_rerun()

    # Chat history
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.write(msg["content"])

    # Chat input
    if prompt := st.chat_input("Ask about players, charities, or performance..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.write(prompt)

    # Process pending user message
    if st.session_state.messages and st.session_state.messages[-1]["role"] == "user":
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                # Build prompt string
                prompt_parts = [f"SYSTEM: {SYSTEM_PROMPT}"]
                for m in st.session_state.messages:
                    prompt_parts.append(f"{m['role'].upper()}: {m['content']}")
                prompt_parts.append("ASSISTANT:")
                full_prompt = "\n\n".join(prompt_parts)

                result_df = session.create_dataframe([{"dummy": "x"}]).select(
                    call_builtin(
                        "SNOWFLAKE.CORTEX.COMPLETE",
                        lit("claude-3-5-sonnet"),
                        lit(full_prompt),
                    ).alias("RESPONSE")
                )
                response = result_df.collect()[0]["RESPONSE"]
                st.write(response)

        st.session_state.messages.append({"role": "assistant", "content": response})
