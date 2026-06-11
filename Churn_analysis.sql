
-- Q1. WHAT IS THE OVERALL CHURN RATE?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SELECT
    COUNT(*)                                       AS total_customers,
    SUM(churn)                                     AS churned,
    COUNT(*) - SUM(churn)                          AS retained,
    ROUND(100.0 * SUM(churn) / COUNT(*), 2)        AS churn_rate_pct
FROM customers;

/*
Expected result:
 total_customers | churned | retained | churn_rate_pct
      2666       |   388   |   2278   |    14.55 %
*/


-- Q2. WHICH CUSTOMER SEGMENTS CHURN THE MOST?
--     Segments examined: State, Area Code, Voice Mail Plan, Spend Tier
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 2a. By STATE — top 10 highest churn states
SELECT
    state,
    COUNT(*)                                        AS customers,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY state
HAVING COUNT(*) >= 20            -- exclude states with very small samples
ORDER BY churn_rate_pct DESC
LIMIT 10;

-- 2b. By AREA CODE
SELECT
    area_code,
    COUNT(*)                                        AS customers,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY area_code
ORDER BY churn_rate_pct DESC;

-- 2c. By VOICE MAIL PLAN (no vmail → higher churn?)
SELECT
    CASE WHEN voice_mail_plan = 1 THEN 'Has VM Plan' ELSE 'No VM Plan' END AS segment,
    COUNT(*)                                        AS customer,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY voice_mail_plan
ORDER BY churn_rate_pct DESC;

-- 2d. By SPEND TIER (derived: Low / Medium / High / Premium)
SELECT
    spend_tier,
    COUNT(*)                                        AS customer,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY spend_tier
ORDER BY
    CASE spend_tier
        WHEN 'Low'     THEN 1
        WHEN 'Medium'  THEN 2
        WHEN 'High'    THEN 3
        WHEN 'Premium' THEN 4
    END;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q3. DOES THE INTERNATIONAL PLAN INCREASE CHURN?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 3a. Simple plan vs. no-plan comparison
SELECT
    CASE WHEN international_plan = 1 THEN 'Has Intl Plan' ELSE 'No Intl Plan' END AS segment,
    COUNT(*)                                        AS customer,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY international_plan
ORDER BY churn_rate_pct DESC;

-- 3b. Cross: Intl Plan × Voice Mail Plan (2×2 interaction)
SELECT
    CASE WHEN international_plan = 1 THEN 'Intl=Yes' ELSE 'Intl=No' END   AS intl_plan,
    CASE WHEN voice_mail_plan    = 1 THEN 'VM=Yes'  ELSE 'VM=No'  END   AS vm_plan,
    COUNT(*)                                                               AS customers,
    SUM(churn)                                                             AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)                               AS churn_rate_pct
FROM customers
GROUP BY international_plan, voice_mail_plan
ORDER BY churn_rate_pct DESC;


-- Q4. HOW DO CUSTOMER SERVICE CALLS IMPACT CHURN?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 4a. Churn rate at every call-count level
SELECT
    customer_service_calls,
    COUNT(*)                                        AS customers,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct
FROM customers
GROUP BY customer_service_calls
ORDER BY customer_service_calls;

-- 4b. Bucketed view: 0-1 / 2-3 / 4+ (the "≥4 cliff" is decisive)
SELECT
    CASE
        WHEN customer_service_calls BETWEEN 0 AND 1 THEN '0–1 calls (low)'
        WHEN customer_service_calls BETWEEN 2 AND 3 THEN '2–3 calls (medium)'
        ELSE                                              '4+ calls (high risk)'
    END                                              AS cs_bucket,
    COUNT(*)                                         AS customer,
    SUM(churn)                                       AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)          AS churn_rate_pct
FROM customers
GROUP BY cs_bucket
ORDER BY churn_rate_pct ASC;

-- 4c. Avg service calls per churn outcome
SELECT
    CASE WHEN churn = 1 THEN 'Churned' ELSE 'Retained' END  AS status,
    ROUND(AVG(customer_service_calls), 2)                   AS avg_cs_calls,
    ROUND(MIN(customer_service_calls), 0)                   AS min_cs_calls,
    ROUND(MAX(customer_service_calls), 0)                   AS max_cs_calls
