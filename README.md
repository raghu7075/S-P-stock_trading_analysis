# S&P 500 Stock Data Analysis Project

A comprehensive financial data analysis project examining stock market performance, volatility patterns, risk-return profiles, and investment strategies using Databricks SQL and Power BI.

## 📊 Project Overview

This project analyzes 5 years of S&P 500 stock market data (February 2013 - February 2018) covering 505 companies with 619,029 daily trading records. The analysis includes 20 sophisticated SQL queries addressing returns, volatility, correlations, seasonality, and investment strategy optimization.

---

## 📁 Dataset

**Table Name:** `testdb.default.s_p_stock_data`

**Format:** Delta Lake

**Time Period:** February 8, 2013 to February 7, 2018 (5 years / 1,825 days)

**Coverage:** 505 S&P 500 companies

**Total Records:** 619,029 daily observations

### Schema:

 Column | Type | Description |
--------|------|-------------|
 `Date` | timestamp | Trading date |
 `Open ($)` | string | Opening price (includes $ and commas) |
 `High ($)` | string | Highest price of the day |
 `Low ($)` | string | Lowest price of the day |
 `Close ($)` | string | Closing price |
 `Volume` | bigint | Number of shares traded |
 `Name` | string | Stock ticker symbol |

**Note:** Price columns are stored as strings with dollar signs ($) and commas. All queries include proper conversion to DOUBLE type.

---

## 🔍 Analysis Queries (20 Questions)

### 1. **Highest Returns vs. Benchmark**
Calculates total return for each stock and compares against portfolio average (benchmark).

**Key Findings:**
- NVDA: 1,749% return (highest)
- NFLX: 923% return
- ALGN: 616% return
- Technology stocks dominated performance

### 2. **Stock Performance Over Time**
Comprehensive performance metrics showing start price, end price, and total return for all stocks.

### 3. **Market Volatility Analysis**
Identifies stocks with highest and lowest volatility using standard deviation of daily returns.

**Volatility Leaders:**
- Highest: CHK (4.17%), AMD (3.78%), BHGE (3.52%)
- Lowest: PEP (0.84%), RSG (0.88%), WM (0.88%)

### 4. **Sector Return Trends**
Analyzes return patterns across different sectors (using letter-based grouping as proxy).

### 5. **Price Extremes**
Identifies companies with highest and lowest stock prices during the analysis period.

### 6. **Major Market Drawdowns**
Calculates drawdowns from peak prices to identify market decline periods (>20% drops).

### 7. **Volume-Price Correlation**
Analyzes correlation between trading volume and price movement.

**Strong Correlations Found:**
- EVHC: 0.87 (Strong Positive)
- STZ: 0.81 (Strong Positive)
- Higher volume often accompanies larger price movements

### 8. **Risk-Return Balance (Sharpe Ratio)**
Identifies stocks with best risk-adjusted returns.

**Top Performers:**
- DXC: 2.19 Sharpe ratio
- HLT: 2.02
- NOC: 1.97

### 9. **Moving Average Trends**
Uses 50-day and 200-day moving averages to identify bullish/bearish trends and crossover events (Golden Cross / Death Cross).

### 10. **Stable Long-Term Growth**
Identifies companies with consistent positive returns and low volatility (stability score = return/volatility).

### 11. **Portfolio Diversification Impact**
Quantifies risk reduction through diversification by comparing portfolio volatility vs. individual stock volatility.

### 12. **Consistent Outperformers**
Identifies stocks that beat market average most frequently.

### 13. **Monthly/Quarterly Seasonality**
Analyzes seasonal patterns in stock performance.

**Monthly Trends:**
- Best months: October (2.76% avg), November (2.66%)
- Worst months: August (-1.27%), January (-0.52%)
- October: 67% positive months (most bullish)

### 14. **Sector Contribution to Profitability**
Measures which sectors (letter groups) contribute most to overall returns.

### 15. **Trading Activity Consistency**
Analyzes volume consistency and trends over time using coefficient of variation.

### 16. **Portfolio vs. Benchmark Performance**
Tracks cumulative equal-weighted portfolio performance over time.

### 17. **Short-Term Price Fluctuations**
Identifies stocks with highest intraday volatility (high-low range).

### 18. **Sector-Level Trend Differences**
Compares sector performance trends across the market.

### 19. **Market Risk Indicators**
Highlights periods of increased market risk using volatility spikes, broad declines, and dispersion metrics.

### 20. **Investment Strategy Classification**
Classifies stocks as suitable for conservative vs. aggressive investment strategies.

