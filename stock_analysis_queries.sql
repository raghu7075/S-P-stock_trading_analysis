

-- QUERY 1: Which companies generated the highest returns compared to benchmark?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
first_last_prices AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close
  FROM stock_prices
),
stock_returns AS (
  SELECT DISTINCT
    Name,
    first_close,
    last_close,
    ((last_close - first_close) / NULLIF(first_close, 0)) * 100 as total_return_pct
  FROM first_last_prices
  WHERE first_close > 0 AND last_close > 0
),
benchmark AS (
  SELECT AVG(total_return_pct) as avg_return
  FROM stock_returns
)
SELECT 
  r.Name as stock_ticker,
  ROUND(r.first_close, 2) as starting_price,
  ROUND(r.last_close, 2) as ending_price,
  ROUND(r.total_return_pct, 2) as return_pct,
  ROUND(r.total_return_pct - b.avg_return, 2) as excess_return_vs_benchmark
FROM stock_returns r
CROSS JOIN benchmark b
ORDER BY r.total_return_pct DESC
LIMIT 50;

-- QUERY 2: How has each stock performed over the selected time period?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
first_last_prices AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close,
    FIRST_VALUE(Date) OVER (PARTITION BY Name ORDER BY Date ASC) as first_date,
    FIRST_VALUE(Date) OVER (PARTITION BY Name ORDER BY Date DESC) as last_date
  FROM stock_prices
),
performance AS (
  SELECT DISTINCT
    Name,
    first_date,
    last_date,
    DATEDIFF(last_date, first_date) as days_traded,
    first_close,
    last_close,
    ((last_close - first_close) / NULLIF(first_close, 0)) * 100 as total_return_pct,
    last_close - first_close as absolute_gain
  FROM first_last_prices
  WHERE first_close > 0
)
SELECT 
  Name,
  DATE_FORMAT(first_date, 'yyyy-MM-dd') as start_date,
  DATE_FORMAT(last_date, 'yyyy-MM-dd') as end_date,
  days_traded,
  ROUND(first_close, 2) as starting_price,
  ROUND(last_close, 2) as ending_price,
  ROUND(absolute_gain, 2) as price_change,
  ROUND(total_return_pct, 2) as return_pct
FROM performance
ORDER BY total_return_pct DESC;

-- QUERY 3: Which stocks exhibit the highest and lowest market volatility?

WITH daily_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return_pct
  FROM daily_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
volatility AS (
  SELECT 
    Name,
    STDDEV(daily_return_pct) as volatility_stddev,
    AVG(ABS(daily_return_pct)) as avg_abs_return,
    COUNT(*) as trading_days
  FROM daily_returns
  WHERE daily_return_pct IS NOT NULL
  GROUP BY Name
  HAVING COUNT(*) >= 100
)
(SELECT Name, ROUND(volatility_stddev, 2) as volatility, 
        ROUND(avg_abs_return, 2) as avg_daily_move, 
        'HIGH' as volatility_category
 FROM volatility
 ORDER BY volatility_stddev DESC
 LIMIT 20)
UNION ALL
(SELECT Name, ROUND(volatility_stddev, 2) as volatility, 
        ROUND(avg_abs_return, 2) as avg_daily_move,
        'LOW' as volatility_category
 FROM volatility
 ORDER BY volatility_stddev ASC
 LIMIT 20)
ORDER BY volatility DESC;

-- QUERY 4: What are the overall return trends across different sectors?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
first_last_prices AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close
  FROM stock_prices
),
stock_returns AS (
  SELECT DISTINCT
    Name,
    first_close,
    last_close,
    ((last_close - first_close) / NULLIF(first_close, 0)) * 100 as total_return_pct
  FROM first_last_prices
  WHERE first_close > 0 AND last_close > 0
),
sector_proxy AS (
  SELECT 
    SUBSTRING(Name, 1, 1) as sector_group,
    COUNT(*) as stock_count,
    AVG(total_return_pct) as avg_return,
    STDDEV(total_return_pct) as return_stddev,
    MIN(total_return_pct) as min_return,
    MAX(total_return_pct) as max_return
  FROM stock_returns
  GROUP BY SUBSTRING(Name, 1, 1)
)
SELECT 
  sector_group,
  stock_count,
  ROUND(avg_return, 2) as avg_return_pct,
  ROUND(return_stddev, 2) as return_volatility,
  ROUND(min_return, 2) as worst_stock,
  ROUND(max_return, 2) as best_stock
