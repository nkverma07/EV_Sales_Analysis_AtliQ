USE evl;

SELECT * FROM dim_date;

SELECT * FROM electric_vehicle_sales_by_makers;

SELECT * FROM electric_vehicle_sales_by_state;

ALTER TABLE electric_vehicle_sales_by_state
RENAME COLUMN ï»¿date TO SNdate;

-- List the top 3 and bottom 3 makers for the fiscal years 
-- 2023 and 2024 in terms of the number of 2-wheelers sold.

with EVRanking as
(
SELECT em.maker, dd.fiscal_year, sum(em.electric_vehicles_sold) as EVsold,
	   DENSE_RANK()OVER(PARTITION BY dd.fiscal_year ORDER BY sum(em.electric_vehicles_sold) DESC) AS ranking
FROM electric_vehicle_sales_by_makers em
JOIN dim_date dd ON em.SNdate=dd.SNdate
WHERE dd.fiscal_year IN("2023","2024") AND em.vehicle_category = '2-Wheelers'
GROUP BY em.maker, dd.fiscal_year
ORDER BY fiscal_year)
SELECT
      maker,fiscal_year,EVsold,ranking
FROM
     EVRanking
WHERE ranking>=3;

-- Identify the top 5 states with the highest penetration 
-- rate in 2-wheeler and 4-wheeler EV sales in FY 2024.

SELECT es.state,
	   (SUM(es.electric_vehicles_sold)/sum(es.total_vehicles_sold))*100 AS PenetrationRate
FROM electric_vehicle_sales_by_state AS es
JOIN dim_date dd ON es.SNdate=dd.SNdate
WHERE fiscal_year = 2024 AND es.vehicle_category = '2-Wheelers'
GROUP BY es.state
ORDER BY PenetrationRate DESC;

SELECT es.state,
	   (SUM(es.electric_vehicles_sold)/sum(es.total_vehicles_sold))*100 AS PenetrationRate
FROM electric_vehicle_sales_by_state AS es
JOIN dim_date dd ON es.SNdate=dd.SNdate
WHERE fiscal_year = 2024 AND es.vehicle_category = '4-Wheelers'
GROUP BY es.state
ORDER BY PenetrationRate DESC;


--  List the states with negative penetration (decline) in EV sales from 2022 to 2024?
WITH EV_Sales AS
(
SELECT 
        es.state,
        dd.fiscal_year,
        SUM(es.electric_vehicles_sold) AS TotalEVSold
FROM 
        electric_vehicle_sales_by_state es
JOIN 
        dim_date dd ON es.SNdate = dd.SNdate
WHERE 
        dd.fiscal_year IN (2022,2024)
GROUP BY 
        es.state,
        dd.fiscal_year
ORDER BY TotalEVSold DESC
),
EV_Sales_Yearly AS 
(
SELECT 
     EVSales22.state,
     EVSales22.TotalEVSold AS TotalEVSold2022,
     EVSales24.TotalEVSold AS TotalEVSold2024,
     (EVSales24.TotalEVSold - EVSales22.TotalEVSold) AS SalesDifference
FROM
	(
     SELECT state, TotalEVSold
	 FROM EV_sales
	 WHERE fiscal_year = 2022) EVSales22
LEFT JOIN
    (
     SELECT state, TotalEVSold
	 FROM EV_sales
	 WHERE fiscal_year = 2024) EVSales24
ON
    EVSales22.state = EVSales24.state
)
SELECT
      state,
      TotalEVSold2022,
      TotalEVSold2024,
      SalesDifference
FROM
      EV_Sales_Yearly
ORDER BY 
      SalesDifference ASC;
      
  
--  List the states with negative penetration (decline) in EV sales from 2022 to 2024?
SELECT state,total_ev_sold2022,total_ev_sold2024,(total_ev_sold2024 - total_ev_sold2022) as SalesDiff
FROM
	(SELECT state,
		   sum(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 End) as total_ev_sold2022,
		   sum(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 End) as total_ev_sold2024
	FROM electric_vehicle_sales_by_state as es
	JOIN dim_date dd on es.SNdate=dd.SNdate
	WHERE dd.fiscal_year IN (2022,2024)
	GROUP BY es.state
	ORDER BY es.state) as SalesRate22_24
ORDER BY 
        SalesDiff;





-- What are the quarterly trends based on sales volume for 
-- the top 5 EV makers (4-wheelers) from 2022 to 2024?
with MakerT4W as
(
SELECT maker,sum(electric_vehicles_sold) as EvSold
FROM electric_vehicle_sales_by_makers as em
JOIN dim_date dd on em.SNdate = dd.SNdate
WHERE vehicle_category = '4-Wheelers'
GROUP BY maker
ORDER BY EvSold DESC
LIMIT 5)
SELECT
      maker,
      quarter,
      sum(electric_vehicles_sold) as EvSold
FROM electric_vehicle_sales_by_makers as em
JOIN dim_date dd on em.SNdate = dd.SNdate
WHERE maker in (SELECT maker FROM MakerT4W)
GROUP BY maker,quarter
ORDER BY maker desc,quarter desc,sum(electric_vehicles_sold) desc;