**Conservative (Low volatility, steady returns):**
- WM, RSG, BRK.B, JNJ, MCD, PEP

**Aggressive (High volatility, high returns):**
- NVDA, STZ, HII, BA, ADBE, AMZN, FB

---

## 📈 SQL Query File

**File:** `stock_analysis_queries.sql`

**Location:** `/Users/mocharlaraghu36@gmail.com/stock_analysis_queries.sql`

**Contents:**
- 20 production-ready SQL queries
- Comprehensive documentation and comments
- Proper data type conversions
- Window functions for time-series analysis
- CTEs (Common Table Expressions) for readability
- Optimized for 5-year dataset

**Query Features:**
- String-to-numeric conversion (removes $, commas)
- Annualized return/volatility calculations
- Correlation analysis (CORR function)
- Moving averages (window functions)
- Risk metrics (Sharpe ratios, drawdowns)
- Seasonality analysis (monthly/quarterly patterns)

---

## 📊 Power BI Dashboard

### Dashboard Overview

An interactive Power BI dashboard visualizes all 20 analytical queries, enabling stakeholders to explore stock performance, volatility, correlations, and investment insights through dynamic filtering and drill-down capabilities.

### Dashboard Pages:

#### **1. Executive Summary**
- **KPIs:** Total return, portfolio volatility, number of stocks analyzed
- **Visuals:**
  - Portfolio cumulative return line chart (5-year trend)
  - Top 10 performers bar chart
  - Volatility distribution histogram
  - Risk-return scatter plot (all stocks)

#### **2. Performance Analysis**
- **Stock returns vs. benchmark** (waterfall chart)
- **Performance heatmap** by stock and year
- **Returns distribution** (box plot by sector proxy)
- **Monthly seasonality** (line chart with month comparison)
- **Best/worst performers** table with sparklines

#### **3. Volatility & Risk**
- **Volatility ranking** (sorted bar chart - high to low)
- **Drawdown analysis** (area chart showing peak-to-trough declines)
- **Risk indicators timeline** (flagging high volatility periods)
- **Intraday range analysis** (average daily high-low percentage)

#### **4. Risk-Return Analysis**
- **Sharpe ratio leaderboard** (top 30 stocks)
- **Efficient frontier scatter plot** (return vs. volatility)
- **Conservative vs. Aggressive classification** (segmented view)
- **Risk-adjusted return trends** over time

#### **5. Correlation & Volume**
- **Volume-price correlation matrix** (heatmap)
- **Volume trends** (line chart with moving average)
- **Trading activity consistency** (coefficient of variation chart)
- **Volume spikes analysis** (highlighting unusual activity)

#### **6. Moving Averages & Trends**
- **Moving average crossovers** (50-day vs. 200-day)
- **Bullish/Bearish signal count** by stock
- **Golden Cross / Death Cross events** timeline
- **Trend strength indicator** (current signals)

#### **7. Investment Strategy**
- **Portfolio diversification impact** (risk reduction gauge)
- **Consistent outperformers** (beat market % ranking)
- **Stable growth leaders** (stability score ranking)
- **Strategy recommendation matrix** (conservative/moderate/aggressive)

#### **8. Sector & Segmentation**
- **Sector return comparison** (letter-based grouping)
- **Sector contribution** to total portfolio
- **Cross-sector volatility** comparison
- **Sector correlation heatmap**

---
## 🚀 Getting Started

### Prerequisites

**Databricks Environment:**
- Databricks workspace (AWS/Azure/GCP)
- SQL Warehouse or Serverless Cluster
- Access to `testdb.default.s_p_stock_data` table

**Power BI:**
- Power BI Desktop (latest version)
- Power BI Pro/Premium license (for publishing)
- Databricks connector installed

**Permissions:**
- READ access to Delta table
- EXECUTE permissions on SQL warehouse

---

### Setup Instructions

#### 1. **Data Verification**
```sql
-- Verify data availability
SELECT 
    MIN(Date) as start_date,
    MAX(Date) as end_date,
    COUNT(DISTINCT Name) as stocks,
    COUNT(*) as records
FROM testdb.default.s_p_stock_data;
```

#### 2. **Run SQL Queries**
- Open `stock_analysis_queries.sql` in Databricks SQL Editor
- Execute queries individually or in batch
- Validate results before connecting to Power BI

#### 3. **Power BI Setup**
- Open Power BI Desktop
- Get Data → More → Databricks
- Enter connection credentials
- Import or use DirectQuery mode
- Load queries or tables as needed