FROM sector_proxy
ORDER BY avg_return DESC;


-- QUERY 5: Which companies recorded highest/lowest stock prices during period?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`High ($)`, '$', ''), ',', '') AS DOUBLE) as high_price,
    CAST(REPLACE(REPLACE(`Low ($)`, '$', ''), ',', '') AS DOUBLE) as low_price
  FROM testdb.default.s_p_stock_data
),
price_extremes AS (
  SELECT 
    Name,
    MAX(high_price) as highest_price,
    MIN(low_price) as lowest_price,
    MAX(high_price) - MIN(low_price) as price_range
  FROM stock_prices
  WHERE high_price > 0 AND low_price > 0
  GROUP BY Name
)
(SELECT Name, ROUND(highest_price, 2) as extreme_price, 
        ROUND(price_range, 2) as total_range, 'HIGHEST' as category
 FROM price_extremes
 ORDER BY highest_price DESC
 LIMIT 20)
UNION ALL
(SELECT Name, ROUND(lowest_price, 2) as extreme_price,
        ROUND(price_range, 2) as total_range, 'LOWEST' as category
 FROM price_extremes
 ORDER BY lowest_price ASC
 LIMIT 20)
ORDER BY extreme_price DESC;

-- QUERY 6: During which periods did stocks experience major market declines?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
running_max AS (
  SELECT 
    Name,
    Date,
    close_price,
    MAX(close_price) OVER (PARTITION BY Name ORDER BY Date 
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as peak_price
  FROM stock_prices
  WHERE close_price > 0
),
drawdowns AS (
  SELECT 
    Name,
    Date,
    close_price,
    peak_price,
    ((close_price - peak_price) / NULLIF(peak_price, 0)) * 100 as drawdown_pct
  FROM running_max
  WHERE peak_price > 0
)
SELECT 
  Name,
  DATE_FORMAT(Date, 'yyyy-MM-dd') as date,
  ROUND(peak_price, 2) as peak_price,
  ROUND(close_price, 2) as current_price,
  ROUND(drawdown_pct, 2) as drawdown_pct
FROM drawdowns
WHERE drawdown_pct < -20
ORDER BY drawdown_pct ASC
LIMIT 100;

-- QUERY 7: Is there correlation between trading volume and price movement?

WITH daily_changes AS (
  SELECT 
    Name,
    Date,
    Volume,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
price_volume_data AS (
  SELECT 
    Name,
    ABS((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as abs_price_change_pct,
    Volume
  FROM daily_changes
  WHERE prev_close IS NOT NULL AND prev_close > 0 AND Volume > 0
),
correlation_calc AS (
  SELECT 
    Name,
    CORR(Volume, abs_price_change_pct) as correlation,
    AVG(Volume) as avg_volume,
    AVG(abs_price_change_pct) as avg_price_change,
    COUNT(*) as data_points
  FROM price_volume_data
  GROUP BY Name
  HAVING COUNT(*) >= 100
)
SELECT 
  Name,
  ROUND(correlation, 4) as volume_price_correlation,
  ROUND(avg_volume, 0) as avg_daily_volume,
  ROUND(avg_price_change, 2) as avg_price_change_pct,
  data_points,
  CASE 
    WHEN correlation > 0.7 THEN 'Strong Positive'
    WHEN correlation > 0.3 THEN 'Moderate Positive'
    WHEN correlation > -0.3 THEN 'Weak/No Correlation'
    WHEN correlation > -0.7 THEN 'Moderate Negative'
    ELSE 'Strong Negative'
  END as correlation_strength
FROM correlation_calc
WHERE correlation IS NOT NULL
ORDER BY ABS(correlation) DESC
LIMIT 50;

-- QUERY 8: Which stocks provide best balance between risk and return?

WITH daily_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return_pct
  FROM daily_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
risk_return AS (
  SELECT 
    Name,
    AVG(daily_return_pct) * 252 as annualized_return,
    STDDEV(daily_return_pct) * SQRT(252) as annualized_volatility,
    COUNT(*) as trading_days
  FROM daily_returns
  WHERE daily_return_pct IS NOT NULL
  GROUP BY Name
  HAVING COUNT(*) >= 100
),
sharpe_calc AS (
  SELECT 
    Name,
    annualized_return,
    annualized_volatility,
    (annualized_return) / NULLIF(annualized_volatility, 0) as risk_adjusted_return
  FROM risk_return
  WHERE annualized_volatility > 0
)
SELECT 
  Name,
  ROUND(annualized_return, 2) as annual_return_pct,
  ROUND(annualized_volatility, 2) as annual_volatility_pct,
  ROUND(risk_adjusted_return, 3) as sharpe_ratio
FROM sharpe_calc
WHERE risk_adjusted_return IS NOT NULL
ORDER BY risk_adjusted_return DESC
LIMIT 30;

-- QUERY 9: How do moving averages identify bullish/bearish trends?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
moving_averages AS (
  SELECT 
    Name,
    Date,
    close_price,
    AVG(close_price) OVER (PARTITION BY Name ORDER BY Date 
                          ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) as ma_50,
    AVG(close_price) OVER (PARTITION BY Name ORDER BY Date 
                          ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) as ma_200,
    ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date) as day_num
  FROM stock_prices
  WHERE close_price > 0
),
signals AS (
  SELECT 
    Name,
    Date,
    close_price,
    ma_50,
    ma_200,
    CASE 
      WHEN ma_50 > ma_200 THEN 'Bullish'
      WHEN ma_50 < ma_200 THEN 'Bearish'
      ELSE 'Neutral'
    END as trend_signal,
    LAG(CASE WHEN ma_50 > ma_200 THEN 1 ELSE 0 END) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_bullish
  FROM moving_averages
  WHERE day_num >= 200
),
crossovers AS (
  SELECT 
    Name,
    DATE_FORMAT(Date, 'yyyy-MM-dd') as date,
    ROUND(close_price, 2) as price,
    ROUND(ma_50, 2) as ma_50,
    ROUND(ma_200, 2) as ma_200,
    trend_signal,
    CASE 
      WHEN trend_signal = 'Bullish' AND prev_bullish = 0 THEN 'Golden Cross'
      WHEN trend_signal = 'Bearish' AND prev_bullish = 1 THEN 'Death Cross'
      ELSE NULL
    END as crossover_event
  FROM signals
)
SELECT 
  Name,
  date,
  price,
  ma_50,
  ma_200,
  trend_signal,
  crossover_event
FROM crossovers
WHERE Date >= '2017-01-01'
ORDER BY Name, Date DESC
LIMIT 100;

-- QUERY 10: Which companies demonstrate most stable long-term growth?

WITH daily_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return_pct
  FROM daily_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
first_last AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close
  FROM daily_prices
),
stability_metrics AS (
  SELECT DISTINCT
    r.Name,
    AVG(r.daily_return_pct) as avg_daily_return,
    STDDEV(r.daily_return_pct) as volatility,
    ((f.last_close - f.first_close) / NULLIF(f.first_close, 0)) * 100 as total_return,
    SUM(CASE WHEN r.daily_return_pct < 0 THEN 1 ELSE 0 END) as down_days,
    COUNT(*) as total_days
  FROM daily_returns r
  JOIN first_last f ON r.Name = f.Name
  GROUP BY r.Name, f.first_close, f.last_close
  HAVING COUNT(*) >= 1000
),
growth_quality AS (
  SELECT 
    Name,
    total_return,
    volatility,
    avg_daily_return,
    (CAST(total_days - down_days AS DOUBLE) / total_days) * 100 as pct_positive_days,
    total_return / NULLIF(volatility, 0) as stability_score
  FROM stability_metrics
  WHERE total_return > 0 AND volatility > 0
)
SELECT 
  Name,
  ROUND(total_return, 2) as total_return_pct,
  ROUND(volatility, 2) as volatility,
  ROUND(pct_positive_days, 2) as pct_up_days,
  ROUND(stability_score, 2) as stability_score
FROM growth_quality
ORDER BY stability_score DESC
LIMIT 30;

-- QUERY 11: How does portfolio diversification impact overall investment risk?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    Date,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return_pct
  FROM stock_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
stock_stats AS (
  SELECT 
    Name,
    AVG(daily_return_pct) as avg_return,
    STDDEV(daily_return_pct) as std_return
  FROM daily_returns
  GROUP BY Name
  HAVING COUNT(*) >= 1000
),
portfolio_returns AS (
  SELECT 
    Date,
    AVG(daily_return_pct) as equal_weight_portfolio_return
  FROM daily_returns
  WHERE Name IN (SELECT Name FROM stock_stats)
  GROUP BY Date
),
portfolio_stats AS (
  SELECT 
    AVG(equal_weight_portfolio_return) as portfolio_avg_return,
    STDDEV(equal_weight_portfolio_return) as portfolio_std
  FROM portfolio_returns
),
avg_stock_stats AS (
  SELECT 
    AVG(std_return) as avg_individual_std
  FROM stock_stats
)
SELECT 
  (SELECT COUNT(*) FROM stock_stats) as num_stocks,
  ROUND((SELECT portfolio_avg_return FROM portfolio_stats), 4) as portfolio_daily_return,
  ROUND((SELECT portfolio_std FROM portfolio_stats), 4) as portfolio_volatility,
  ROUND((SELECT avg_individual_std FROM avg_stock_stats), 4) as avg_stock_volatility,
  ROUND(((SELECT avg_individual_std FROM avg_stock_stats) - 
         (SELECT portfolio_std FROM portfolio_stats)) / 
         (SELECT avg_individual_std FROM avg_stock_stats) * 100, 2) as risk_reduction_pct;

-- QUERY 12: Which stocks consistently outperform the portfolio average?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    Date,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return_pct
  FROM stock_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
market_returns AS (
  SELECT 
    Date,
    AVG(daily_return_pct) as market_return
  FROM daily_returns
  GROUP BY Date
),
outperformance AS (
  SELECT 
    d.Name,
    d.Date,
    d.daily_return_pct,
    m.market_return,
    CASE WHEN d.daily_return_pct > m.market_return THEN 1 ELSE 0 END as beat_market
  FROM daily_returns d
  JOIN market_returns m ON d.Date = m.Date
),
consistency_metrics AS (
  SELECT 
    Name,
    COUNT(*) as total_days,
    SUM(beat_market) as days_beat_market,
    (SUM(beat_market) * 100.0 / COUNT(*)) as pct_days_beat_market,
    AVG(daily_return_pct - market_return) as avg_excess_return
  FROM outperformance
  GROUP BY Name
  HAVING COUNT(*) >= 1000
)
SELECT 
  Name,
  total_days,
  days_beat_market,
  ROUND(pct_days_beat_market, 2) as consistency_pct,
  ROUND(avg_excess_return, 4) as avg_daily_excess_return
FROM consistency_metrics
ORDER BY pct_days_beat_market DESC
LIMIT 30;

-- QUERY 13: What monthly/quarterly trends can be identified?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    YEAR(Date) as year,
    MONTH(Date) as month,
    QUARTER(Date) as quarter,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
monthly_returns AS (
  SELECT 
    Name,
    year,
    month,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name, year, month ORDER BY Date ASC) as month_start,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name, year, month ORDER BY Date DESC) as month_end
  FROM stock_prices
  WHERE close_price > 0
),
monthly_performance AS (
  SELECT DISTINCT
    Name,
    year,
    month,
    ((month_end - month_start) / NULLIF(month_start, 0)) * 100 as monthly_return
  FROM monthly_returns
  WHERE month_start > 0
),
monthly_stats AS (
  SELECT 
    month,
    COUNT(*) as observations,
    AVG(monthly_return) as avg_return,
    STDDEV(monthly_return) as return_volatility,
    SUM(CASE WHEN monthly_return > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as pct_positive
  FROM monthly_performance
  GROUP BY month
)
SELECT 
  CASE month
    WHEN 1 THEN 'January'
    WHEN 2 THEN 'February'
    WHEN 3 THEN 'March'
    WHEN 4 THEN 'April'
    WHEN 5 THEN 'May'
    WHEN 6 THEN 'June'
    WHEN 7 THEN 'July'
    WHEN 8 THEN 'August'
    WHEN 9 THEN 'September'
    WHEN 10 THEN 'October'
    WHEN 11 THEN 'November'
    WHEN 12 THEN 'December'
  END as month_name,
  observations,
  ROUND(avg_return, 2) as avg_monthly_return_pct,
  ROUND(return_volatility, 2) as volatility,
  ROUND(pct_positive, 2) as pct_positive_months
FROM monthly_stats
ORDER BY month;

-- QUERY 14: Which sectors contribute most to portfolio profitability?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
first_last AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close
  FROM stock_prices
),
returns AS (
  SELECT DISTINCT
    Name,
    SUBSTRING(Name, 1, 1) as sector_proxy,
    ((last_close - first_close) / NULLIF(first_close, 0)) * 100 as total_return
  FROM first_last
  WHERE first_close > 0 AND last_close > 0
),
sector_contribution AS (
  SELECT 
    sector_proxy,
    COUNT(*) as stock_count,
    AVG(total_return) as avg_return,
    SUM(total_return) as total_contribution,
    STDDEV(total_return) as return_spread
  FROM returns
  GROUP BY sector_proxy
)
SELECT 
  sector_proxy as sector_group,
  stock_count,
  ROUND(avg_return, 2) as avg_return_pct,
  ROUND(total_contribution, 2) as total_contribution,
  ROUND(return_spread, 2) as return_volatility