-- How do the EV sales and penetration rates in 
-- Delhi compare to Karnataka for 2024?
SELECT es.state, dd.fiscal_year,
                round((sum(es.electric_vehicles_sold)/sum(es.total_vehicles_sold)) *100,2) as penetration_rate
FROM electric_vehicle_sales_by_state as es
JOIN dim_date dd on es.SNdate=dd.SNdate
WHERE dd.fiscal_year = 2024 and es.state IN('delhi','karnataka')
GROUP BY es.state
ORDER BY es.state;


-- List down the compounded annual growth rate (CAGR) in 
-- 4-wheeler units for the top 5 makers from 2022 to 2024

WITH TOP5MAKERS AS(
SELECT 
        maker
FROM 
        electric_vehicle_sales_by_makers em
JOIN 
        dim_date dd ON em.SNdate = dd.SNdate
WHERE 
		vehicle_category = '4-Wheelers'
GROUP BY 
        maker
ORDER BY sum(electric_vehicles_sold) desc
LIMIT 5)
SELECT
     maker,
     (ROUND(POWER((SUM(CASE WHEN fiscal_year = 2024 THEN electric_vehicles_sold ELSE 0 END) /
		SUM(CASE WHEN fiscal_year = 2022 THEN electric_vehicles_sold ELSE 0 END)), 1 / 2) - 1, 5))*100 AS CAGR
FROM 
        electric_vehicle_sales_by_makers em
JOIN 
        dim_date dd ON em.SNdate = dd.SNdate
WHERE vehicle_category = '4-Wheelers' AND maker IN(SELECT maker FROM TOP5MAKERS)
GROUP BY maker
ORDER BY CAGR desc;



-- List down the top 10 states that had the highest compounded annual 
-- growth rate (CAGR) from 2022 to 2024 in total vehicles sold

WITH TOP10STATES AS(
SELECT 
        state
FROM 
        electric_vehicle_sales_by_state
GROUP BY 
        state
ORDER BY sum(total_vehicles_sold) desc
LIMIT 10)
SELECT
     state,
     (ROUND(POWER((SUM(CASE WHEN fiscal_year = 2024 THEN total_vehicles_sold ELSE 0 END) /
		SUM(CASE WHEN fiscal_year = 2022 THEN total_vehicles_sold ELSE 0 END)), 1 / 2) - 1, 2))*1000 AS CAGR
FROM 
        electric_vehicle_sales_by_state es
JOIN 
        dim_date dd ON es.SNdate = dd.SNdate
WHERE state IN(SELECT state FROM TOP10STATES)
GROUP BY state
ORDER BY CAGR desc;


-- What are the peak and low season months for 
-- EV sales based on the data from 2022 to 2024?

SELECT 
    DATE_FORMAT(STR_TO_DATE(dd.SNdate, '%d-%b-%y'), '%M') as SalesMonth,
    sum(es.electric_vehicles_sold) as MaxEVsold
FROM 
    electric_vehicle_sales_by_state es
JOIN 
    dim_date dd ON es.SNdate = dd.SNdate
GROUP BY 
    SalesMonth
ORDER BY 
    SalesMonth;
    
    
-- Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India 
-- for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price

SELECT fiscal_year,
    CASE WHEN vehicle_category = '2-Wheelers' THEN sum(electric_vehicles_sold)*85000 END as revenue_of_2_wheelers,
    CASE WHEN vehicle_category = '4-Wheelers' THEN sum(electric_vehicles_sold)*1500000 END as revenue_of_4_wheelers
FROM electric_vehicle_sales_by_state es
JOIN dim_date dd on es.SNdate=dd.SNdate
WHERE fiscal_year in (2022,2023,2024)
GROUP BY vehicle_category,fiscal_year
ORDER BY revenue_of_2_wheelers DESC,revenue_of_4_wheelers DESC;

-- Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India 
-- for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price
SELECT vehicle_category,
      ((revenue2024 - revenue2022) / revenue2022) * 100 as revenue2022_2024,
      ((revenue2024 - revenue2023) / revenue2023) * 100 as revenue2023_2024
FROM (
    SELECT vehicle_category,
           SUM(CASE WHEN fiscal_year = 2024 THEN total_revenue END) as revenue2024,
           SUM(CASE WHEN fiscal_year = 2023 THEN total_revenue END) as revenue2023,
           SUM(CASE WHEN fiscal_year = 2022 THEN total_revenue END) as revenue2022
    FROM (
        SELECT 
        vehicle_category,
        fiscal_year,
        SUM(electric_vehicles_sold) * CASE 
            WHEN vehicle_category = '2-Wheelers' THEN 85000 
            WHEN vehicle_category = '4-Wheelers' THEN 1500000 
        END AS total_revenue
    FROM electric_vehicle_sales_by_state es
    JOIN dim_date dd ON es.SNdate = dd.SNdate
    WHERE fiscal_year IN (2022, 2023, 2024)
    GROUP BY vehicle_category, fiscal_year
    ) trv
    GROUP by vehicle_category
) trvy


-- SHOW VARIABLES LIKE 'secure_file_priv';
-- INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Revenue.csv'
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n';