#### 4. **Dashboard Development**
- Create calculated columns for price conversions
- Build DAX measures (see above)
- Design visualizations per page layout
- Configure filters and interactions
- Add bookmarks for key insights

#### 5. **Publish & Share**
- Publish to Power BI Service
- Configure data refresh schedule
- Set up row-level security (if needed)
- Share with stakeholders

---

## 📊 Key Insights Summary

### Performance Insights:
- **Top Performer:** NVDA with 1,749% return over 5 years
- **Average Portfolio Return:** ~93% (benchmark)
- **Technology Leadership:** Tech stocks dominated top 20 performers

### Risk Insights:
- **Most Volatile:** CHK (4.17% daily std dev)
- **Most Stable:** PEP (0.84% daily std dev)
- **Diversification Benefit:** Portfolio volatility reduced by ~35% vs. average stock

### Seasonal Insights:
- **Best Month:** October (2.76% avg return, 67% positive)
- **Worst Month:** August (-1.27% avg return, 42% positive)
- **Quarterly Pattern:** Q4 strongest, Q3 weakest

### Strategy Insights:
- **Conservative Picks:** WM, RSG, BRK.B (low volatility, steady growth)
- **Aggressive Picks:** NVDA, NFLX, ALGN (high risk, high reward)
- **Best Risk-Adjusted:** DXC, HLT, NOC (Sharpe > 2.0)

### Volume Insights:
- **Strong Correlation:** 50+ stocks show volume-price correlation > 0.6
- **Volume Leadership:** EVHC (0.87 correlation)

---

## 🛠️ Technologies Used

 Category | Technology |
----------|-----------|
 **Data Storage** | Delta Lake (Databricks) |
 **Compute** | Databricks SQL Serverless |
 **Analytics** | Databricks SQL (Spark SQL) |
 **Visualization** | Power BI Desktop & Service |
 **Cloud Platform** | AWS (Databricks) |
 **Languages** | SQL (primary), DAX (Power BI) |
 **Version Control** | Git (recommended for SQL files) |

---

## 📋 Query Execution Guide

### Running Individual Queries:

**Option 1: Databricks SQL Editor**
```
1. Open stock_analysis_queries.sql
2. Select specific query (highlight)
3. Click "Run" or press Shift+Enter
4. View results in table/chart format
5. Export as CSV if needed
```

**Option 2: Notebooks**
```sql
-- Copy query into notebook cell
-- Execute with Cmd/Ctrl + Enter
-- Results appear below cell
```

**Option 3: Scheduled Jobs**
```
1. Create Databricks Job
2. Add SQL query task
3. Schedule (daily, weekly, etc.)
4. Configure notifications
```

---

## 🔄 Maintenance & Updates

### Data Refresh:
- **Frequency:** Historical data (static); add new periods as available
- **Process:** Append new records to Delta table, re-run queries
- **Validation:** Check for duplicates, missing dates, price anomalies

### Query Updates:
- **Modifications:** Edit SQL file, test in Databricks, update Power BI
- **New Queries:** Add to SQL file with proper documentation
- **Deprecations:** Comment out instead of deleting (preserve history)

### Dashboard Updates:
- **New Visuals:** Add to existing pages or create new pages
- **DAX Updates:** Test measures thoroughly before publishing
- **Performance:** Monitor query times, optimize as needed

---

## 🐛 Troubleshooting

### Common Issues:

**Issue:** Price columns returning NULL
- **Cause:** String format with $ and commas
- **Fix:** Use `CAST(REPLACE(REPLACE(column, '$', ''), ',', '') AS DOUBLE)`

**Issue:** Query timeout
- **Cause:** Full table scan on 619K records
- **Fix:** Add date filters, use indexed columns, optimize joins

**Issue:** Power BI connection fails
- **Cause:** Authentication or network issues
- **Fix:** Verify PAT token, check firewall rules, test SQL warehouse

**Issue:** Incorrect correlation results
- **Cause:** Insufficient data points
- **Fix:** Ensure `HAVING COUNT(*) >= 100` filter is applie

---

## 📄 License

This project is provided for educational and analytical purposes. Stock data is historical and should not be used as the sole basis for investment decisions.

---

## 🎯 Future Enhancements

- [ ] Add sector classification mapping table
- [ ] Implement machine learning price prediction models
- [ ] Create real-time dashboard with live data feeds
- [ ] Add sentiment analysis from news/social media
- [ ] Build portfolio optimization simulator
- [ ] Integrate additional market indicators (VIX, bonds, commodities)
- [ ] Create mobile-responsive Power BI app
- [ ] Add AI-powered natural language Q&A

---