FROM sector_contribution
ORDER BY total_contribution DESC;

-- QUERY 15: Which stocks show most consistent trading activity over time?

WITH volume_data AS (
  SELECT 
    Name,
    Date,
    Volume,
    AVG(Volume) OVER (PARTITION BY Name) as avg_volume,
    STDDEV(Volume) OVER (PARTITION BY Name) as stddev_volume
  FROM testdb.default.s_p_stock_data
  WHERE Volume > 0
),
volume_stats AS (
  SELECT DISTINCT
    Name,
    avg_volume,
    stddev_volume,
    (stddev_volume / NULLIF(avg_volume, 0)) as coefficient_of_variation
  FROM volume_data
),
volume_trends AS (
  SELECT 
    Name,
    Date,
    Volume,
    AVG(Volume) OVER (PARTITION BY Name ORDER BY Date 
                     ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as ma_30,
    ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Date DESC) as recency
  FROM testdb.default.s_p_stock_data
  WHERE Volume > 0
),
recent_vs_historical AS (
  SELECT 
    Name,
    AVG(CASE WHEN recency <= 90 THEN Volume END) as recent_avg_volume,
    AVG(CASE WHEN recency > 90 THEN Volume END) as historical_avg_volume
  FROM volume_trends
  GROUP BY Name
)
SELECT 
  vs.Name,
  ROUND(vs.avg_volume, 0) as avg_daily_volume,
  ROUND(vs.stddev_volume, 0) as volume_std_dev,
  ROUND(vs.coefficient_of_variation, 3) as volume_consistency_ratio,
  ROUND(rh.recent_avg_volume, 0) as recent_90day_avg,
  ROUND(((rh.recent_avg_volume - rh.historical_avg_volume) / 
         NULLIF(rh.historical_avg_volume, 0)) * 100, 2) as volume_trend_pct
