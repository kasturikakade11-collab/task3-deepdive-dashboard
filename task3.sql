USE Task1_Sales;

-- KPI 1: TOTAL REVENUE
SELECT 
    ROUND(SUM(Total_Sales), 2) AS total_revenue
FROM cleaned_sales_dataset;

-- KPI 2: AVERAGE ORDER VALUE
SELECT 
    ROUND(AVG(Total_Sales), 2) AS avg_order_value
FROM cleaned_sales_dataset;

-- KPI 3: REVENUE CONCENTRATION RATE
SELECT
    ROUND(
        SUM(CASE WHEN Sales_Category = 'High' 
            THEN Total_Sales ELSE 0 END) /
        SUM(Total_Sales) * 100, 2
    ) AS high_tier_revenue_pct
FROM cleaned_sales_dataset;

-- KPI 4: ELECTRONICS REVENUE SHARE
SELECT
    ROUND(
        SUM(CASE WHEN Category = 'Electronics' 
            THEN Total_Sales ELSE 0 END) /
        SUM(Total_Sales) * 100, 2
    ) AS electronics_revenue_pct
FROM cleaned_sales_dataset;

-- KPI 5: CITY PREMIUM INDEX
SELECT 
    City,
    ROUND(AVG(Total_Sales), 2) AS city_avg,
    ROUND(AVG(Total_Sales) / 
        (SELECT AVG(Total_Sales) 
         FROM cleaned_sales_dataset) * 100, 2
    ) AS premium_index
FROM cleaned_sales_dataset
GROUP BY City
ORDER BY premium_index DESC;

-- SEGMENTATION QUERY 1: 
-- RFM BASE TABLE (per customer)
SELECT
    Customer_ID,
    Customer_Name,
    DATEDIFF('2026-01-01', MAX(Order_Date)) 
        AS recency_days,
    COUNT(*) AS frequency,
    ROUND(SUM(Total_Sales), 2) AS monetary_value
FROM cleaned_sales_dataset
GROUP BY Customer_ID, Customer_Name
ORDER BY monetary_value DESC;

-- SEGMENTATION QUERY 2:
-- ASSIGN SEGMENT TO EACH CUSTOMER
SELECT
    Customer_ID,
    Customer_Name,
    recency_days,
    frequency,
    monetary_value,
    CASE
        WHEN recency_days <= 90
         AND frequency >= 2
         AND monetary_value >= 200000
        THEN 'Champion'

        WHEN recency_days <= 180
         AND monetary_value >= 150000
        THEN 'Loyal Customer'

        WHEN recency_days <= 90
         AND monetary_value < 100000
        THEN 'Recent Low Spender'

        WHEN recency_days > 180
         AND monetary_value >= 150000
        THEN 'At-Risk High Value'

        ELSE 'Regular Customer'
    END AS customer_segment
FROM (
    SELECT
        Customer_ID,
        Customer_Name,
        DATEDIFF('2026-01-01', MAX(Order_Date)) 
            AS recency_days,
        COUNT(*) AS frequency,
        ROUND(SUM(Total_Sales), 2) AS monetary_value
    FROM cleaned_sales_dataset
    GROUP BY Customer_ID, Customer_Name
) AS rfm_base
ORDER BY monetary_value DESC;

-- SEGMENTATION QUERY 3:
-- SEGMENT SUMMARY (for dashboard chart)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary_value), 2) AS avg_spend,
    ROUND(SUM(monetary_value), 2) AS segment_revenue
FROM (
    SELECT
        Customer_ID,
        DATEDIFF('2026-01-01', MAX(Order_Date)) 
            AS recency_days,
        COUNT(*) AS frequency,
        ROUND(SUM(Total_Sales), 2) AS monetary_value,
        CASE
            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 90
             AND COUNT(*) >= 2
             AND SUM(Total_Sales) >= 200000
            THEN 'Champion'

            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 180
             AND SUM(Total_Sales) >= 150000
            THEN 'Loyal Customer'

            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 90
             AND SUM(Total_Sales) < 100000
            THEN 'Recent Low Spender'

            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) > 180
             AND SUM(Total_Sales) >= 150000
            THEN 'At-Risk High Value'

            ELSE 'Regular Customer'
        END AS customer_segment
    FROM cleaned_sales_dataset
    GROUP BY Customer_ID
) AS rfm
GROUP BY customer_segment
ORDER BY segment_revenue DESC;


-- SEGMENTATION QUERY 4:
-- WHICH CATEGORY DOES EACH SEGMENT BUY?
SELECT
    rfm.customer_segment,
    cs.Category,
    COUNT(*) AS orders,
    ROUND(SUM(cs.Total_Sales), 2) AS revenue
FROM cleaned_sales_dataset cs
JOIN (
    SELECT
        Customer_ID,
        CASE
            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 90
             AND COUNT(*) >= 2
             AND SUM(Total_Sales) >= 200000
            THEN 'Champion'
            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 180
             AND SUM(Total_Sales) >= 150000
            THEN 'Loyal Customer'
            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) <= 90
             AND SUM(Total_Sales) < 100000
            THEN 'Recent Low Spender'
            WHEN DATEDIFF('2026-01-01', MAX(Order_Date)) > 180
             AND SUM(Total_Sales) >= 150000
            THEN 'At-Risk High Value'
            ELSE 'Regular Customer'
        END AS customer_segment
    FROM cleaned_sales_dataset
    GROUP BY Customer_ID
) AS rfm ON cs.Customer_ID = rfm.Customer_ID
GROUP BY rfm.customer_segment, cs.Category
ORDER BY rfm.customer_segment, revenue DESC;