FROM customers
GROUP BY churn;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q5. ARE HIGH-VALUE CUSTOMERS MORE LIKELY TO CHURN?
--     "High-value" = top quartile of total_charge (spend_tier = 'Premium')
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 5a. Mean spend — churned vs. retained
SELECT
    CASE WHEN churn = 1 THEN 'Churned' ELSE 'Retained' END  AS status,
    ROUND(AVG(total_charge), 2)                             AS avg_total_charge,
    ROUND(AVG(total_day_charge), 2)                         AS avg_day_charge,
    ROUND(AVG(total_intl_charge), 2)                        AS avg_intl_charge,
    COUNT(*)                                                AS customers
FROM customers
GROUP BY churn;

-- 5b. Churn rate across spend quartiles
SELECT
    spend_tier,
    COUNT(*)                                        AS customers,
    SUM(churn)                                      AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)         AS churn_rate_pct,
    ROUND(AVG(total_charge), 2)                     AS avg_total_charge
FROM customers
GROUP BY spend_tier
ORDER BY
    CASE spend_tier
        WHEN 'Low'     THEN 1
        WHEN 'Medium'  THEN 2
        WHEN 'High'    THEN 3
        WHEN 'Premium' THEN 4
    END;
    

-- 5c. Revenue at risk: how much charge are churned "Premium" customers generating?
SELECT
    spend_tier,
    SUM(CASE WHEN churn = 1 THEN total_charge ELSE 0 END)   AS revenue_at_risk,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 1 THEN total_charge ELSE 0 END)
        / SUM(total_charge), 1
    )                                                        AS pct_of_tier_revenue
FROM customers
GROUP BY spend_tier
ORDER BY revenue_at_risk DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Q6. WHAT CUSTOMER PROFILE IS MOST LIKELY TO CHURN?
--     Composite risk score combining the strongest individual predictors
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 6a. Individual predictor strength — churn rate by flag combination
SELECT
    international_plan,
    voice_mail_plan,
    high_cs_calls,
    spend_tier,
    COUNT(*)                                         AS customers,
    SUM(churn)                                       AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)          AS churn_rate_pct
FROM customers
GROUP BY international_plan, voice_mail_plan, high_cs_calls, spend_tier
HAVING COUNT(*) >= 5
ORDER BY churn_rate_pct DESC
LIMIT 15;

-- 6b. HIGHEST-RISK PROFILE:
--     International plan ON  +  4+ CS calls  +  No voice-mail plan
--     → the "angry frequent caller on a premium plan" segment
SELECT
    CASE
        WHEN international_plan = 1
             AND high_cs_calls = 1
             AND voice_mail_plan = 0
        THEN 'High-Risk Profile'
        ELSE 'All Other Customers'
    END                                               AS profile,
    COUNT(*)                                          AS customers,
    SUM(churn)                                        AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)           AS churn_rate_pct,
    ROUND(AVG(total_charge), 2)                       AS avg_spend
FROM customers
GROUP BY profile
ORDER BY churn_rate_pct DESC;

-- 6c. Scored risk model — each customer gets a 0–4 composite risk score
--     Each flag contributes +1:
--       • Has International Plan    (+1)
--       • ≥4 Customer Service Calls (+1)
--       • No Voice Mail Plan        (+1)
--       • Spend Tier = Premium      (+1)
SELECT
    risk_score,
    COUNT(*)                                          AS customers,
    SUM(churn)                                        AS churned,
    ROUND(100.0 * SUM(churn) / COUNT(*), 1)           AS churn_rate_pct,
    ROUND(AVG(total_charge), 2)                       AS avg_spend
FROM (
    SELECT
        churn,
        total_charge,
        (international_plan                           -- 1 if has plan
         + high_cs_calls                             -- 1 if ≥4 CS calls
         + (1 - voice_mail_plan)                     -- 1 if no VM plan
         + CASE WHEN spend_tier = 'Premium' THEN 1 ELSE 0 END
        )                                             AS risk_score
    FROM customers
) scored
GROUP BY risk_score
ORDER BY risk_score;


-- END OF ANALYSIS