FROM volume_stats vs
JOIN recent_vs_historical rh ON vs.Name = rh.Name
WHERE vs.coefficient_of_variation IS NOT NULL
ORDER BY vs.coefficient_of_variation ASC
LIMIT 30;

-- QUERY 16: How does portfolio perform relative to S&P 500 benchmark?

WITH stock_prices AS (
  SELECT 
    Date,
    Name,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
),
daily_prices AS (
  SELECT 
    Date,
    AVG(close_price) as avg_market_price
  FROM stock_prices
  WHERE close_price > 0
  GROUP BY Date
),
market_returns AS (
  SELECT 
    Date,
    avg_market_price,
    LAG(avg_market_price) OVER (ORDER BY Date) as prev_price,
    ((avg_market_price - LAG(avg_market_price) OVER (ORDER BY Date)) / 
     NULLIF(LAG(avg_market_price) OVER (ORDER BY Date), 0)) * 100 as daily_return
  FROM daily_prices
),
cumulative_performance AS (
  SELECT 
    Date,
    daily_return,
    SUM(daily_return) OVER (ORDER BY Date) as cumulative_return,
    AVG(daily_return) OVER (ORDER BY Date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as ma_30_return
  FROM market_returns
  WHERE daily_return IS NOT NULL
)
SELECT 
  DATE_FORMAT(Date, 'yyyy-MM-dd') as date,
  ROUND(daily_return, 3) as daily_return_pct,
  ROUND(cumulative_return, 2) as cumulative_return_pct,
  ROUND(ma_30_return, 3) as avg_30day_return
FROM cumulative_performance
ORDER BY Date DESC
LIMIT 100;

-- QUERY 17: Which companies experience largest short-term price fluctuations?

WITH intraday_ranges AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`High ($)`, '$', ''), ',', '') AS DOUBLE) as high_price,
    CAST(REPLACE(REPLACE(`Low ($)`, '$', ''), ',', '') AS DOUBLE) as low_price,
    CAST(REPLACE(REPLACE(`Open ($)`, '$', ''), ',', '') AS DOUBLE) as open_price,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price
  FROM testdb.default.s_p_stock_data
  WHERE CAST(REPLACE(REPLACE(`High ($)`, '$', ''), ',', '') AS DOUBLE) > 0
    AND CAST(REPLACE(REPLACE(`Low ($)`, '$', ''), ',', '') AS DOUBLE) > 0
),
daily_volatility AS (
  SELECT 
    Name,
    Date,
    high_price,
    low_price,
    open_price,
    close_price,
    ((high_price - low_price) / NULLIF(low_price, 0)) * 100 as intraday_range_pct,
    ABS((close_price - open_price) / NULLIF(open_price, 0)) * 100 as open_close_move_pct
  FROM intraday_ranges
),
volatility_stats AS (
  SELECT 
    Name,
    AVG(intraday_range_pct) as avg_intraday_range,
    MAX(intraday_range_pct) as max_intraday_range,
    AVG(open_close_move_pct) as avg_open_close_move,
    STDDEV(intraday_range_pct) as range_volatility,
    COUNT(*) as trading_days
  FROM daily_volatility
  WHERE intraday_range_pct IS NOT NULL
  GROUP BY Name
  HAVING COUNT(*) >= 1000
)
SELECT 
  Name,
  ROUND(avg_intraday_range, 2) as avg_daily_range_pct,
  ROUND(max_intraday_range, 2) as max_daily_range_pct,
  ROUND(avg_open_close_move, 2) as avg_open_close_pct,
  ROUND(range_volatility, 2) as volatility_of_ranges,
  trading_days
FROM volatility_stats
ORDER BY avg_intraday_range DESC
LIMIT 30;

-- QUERY 18: How do sector-level stock trends differ across the market?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    SUBSTRING(Name, 1, 1) as sector_proxy,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    sector_proxy,
    Date,
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return
  FROM stock_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
sector_daily_avg AS (
  SELECT 
    sector_proxy,
    Date,
    AVG(daily_return) as sector_avg_return
  FROM daily_returns
  GROUP BY sector_proxy, Date
),
sector_performance AS (
  SELECT 
    sector_proxy,
    AVG(sector_avg_return) as avg_daily_return,
    STDDEV(sector_avg_return) as volatility,
    MIN(sector_avg_return) as worst_day,
    MAX(sector_avg_return) as best_day,
    COUNT(DISTINCT Date) as trading_days
  FROM sector_daily_avg
  GROUP BY sector_proxy
)
SELECT 
  sector_proxy as sector_group,
  trading_days,
  ROUND(avg_daily_return * 252, 2) as annualized_return_pct,
  ROUND(volatility * SQRT(252), 2) as annualized_volatility,
  ROUND(worst_day, 2) as worst_single_day_pct,
  ROUND(best_day, 2) as best_single_day_pct,
  ROUND((avg_daily_return * 252) / NULLIF(volatility * SQRT(252), 0), 2) as risk_adjusted_return
FROM sector_performance
ORDER BY annualized_return_pct DESC;

-- QUERY 19: What indicators highlight periods of increased market risk?

WITH stock_prices AS (
  SELECT 
    Date,
    Name,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Date,
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return
  FROM stock_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
market_metrics AS (
  SELECT 
    Date,
    AVG(daily_return) as market_return,
    STDDEV(daily_return) as cross_sectional_volatility,
    COUNT(CASE WHEN daily_return < -3 THEN 1 END) as num_large_declines,
    COUNT(DISTINCT Name) as num_stocks
  FROM daily_returns
  GROUP BY Date
),
risk_indicators AS (
  SELECT 
    Date,
    market_return,
    cross_sectional_volatility,
    num_large_declines,
    num_stocks,
    (num_large_declines * 100.0 / num_stocks) as pct_stocks_declining,
    AVG(cross_sectional_volatility) OVER (ORDER BY Date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as ma_20_volatility,
    STDDEV(market_return) OVER (ORDER BY Date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as rolling_20day_vol
  FROM market_metrics
),
risk_events AS (
  SELECT 
    Date,
    market_return,
    cross_sectional_volatility,
    pct_stocks_declining,
    rolling_20day_vol,
    CASE 
      WHEN cross_sectional_volatility > ma_20_volatility * 1.5 THEN 'HIGH VOLATILITY'
      WHEN market_return < -2 AND pct_stocks_declining > 50 THEN 'BROAD DECLINE'
      WHEN rolling_20day_vol > 2 THEN 'ELEVATED RISK'
      ELSE 'NORMAL'
    END as risk_level
  FROM risk_indicators
  WHERE ma_20_volatility IS NOT NULL
)
SELECT 
  DATE_FORMAT(Date, 'yyyy-MM-dd') as date,
  ROUND(market_return, 2) as market_return_pct,
  ROUND(cross_sectional_volatility, 2) as dispersion,
  ROUND(pct_stocks_declining, 1) as pct_declining,
  ROUND(rolling_20day_vol, 2) as rolling_volatility,
  risk_level
FROM risk_events
WHERE risk_level != 'NORMAL'
ORDER BY Date DESC
LIMIT 100;

-- QUERY 20: Which stocks suit conservative vs aggressive investment strategies?

WITH stock_prices AS (
  SELECT 
    Name,
    Date,
    CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE) as close_price,
    LAG(CAST(REPLACE(REPLACE(`Close ($)`, '$', ''), ',', '') AS DOUBLE)) 
      OVER (PARTITION BY Name ORDER BY Date) as prev_close
  FROM testdb.default.s_p_stock_data
),
daily_returns AS (
  SELECT 
    Name,
    ((close_price - prev_close) / NULLIF(prev_close, 0)) * 100 as daily_return
  FROM stock_prices
  WHERE prev_close IS NOT NULL AND prev_close > 0
),
first_last AS (
  SELECT 
    Name,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date ASC) as first_close,
    FIRST_VALUE(close_price) OVER (PARTITION BY Name ORDER BY Date DESC) as last_close
  FROM stock_prices
),
risk_metrics AS (
  SELECT 
    r.Name,
    AVG(r.daily_return) * 252 as annualized_return,
    STDDEV(r.daily_return) * SQRT(252) as annualized_volatility,
    ((f.last_close - f.first_close) / NULLIF(f.first_close, 0)) * 100 as total_return,
    MIN(r.daily_return) as worst_day,
    COUNT(*) as trading_days
  FROM daily_returns r
  JOIN first_last f ON r.Name = f.Name
  GROUP BY r.Name, f.first_close, f.last_close
  HAVING COUNT(*) >= 1000
),
classification AS (
  SELECT 
    Name,
    annualized_return,
    annualized_volatility,
    total_return,
    worst_day,
    (annualized_return / NULLIF(annualized_volatility, 0)) as sharpe_ratio,
    CASE 
      WHEN annualized_volatility < 15 AND annualized_return > 5 THEN 'CONSERVATIVE'
      WHEN annualized_volatility < 20 AND annualized_return > 10 THEN 'MODERATE'
      WHEN annualized_volatility >= 20 AND annualized_return > 15 THEN 'AGGRESSIVE'
      WHEN annualized_volatility >= 30 THEN 'SPECULATIVE'
      ELSE 'NEUTRAL'
    END as investment_profile
  FROM risk_metrics
)
SELECT 
  Name,
  ROUND(annualized_return, 2) as annual_return_pct,
  ROUND(annualized_volatility, 2) as annual_volatility_pct,
  ROUND(total_return, 2) as total_period_return,
  ROUND(worst_day, 2) as worst_single_day,
  ROUND(sharpe_ratio, 3) as risk_adjusted_return,
  investment_profile
FROM classification
WHERE investment_profile IN ('CONSERVATIVE', 'AGGRESSIVE')
ORDER BY 
  CASE investment_profile 
    WHEN 'CONSERVATIVE' THEN 1 
    WHEN 'AGGRESSIVE' THEN 2 
  END,
  sharpe_ratio DESC;


